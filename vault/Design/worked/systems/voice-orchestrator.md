# Real Time Voice Orchestrator

> [!tldr]
> Overlapping streams are the whole trick. The user hears the first word while the model is still generating the rest of the sentence, which is how you beat the 500 ms barrier.

---

## The problem

A customer calls an enterprise phone number and an AI agent picks up.

Standard REST APIs are request and response. You wait for the full audio, send it, wait for the full transcript, send it to the model, wait for the full paragraph, send it to text to speech, wait for the full audio, and send it back. That takes 4 to 6 seconds.

In telephony, if latency exceeds 500 ms, humans think the line is dead and talk over the AI. And if the AI is speaking and the human interrupts, the AI must instantly stop talking and listen.

**The objective.** Build a real time streaming pipeline that ingests continuous audio, transcribes it, feeds it to an LLM, and synthesises it back to voice using heavily chunked overlapping streams, achieving under 500 ms time to first audio.

> [!question] STT, LLM, TTS
> **STT**, speech to text, converts the user's audio to text. The **LLM** processes the text, understands intent and generates a response. **TTS**, text to speech, converts the response text to spoken audio. Orchestration uses a streaming pipeline so they overlap: audio, STT chunks, LLM streaming, TTS chunks, audio.

---

## Functional requirements

**Ingest.** Accept a continuous stream of raw audio bytes from a telephony provider.

**Process.** Orchestrate STT, LLM and TTS simultaneously.

**Barge in.** Detect when the user interrupts, immediately halt TTS playback, and clear the LLM's current generation queue.

**State.** Maintain conversational memory, the context window, for the duration of the call.

> [!question] The context window
> Stores the relevant conversation history supplied to the LLM. It maintains continuity during the call while staying within the model's token limit.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale | 10,000 concurrent active voice calls |
| Performance | glass to glass latency, human finishes speaking to AI starts speaking, must be under 500 ms |
| Availability | absolute. A dropped network connection drops the phone call |
| Concurrency | safe memory management as asynchronous STT and TTS chunks race each other |
| Edge cases | the barge in race condition, where the user interrupts exactly as the AI sends a new sentence to the speaker |

---

## The architecture

```text
================== EXTERNAL TELEPHONY (THE EDGE) ==========================

      +-------------------------------------------+
      |     TELEPHONY PROVIDER (SIP bridge)       |
      |   (Converts phone call to WebSockets)     |
      +---------------------+---------------------+
                            | 1. Bidirectional WebSocket (raw audio bytes)
                            v
======================= REAL-TIME CLUSTER =================================

      +-------------------------------------------+
      |    L4 NETWORK LOAD BALANCER               |
      +---------------------+---------------------+
                            | 2. TCP Stream
                            v
  +--------------------------------------------------------------+
  |               VOICE ORCHESTRATOR NODE (Go / Node.js)         |
  |   (Maintains the active WebSocket for the life of the call)  |
  +------+----------------------+---------------------------+----+
         |                      |                           |
 3. gRPC | Stream               | 4. gRPC Stream            | 5. gRPC Stream
         v                      v                           v
  +-------------+        +--------------+        +--------------+
  |   STT API   |        |   LLM API    |        |   TTS API    |
  +------+------+        +------+-------+        +------+-------+
         |                      |                       |
         +----------------------+-----------------------+
                                | 6. Sync TCP (sub-millisecond)
                                v
                      +--------------------+
                      |    REDIS CLUSTER   |
                      | (Call state and    |
                      |  context window)   |
                      +--------------------+
```

---

## Tracing "I want to book a flight"

**1. The ingestion.** The provider opens a WebSocket to the orchestrator node. As the human speaks, it sends raw audio bytes, 8 kHz G.711 format, every 20 milliseconds.

**2. Streaming STT.** The orchestrator does not wait for the human to finish. It pipes those raw bytes directly into an open gRPC stream to the STT service, which streams back partial text: `"I"`, then `"I want"`, then `"I want to book a flight."`

**3. Voice activity detection.** The orchestrator detects a 500 ms pause in incoming audio volume, assumes the human is done, and pushes the final text to the LLM.

**4. LLM chunking, the latency hack.** The LLM starts generating "Great, I can help with that. Where are you flying to?"

We do not wait for the full sentence. The LLM streams tokens, and the moment the orchestrator receives the first logical chunk, `"Great,"`, it instantly fires that to the TTS engine.

**5. Streaming TTS.** The TTS engine turns `"Great,"` into audio bytes and streams them back, and the orchestrator pipes them down the WebSocket. The user hears "Great," while the LLM is still generating the rest of the sentence. This overlap is how you beat the 500 ms barrier.

**6. Barge in.** The AI is saying "Where are you flying to?" and the human suddenly says "Wait!". The STT engine instantly detects human speech, the orchestrator fires an internal `ABORT` signal, flushes the TTS audio buffer, closes the current LLM stream, and transitions back to listening.

