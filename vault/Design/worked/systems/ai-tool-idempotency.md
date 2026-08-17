# AI Tool Calling Idempotency Engine

> [!tldr]
> LLMs are non deterministic and aggressive retryers. If a tool call lags, the model hallucinates failure and calls it again. You need a mathematical shield around the AI.

---

## The problem

An AI agent is on a phone call with a customer and decides to refund a 50 dollar ticket. The LLM generates `{"name": "issue_refund", "args": {"amount": 50}}`.

The orchestrator forwards this to the airline's external API. The airline processes the refund but takes 10 seconds to respond. The LLM's internal loop times out after 5 seconds, assumes failure, and generates a second identical tool call. Without protection, the customer is refunded 100 dollars.

**The objective.** A centralised idempotency execution engine that intercepts all outgoing AI tool calls, generates deterministic execution locks, guarantees exactly once execution of side effects, and seamlessly returns cached responses if the LLM retries.

---

## Functional requirements

**Intercept.** Receive raw tool call JSON from the LLM orchestrator.

**Deduplicate.** Deterministically identify whether this exact tool call has already been attempted in this conversation turn.

**Execute.** Proxy the request to the external enterprise API safely.

**Cache and replay.** If the LLM retries, intercept the retry, do not hit the external API, and instantly return the previously saved successful or failed response.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | 10,000 active agents executing 1 tool per second, so 10,000 QPS |
| Performance | the idempotency check must add under 5 ms before hitting the external API |
| Availability against consistency | strict consistency is absolute. If the locking cluster is down we fail closed. Better for the AI to say "I cannot process refunds right now" than to charge a card twice |
| Concurrency | defending against thundering herds of retries, the LLM firing 3 identical calls in parallel due to an async orchestration bug |
| Edge cases | semantic hallucination, where the LLM retries but slightly alters the argument, `50` against `50.00` |

---

## The architecture

```text
======================= THE LLM ORCHESTRATION LAYER =======================

      +-------------------------------------------+
      |     VOICE ORCHESTRATOR NODE (Node.js)     |
      |   (Receives Tool Call JSON from the LLM)  |
      +---------------------+---------------------+
                            | 1. gRPC: ExecuteTool(AgentID, TurnID, Payload)
                            v
======================= THE IDEMPOTENCY SHIELD (CP) ======================

      +-------------------------------------------+
      |        TOOL EXECUTION ENGINE (Go)         |
      |  (Generates idempotency key via hashing)  |
      +------+----------------------+-------+-----+
             |                      |       |
 2. Sync TCP |          3. Sync TCP |       | 4. HTTP POST
 (SETNX Lock)|          (Audit Row) |       | (The actual mutation)
             v                      v       v
    +----------------+   +----------------+ +---------------------------+
    | REDIS CLUSTER  |   |   POSTGRESQL   | |   EXTERNAL ENTERPRISE API |
    | (Distributed   |   |  (Permanent    | |   (Payments, commerce,    |
    |  Mutex Locks)  |   |   State/Cache) | |    hospital EHR)          |
    +----------------+   +----------------+ +---------------------------+
```

---

## Tracing a double refund attempt

1. **The request.** The LLM outputs `{"tool": "refund", "amount": 50}` and the orchestrator forwards it to the tool execution engine.

2. **Key generation.** The engine hashes `Agent_ID + Conversation_Turn_ID + Tool_Name` to generate a deterministic key, `ik_88xyz`.

3. **The lock, tier 1.** The engine runs `SETNX lock:ik_88xyz "PROCESSING" EX 30`. Redis returns 1, so the engine owns the lock.

4. **The audit, tier 2.** `INSERT INTO tool_executions (id, status) VALUES ('ik_88xyz', 'PROCESSING')` in PostgreSQL.

5. **The external call.** The engine calls the external API. It takes 10 seconds.

6. **The race condition.** At second 5 the LLM times out and fires the same tool call again. The engine generates the same hash, attempts `SETNX lock:ik_88xyz`, and Redis returns 0. The engine knows this is a duplicate in flight, so it pauses the retry thread and makes it long poll PostgreSQL, waiting for the status of `ik_88xyz` to change from `PROCESSING` to `COMPLETED`.

7. **The final handoff.** At second 10 the original call succeeds. The engine updates Postgres to `COMPLETED` and saves the JSON response. The original thread returns the response to the LLM. The waiting retry thread wakes, reads the cached response from Postgres, and returns it. The external API was hit exactly once.

