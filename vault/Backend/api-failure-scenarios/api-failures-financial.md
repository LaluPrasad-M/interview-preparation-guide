# API Failures: Financial Transactions

> [!tldr]
> Two high-value failure scenarios: wallet transfers use row locking for consistency, external payments need state machines with reconciliation.

Part of [[api-failure-scenarios]].

---

## 1. Wallet transfer

Users have wallets and can transfer money. No negative balance, no double deduction, no partial debit or credit, and retry safe.

```text
POST /wallet/transfers
{
 "fromUserId": "U1",
 "toUserId": "U2",
 "amount": 500,
 "idempotencyKey": "abc-123"
}
```

### The naive version, which is wrong

```sql
SELECT balance FROM wallets WHERE id = 'U1';
-- balance = 1000

UPDATE wallets SET balance = 500 WHERE id = 'U1';
UPDATE wallets SET balance = 1500 WHERE id = 'U2';
```

Two concurrent transfers both read 1000 and both write 500. That is the lost update anomaly.

### Fix 1: pessimistic locking

```sql
BEGIN;

SELECT balance
FROM wallets
WHERE id = 'U1'
FOR UPDATE;

-- Row locked here

UPDATE wallets SET balance = balance - 500 WHERE id = 'U1';
UPDATE wallets SET balance = balance + 500 WHERE id = 'U2';

COMMIT;
```

**Internally.** `FOR UPDATE` acquires an exclusive row lock. The second transaction blocks, the first commits, and the second then reads the updated balance.

**The principles.** Isolation, row level locking, and [[write-ahead-log|WAL]] for durability.

### Failure scenario 2: the client retries

The client times out but the server completed the transfer. The client retries and the money is deducted twice.

### Fix 2: an idempotency key

```sql
CREATE TABLE transfers (
 id UUID PRIMARY KEY,
 idempotency_key TEXT UNIQUE,
 status TEXT
);
```

```sql
INSERT INTO transfers (...) VALUES (...)
ON CONFLICT (idempotency_key) DO NOTHING;
```

If the row already exists, return the stored result.

**Internally.** The unique index uses a B-tree, the duplicate insert is rejected atomically, and no race is possible.

---

## 2. Payment through an external gateway

No double charge, and if the database crashes after the gateway succeeds the system must recover.

```text
POST /payments
{ "userId": "U1", "amount": 1000, "idempotencyKey": "p-111" }
```

### The dangerous scenario

Call the gateway, the gateway succeeds, and the server crashes before saving. Money is deducted and the database shows no record.

> [!warning] Why not wrap it in a DB transaction?
> The external HTTP call is outside database control. A database transaction cannot roll back the payment provider.

### The fix: a state machine

```sql
INSERT INTO payments(id, status) VALUES('p1', 'INITIATED');
```

Then call the gateway, then update the status to `SUCCESS`.

If it crashes before the update, the row stays `INITIATED`. On restart, a reconciliation worker checks the gateway for anything stuck in that state.

**Internally.** The first insert is committed via WAL so it is durable. The gateway success exists externally. Reconciliation queries the gateway API and updates the database later.

**The principles.** Eventual consistency, a durable state machine, at least once processing.
