# SQL Data Types

> [!tldr]
> Never store money in a float. Everything else is a sizing decision that shows up later as index bloat.

---

## Numeric

| Type | Stores | Size | Exact or approximate | Common usage | Notes |
| --- | --- | --- | --- | --- | --- |
| `TINYINT` | very small integers | 1 byte | exact | flags, age | range usually -128 to 127 |
| `SMALLINT` | small integers | 2 bytes | exact | counts | smaller storage |
| `INT` / `INTEGER` | standard integers | 4 bytes | exact | IDs, counts | the most common integer type |
| `BIGINT` | very large integers | 8 bytes | exact | large IDs, analytics | needed for huge datasets |
| `FLOAT` | floating point decimals | 4 bytes | approximate | scientific values | precision issues possible |
| `DOUBLE` | double precision float | 8 bytes | approximate | calculations | more precision than float |
| `DECIMAL(p,s)` | exact decimal | variable | exact | money, finance | best for currency |
| `NUMERIC(p,s)` | exact decimal | variable | exact | finance | usually the same as `DECIMAL` |

> [!warning] The financial interview point
> Never use `FLOAT` or `DOUBLE` for money. Use `DECIMAL(10,2)`, because floating point internally may produce `0.1 + 0.2 = 0.30000000004`.

### DECIMAL(p,s) explained

In `DECIMAL(10,2)`, the 10 is total digits and the 2 is digits after the decimal. It can store `12345678.90`.

---

## Character and string

| Type | Stores | Fixed or variable | Common usage | Notes |
| --- | --- | --- | --- | --- |
| `CHAR(n)` | fixed length string | fixed | country code, status | pads with spaces |
| `VARCHAR(n)` | variable length string | variable | names, emails | the most commonly used |
| `TEXT` | large text | variable | blogs, comments | large storage |
| `MEDIUMTEXT` | bigger text | variable | articles | MySQL specific |
| `LONGTEXT` | very large text | variable | documents | huge storage |

**`CHAR`.** `CHAR(5)` storing `AB` is actually stored padded. It works well when the size is constant, for example a PIN, a country code, or fixed identifiers.

**`VARCHAR`.** It stores only the actual content, which is efficient for varying lengths, and it works best for names, emails and addresses.

**Why not `VARCHAR(10000)` everywhere?** Larger possible row size, memory inefficiency, and index overhead. Proper sizing matters.

---

## Date and time

| Type | Stores | Common usage | Notes |
| --- | --- | --- | --- |
| `DATE` | date only | birthdays | `YYYY-MM-DD` |
| `TIME` | time only | schedules | `HH:MM:SS` |
| `DATETIME` | date plus time | events | no timezone conversion |
| `TIMESTAMP` | timestamp | audit logs | often UTC internally |
| `YEAR` | year | reporting | limited usage |

### DATETIME against TIMESTAMP

| Feature | `DATETIME` | `TIMESTAMP` |
| --- | --- | --- |
| Timezone aware | no | usually yes |
| UTC conversion | no | yes |
| Good for | business date | audit logs |
| Auto update support | limited | common |

`created_at TIMESTAMP` is good because it is server timezone independent and easier to support in distributed systems.

---

## Boolean

| Type | Stores | Notes |
| --- | --- | --- |
| `BOOLEAN` | true or false | often internally 0 or 1 |
| `BIT` | bit values | compact storage |

---

## Binary

| Type | Stores | Common usage |
| --- | --- | --- |
| `BINARY` | fixed binary | encrypted keys |
| `VARBINARY` | variable binary | tokens |
| `BLOB` | binary large object | files and images |

**Production reality.** Modern architectures avoid storing large files in the database. Store the file in object storage such as S3, a [[cdn|CDN]] or blob storage, and save the URL in the database.

---

## JSON and semi structured

| Type | Usage |
| --- | --- |
| `JSON` | semi structured data |
| `JSONB` | optimised binary JSON in PostgreSQL |
| `XML` | XML documents |

```json
{
  "theme": "dark",
  "language": "en"
}
```

In modern SQL databases, arrays are commonly stored inside a JSON column. A `tags JSON` column can hold `["mobile", "android", "electronics"]`.

**Good for** flexible metadata, changing schema and optional attributes. **Bad for** highly relational queries, heavy joins and strict constraints.

---

## UUID

UUIDs are very important in distributed systems. Example: `550e8400-e29b-41d4-a716-446655440000`.

**Benefits.** They avoid centralised ID generation and are safer for distributed systems.

**Trade off.** Larger indexes and fragmentation issues.

---

## ENUM

ENUM restricts allowed values:

```sql
status ENUM('PENDING', 'DONE', 'FAILED')
```

Good for validation. Bad for schema evolution and portability. Many backend systems prefer `VARCHAR` plus a `CHECK` constraint instead.

---

## Best practice table

| Situation | Recommended type |
| --- | --- |
| Money | `DECIMAL` |
| User IDs | `BIGINT` or `UUID` |
| Names | `VARCHAR` |
| Fixed size code | `CHAR` |
| Log timestamps | `TIMESTAMP` |
| Large articles | `TEXT` |
| Flexible metadata | `JSON` |
| Boolean flags | `BOOLEAN` |
