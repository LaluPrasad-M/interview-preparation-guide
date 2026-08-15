# S3 Lifecycle Rules

> [!tldr]
> Rules that move objects to cheaper storage classes as they age, and delete them when they expire, without anyone running a script.

---

## The example rule

Move to Standard-IA after 30 days, to Glacier after 90 days, delete after a year.

```json
{
  "Rules": [
    {
      "ID": "MoveToGlacier",
      "Status": "Enabled",
      "Prefix": "logs/",
      "Transitions": [
        { "Days": 30, "StorageClass": "STANDARD_IA" },
        { "Days": 90, "StorageClass": "GLACIER" }
      ],
      "Expiration": { "Days": 365 }
    }
  ]
}
```

---

## Reading it

| Field | Does |
| --- | --- |
| `ID` | names the rule, so you can find it later in logs and in the console |
| `Status` | `Enabled` or `Disabled`, which lets you switch a rule off without deleting it |
| `Prefix` | limits the rule to keys starting with `logs/`, so it does not touch the rest of the bucket |
| `Transitions` | the moves between storage classes, each with an age in days |
| `Expiration` | deletes the object at that age |

`Days` is counted from when the object was created, not from when the rule was written. So adding this rule to a bucket that already holds year old logs deletes them on the next evaluation.

> [!warning] Expiration deletes data on a timer nobody is watching
> That is the point of the feature and also its danger. A `Prefix` that is broader than you intended, or an `Expiration` where you meant a `Transition`, removes objects silently and permanently. Enable versioning first, and test a new rule on a prefix that holds nothing you need.

The classes these rules move between are in [[storage-classes]].