---

## API design: bidirectional streaming against REST

In a standard REST API the client opens a connection, sends data, gets a response, and the connection closes. In bidirectional streaming over WebSockets or gRPC, the connection stays open permanently and both sides push data at any time, simultaneously.

**Why not HTTPS.** It is fine for independent request and response calls, but it does not provide the long lived bidirectional streaming needed here.

**Why gRPC streaming.** It keeps a persistent connection and lets audio and data flow continuously in both directions, avoiding repeated HTTP request overhead.

**Multiple concurrent calls.** Each call has its own long lived stream and state. The orchestrator handles thousands of concurrent connections asynchronously. Do not confuse this with multiple requests on one HTTP connection.

The key additions to mention are connection lifecycle, a per call `call_id`, cancellation and [[backpressure]], and streaming state management.

```protobuf
// The bidirectional stream for speech to text
service AudioProcessor {
  rpc StreamAudio(stream AudioFrame) returns (stream TranscriptionEvent);
}

message AudioFrame {
  string call_id = 1;
  bytes audio_data = 2; // raw 20ms chunk of audio
}

message TranscriptionEvent {
  string text = 1;
  bool is_final = 2; // true if the user stopped speaking
}
```

---

## State management

During a live call the orchestrator needs to remember the conversation. Writing every spoken word to PostgreSQL synchronously would add 50 ms of latency and burn out the database connections.

**Hot storage, Redis, the active call.** This is a Redis `LIST`, which is perfect for chronologically appending chat history. The key is `call_context:{call_id}`.

When STT finishes a sentence, the orchestrator runs `RPUSH call_context:123 '{"role": "user", "content": "I want to book a flight"}'`. When sending to the LLM, it runs `LRANGE call_context:123 0 -1` to grab the whole history in 1 ms.

**Cold storage, Kafka plus Postgres, post call analytics.** When the call hangs up, the orchestrator pulls the full Redis list, publishes it to a `call.completed` Kafka topic, and a background worker writes it permanently to PostgreSQL.

---

## Alternatives considered

### WebSockets against WebRTC

**Alternative.** Build this using WebRTC, which uses UDP, instead of WebSockets, which use TCP.

**Why WebSockets.** Telephony providers natively bridge SIP to WebSockets for media streams. WebRTC is superior for browser to browser video, because UDP does not care about dropped packets. But for backend AI integrations, where missing a packet means the LLM hallucinates a word, TCP based WebSockets provide the necessary packet ordering guarantees.

### Redis against in memory state

**Alternative.** Store the call context in an array variable inside the process, `let callHistory = []`.

**Why Redis.** If the pod crashes at minute 15 of a 30 minute call, the array is destroyed. The telephony provider instantly reconnects the caller to a new pod. By externalising state to Redis, the new pod fetches the `call_id` from Redis in 1 ms and says "sorry, bad connection, you were saying?" without losing any memory.

### Go or Node.js against Python

**Alternative.** AI companies love Python.

**Why Go or Node.js.** Python's global interpreter lock makes handling 1,000 highly concurrent WebSocket streams inefficient. Go with goroutines, or Node.js with its async epoll event loop, can handle thousands of open WebSockets on a single CPU core.

---

## Trade offs and edge cases

### Chunk size against audio quality

**The problem.** If we send LLM output to TTS one word at a time, the AI sounds like a stuttering robot, because the TTS engine has no context for intonation or emotion.

**The solution.** Punctuation based buffering. The orchestrator buffers the token stream in RAM and only sends chunks to TTS when it hits a comma, period or question mark, for example `"Great, "`.

**The trade off.** We artificially add roughly 100 ms of latency waiting for the comma, but audio quality improves dramatically because the TTS model can infer the proper inflection for that phrase.

### The ghost echo

**The scenario.** The AI is speaking. The human's phone speaker plays the AI's voice. The human's microphone picks it up and sends it back to our STT engine. The AI starts talking to itself.

**The solution.** Mathematically subtract the audio waves we are sending out from the waves coming in, which is acoustic echo cancellation. Also implement strict state gating: while the AI is speaking, raise the volume threshold required for voice activity detection to trigger a barge in, so only a loud human voice interrupts.

---

## Follow up question

**Q.** How do you handle rate limiting for an enterprise client paying per minute of AI talk time?

**A.** We cannot block a live WebSocket to check Postgres billing. We use a Redis token bucket running locally on the orchestrator. Before the call connects we load 60 minutes of credits into Redis, and a background `setInterval` decrements the counter every 60 seconds. If the counter hits 0 during the call, the orchestrator gracefully injects a TTS message saying the account has run out of minutes, and cleanly terminates the WebSocket.

---

## Related

The transport decision table is in [[websockets-and-sse]]. The tool calling shield is in [[ai-tool-idempotency]].
