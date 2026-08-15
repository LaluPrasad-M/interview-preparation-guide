# Message Ordering

> [!tldr]
> Messages sent in one order can arrive in another. In a chat app that does not just look untidy, it changes what the words mean.

---

## The story that makes it stick

> [!example] Four messages, wrong order
> **Sent, in this order:**
> 1. I am visiting my cousin's house today. Her daughter was upset when I met her yesterday.
> 2. Her daughter has a cat, which was old and sick these last few days.
> 3. Unfortunately, she died recently.
> 4. I am planning to gift her a new one today.
>
> **Arrived, in this order:**
> 1. I am visiting my cousin's house today. Her daughter was upset when I met her yesterday.
> 2. Unfortunately, she died recently.
> 3. I am planning to gift her a new one today.
> 4. Her daughter has a cat, which was old and sick these last few days.
>
> Nothing was lost. Every message arrived. But the wife now believes the cousin's daughter died, and that her husband plans to replace her with a new one.

---

## Why it happens

Message 3 overtook message 2. Messages travel over separate connections and get handled by different servers, so the order they leave in is not the order they land in. Kafka and any other async pipeline behave the same way unless you ask them not to.

The word "she" is what breaks. Message 3 depends on message 2 for its meaning, so the reader fills the gap with the wrong subject.

---

## How chat apps fix it

| Fix | How |
| --- | --- |
| **Sequence numbers** | every message gets a number on the way out (msg_1, msg_2). The receiving app holds anything early and shows them in order |
| **Timestamps** | sort by when the message was sent, not when it turned up |
| **Acknowledgements** | if the receiver never sees msg_2, it asks again and slots it into place |
| **Partitioning** | Kafka only promises order inside one partition, so put every message between the same two people in the same partition |

---

## The part you cannot fix by sorting

> [!warning] Notifications are fire and forget
> Once the phone has buzzed you cannot take it back. The chat screen can sort itself out perfectly and the notification shade will still show the wrong story.

| Message | In the chat | As a notification |
| --- | --- | --- |
| I am visiting my cousin's house today | 1st | delivered |
| Her daughter has a cat, which was old | 2nd | never arrived |
| Unfortunately, she died recently | 3rd | delivered, wife in tears |
| I am planning to gift her a new one | 4th | delivered, wife now frightened |

This is a **notification race condition**: the backend fires notifications before it has settled the message order.

| Platform | Approach | Why it works |
| --- | --- | --- |
| WhatsApp | notification queue plus sequence numbers | notifications only go out once ordering is settled |
| Instagram | Firebase topics with priority | only important messages get pushed |
| Telegram | short delay and batching | waits a few seconds so it can reorder first |
| Signal | APNs collapse id | folds several notifications for one chat into one |

---

> [!tip] Rule of thumb
> Sort on the client. Delay notifications on the server. Use Kafka partitions or Redis sorted sets to keep order where it matters.
