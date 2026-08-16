# AI Agent Orchestration and State Management

> [!tldr]
> Long running multi step processes where the data shape is unpredictable. Async API, document store for the working memory, and optimistic concurrency for the state transitions.

---

## The retry decision flow

```text
  Request
     |
  Timeout
     |
  Retryable? -- No --> DLQ / Discard
     |
    Yes
     |
  Exponential Backoff + Jitter
     |
  Retry limit reached?
     |
    Yes
     |
  DLQ + Alert
```

---

## API design: asynchronous workflow execution

When an enterprise system triggers an AI agent, the process might take anywhere from 5 seconds to 5 minutes: calling a user, waiting for input, querying a CRM, synthesising a response. The API must be asynchronous.

**Endpoint.** `POST /v1/agents/{agent_id}/executions`

```json
{
  "input_parameters": {
    "customer_phone": "+1234567890",
    "intent": "reschedule_flight"
  },
  "callback_url": "https://client-api.enterprise.com/webhook"
}
```

**Response.** `202 Accepted`

```json
{
  "execution_id": "exec_987abc",
  "status": "PENDING",
  "status_url": "/v1/executions/exec_987abc"
}
```

**The design choice.** By returning a `status_url` and accepting a `callback_url`, you support both polling for lightweight clients and webhooks for robust enterprise backends, avoiding keeping HTTP connections open for minutes.

---

## Database modelling: the document model

MongoDB is the right choice here. An agent's working memory, `state_data`, changes dynamically depending on what the LLM decides to do or what a third party API returns. A rigid SQL schema would require constant migrations.

```json
{
  "_id": ObjectId("..."),
  "tenant_id": "org_123xyz",
  "status": "RUNNING",
  "current_step": "fetch_crm_data",
  "state_data": {
    "salesforce_response": { "ticket_id": "TCK-445" },
    "transcription_so_far": "I need to change my flight..."
  },
  "version": 3,
  "updated_at": ISODate("2026-08-15T10:30:00Z")
}
```

The `state_data` block is the flexible schema area, and `version` is critical for concurrency.

**Indexing strategy.** A compound index on `{ tenant_id: 1, status: 1 }` to quickly query all `RUNNING` or `FAILED` executions for a client dashboard.

---

## The key interview question: race conditions

**Q.** How do you handle race conditions if two different async workers, a timeout monitor and a successful API response handler, try to update the agent's state to `FAILED` and `COMPLETED` at the exact same millisecond?

**A.** Optimistic concurrency control using the `version` field.

**1. The fetch.** Both worker A, handling the timeout, and worker B, handling the success, read the document. They both see `version: 3`.

**2. The update condition.** When a worker updates, it includes the version it read in the query filter and increments it in the payload.

```js
db.agent_executions.updateOne(
  { _id: "exec_987abc", version: 3 }, // only update if version is still 3
  {
    $set: { status: "COMPLETED" },
    $inc: { version: 1 }
  }
)
```

**3. The collision.** If worker A succeeds first, the version becomes 4.

**4. The rejection.** When worker B's query executes a millisecond later it looks for `version: 3`, and finds zero matches, `modifiedCount: 0`.

**5. The resolution.** Worker B throws a concurrency error, re fetches the document, sees it is already marked `COMPLETED` or `FAILED`, and safely aborts without overwriting the previous state.