---

## API design, internal gRPC

```protobuf
service ToolExecutionService {
  rpc Execute(ToolRequest) returns (ToolResponse);
}

message ToolRequest {
  string session_id = 1;       // e.g., call_9988
  string turn_id = 2;          // e.g., turn_5 (the 5th time the user spoke)
  string tool_name = 3;        // e.g., "issue_refund"
  string raw_json_args = 4;    // e.g., '{"amount": 50}'
}

message ToolResponse {
  bool was_cached = 1;         // tells the orchestrator if this was a fresh hit or a replay
  string status = 2;           // SUCCESS, FAILED, TIMEOUT
  string json_result = 3;      // the payload to feed back into the LLM
}
```

---

## Database design

**Redis, the lock layer.** Strictly `SETNX`, set if not exists, with an expiry TTL of 30 seconds. That prevents permanent deadlocks if the tool engine pod is OOM killed while holding the lock.

**PostgreSQL, the state and cache layer. Table `tool_executions`.**

| Column | Notes |
| --- | --- |
| `idempotency_key` | VARCHAR, primary key |
| `session_id` | VARCHAR, indexed |
| `status` | enum: `PROCESSING`, `SUCCESS`, `FAILED` |
| `request_payload` | JSONB |
| `response_payload` | JSONB, nullable, stores the cached result for replays |
| `created_at` | timestamp |

---

## Alternatives considered

### LLM generated against server generated keys

**Alternative.** Prompt the LLM to always include a unique UUID in its tool calls for idempotency.

**Why rejected.** LLMs are notoriously bad at following strict formatting instructions across long contexts. The model might hallucinate a new UUID on the retry, bypassing the entire shield. We must generate the key deterministically on the server using the turn ID, which the orchestrator tracks flawlessly.

### Redis only against Redis plus Postgres

**Alternative.** Store cached responses in Redis for 24 hours and skip Postgres.

**Why rejected.** Tool executions involving money or enterprise state require strict permanent auditability. If an enterprise asks why an agent refunded money yesterday, we need a permanent SQL record of the exact LLM payload and the external API response. Redis is volatile, Postgres is durable.

---

## The hardest edge case: semantic hallucination

**The scenario.** The LLM fires call 1 as `{"amount": 50, "reason": "delay"}`. It times out. Because the model is non deterministic, the retry is `{"amount": 50.0, "reason": "flight delay"}`.

**The failure.** If our server hashes the raw JSON to create the key, call 1 and call 2 generate different hashes. The lock is bypassed and the customer is refunded twice.

**The solution.** Do not hash the arguments. The idempotency key is constructed strictly from `Agent_ID + Conversation_Turn_ID + Tool_Name`.

An AI agent can only legally execute a tool once per conversation turn, the space between the user finishing speaking and the AI replying. Locking at the turn ID level mathematically guarantees that even if the LLM hallucinates different semantic arguments on the retry, the engine intercepts it and returns the cached result of the first attempt.

---

## The stuck lock

**The scenario.** The tool engine grabs the Redis lock, starts processing, and the pod is killed by the OOM killer. The Redis lock remains and the Postgres status is permanently `PROCESSING`.

**The solution.** An active recovery worker. A background cron queries Postgres for any row where `status = PROCESSING` and `created_at < NOW() - 60 seconds`, and transitions those to `FAILED`. When the LLM retries it sees `FAILED`, bypasses the cache, and attempts a clean execution.

---

## Follow up questions

### A tool that takes 2 minutes

**Q.** What if the external API takes 2 minutes? We cannot hold a gRPC stream open that long, and the LLM will time out.

**A.** For long running tools, shift from synchronous to asynchronous polling. When the tool is called, the engine instantly returns a mock response, `{"status": "PENDING_BACKGROUND_JOB"}`. We instruct the LLM in its system prompt: if a tool returns `PENDING`, say "I am working on that for you", and use the `check_status` tool after 10 seconds. The engine handles the 2 minute API call in the background using a queue and updates Postgres when finished. The LLM simply polls until it is ready.

### An external API with no idempotency support

**Q.** What if the external API does not support idempotency keys natively?

**A.** That is exactly why this architecture exists. We act as the shield, and we never pass our internal key to an external API that does not support it. Because we physically block the duplicate request from ever leaving our network using the Redis lock, the external API is protected from duplicate hits even with zero idempotency logic on their end.
