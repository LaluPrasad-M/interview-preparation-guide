# HTTP Status Codes

> [!tldr]
> 1xx wait, 2xx success, 3xx redirect, 4xx your fault, 5xx my fault. The interview questions are all about the pairs that look similar.

---

## The master table

| Code | Name | Who sends it | What happened | Mental model | When you should return it |
| --- | --- | --- | --- | --- | --- |
| 100 | Continue | server | the client may continue sending the body | go ahead | large uploads |
| 101 | Switching Protocols | server | protocol upgraded | change lanes | WebSocket upgrade |
| 102 | Processing | server | still processing | working | a long running task |
| 200 | OK | server | request succeeded | all good | a successful GET |
| 201 | Created | server | a resource was created | created | POST success |
| 202 | Accepted | server | accepted for async processing | queued | background jobs |
| 204 | No Content | server | success with no body | done | DELETE success |
| 206 | Partial Content | server | a partial response | chunk | range requests |
| 301 | Moved Permanently | server | permanent redirect | moved | SEO redirect |
| 302 | Found | server | temporary redirect | temporary | login redirect |
| 304 | Not Modified | server | the cached copy is still valid | use cache | browser caching |
| 307 | Temporary Redirect | server | redirect, method preserved | safe redirect | redirecting a POST |
| 308 | Permanent Redirect | server | permanent redirect, method preserved | safe move | API versioning |
| 400 | Bad Request | server | invalid request syntax | I do not understand | malformed JSON |
| 401 | Unauthorized | server | authentication missing or invalid | who are you? | missing token |
| 403 | Forbidden | server | auth is fine, access denied | not allowed | role restriction |
| 404 | Not Found | server | resource not found | gone | wrong ID |
| 405 | Method Not Allowed | server | that method is not supported | wrong verb | POST on a GET only route |
| 409 | Conflict | server | state conflict | duplicate | unique constraint violation |
| 410 | Gone | server | permanently removed | deleted | deprecated API |
| 413 | Payload Too Large | server | the request is too large | too big | upload limit |
| 415 | Unsupported Media Type | server | wrong `Content-Type` | wrong format | JSON expected |
| 422 | Unprocessable Entity | server | validation failed | invalid data | form validation |
| 429 | Too Many Requests | server | rate limit exceeded | slow down | throttling |
| 500 | Internal Server Error | server | unhandled failure | my fault | unexpected error |
| 501 | Not Implemented | server | feature not implemented | not built | a stub API |
| 502 | Bad Gateway | gateway | upstream returned an invalid response | dependency failed | microservice failure |
| 503 | Service Unavailable | server | unavailable or overloaded | down | maintenance |
| 504 | Gateway Timeout | gateway | upstream did not respond in time | too slow | timeout |

---

## The pairs that get asked

### 401 against 403

| Code | Meaning |
| --- | --- |
| 401 Unauthorized | auth missing or invalid, "who are you?" |
| 403 Forbidden | auth valid but access denied, "you cannot do this" |

No token gives 401. A valid token with an insufficient role gives 403.

### 204 against 304

| Code | Meaning |
| --- | --- |
| 204 No Content | success, no response body |
| 304 Not Modified | the client should use its cached response |

A DELETE returns 204. Browser revalidation returns 304.

### 400 against 409

| Code | Usage |
| --- | --- |
| 400 Bad Request | invalid syntax or a malformed request |
| 409 Conflict | the request conflicts with current state |

A missing field gives 400. A duplicate email hitting a unique constraint gives 409.

### 400 against 422

400 means the syntax itself is wrong, for example malformed JSON. 422 means the syntax is valid but the data is semantically invalid, for example a badly formatted email.

### 502 against 504

| Code | Meaning |
| --- | --- |
| 502 Bad Gateway | upstream responded, but incorrectly |
| 504 Gateway Timeout | upstream did not respond at all |

The short version: a response was received but invalid gives 502, no response received gives 504.

### 301 against 308

| Code | Method preservation |
| --- | --- |
| 301 | may change POST to GET |
| 308 | preserves the method |

If you need the method preserved across a redirect, use 307 for temporary or 308 for permanent.

---

## Scenario answers

| Scenario | Code |
| --- | --- |
| `POST /users` creates a user and returns it | 201 Created |
| Protected endpoint called with no `Authorization` header | 401 Unauthorized |
| Valid JSON that fails email validation | 422 Unprocessable Entity |
| 1 GB upload against a 200 MB limit | 413 Payload Too Large |
| `GET /products/999` where the product does not exist | 404 Not Found |
| Redirect that must keep POST as POST | 307, or 308 if permanent |
| `DELETE /users/123` succeeds with no body | 204 No Content |
| ETag revalidation and the resource is unchanged | 304 Not Modified |
| Gateway calls a service that returns malformed JSON | 502 Bad Gateway |
| User exceeds 100 requests per minute | 429 Too Many Requests |
| Server overloaded by a traffic spike | 503 Service Unavailable |

---

## Design scenarios

**A file upload endpoint.**

| Case | Status | Reason |
| --- | --- | --- |
| Too large | 413 | upload limit exceeded |
| Wrong media type | 415 | expecting a specific type |
| Virus detected | 422 or 403 | semantically invalid, or explicitly blocked |

**A login endpoint.**

| Scenario | Status |
| --- | --- |
| Wrong password | 401 |
| Missing credentials | 400 or 401 |
| Account locked | 403 |
| Success | 200 |

**A long running report job.**

| Scenario | Status |
| --- | --- |
| Accepted for background processing | 202 Accepted |
| Still processing | 102 Processing, optional |
| Completed and ready | 200 OK, with the data or a URL |

See [[api-design]] for why 202 is a senior signal.
