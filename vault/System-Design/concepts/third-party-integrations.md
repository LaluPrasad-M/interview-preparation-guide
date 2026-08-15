# Third Party Integrations

> [!tldr]
> Every integration is a piece of your product you no longer control. Often worth it, as long as you make the trade knowingly.

---

## The trade

| What you get | What it costs |
| --- | --- |
| Features you did not build: payments (Juspay, Rupay), login (Auth0, Google OAuth), SMS (Twilio), push (Firebase) | Their limits become your limits. Rate caps and outages you can only wait out |
| Speed. A working payment flow this week instead of next quarter | New ways to leak. API keys in the wrong place, libraries nobody checked |
| Someone else's scaling problem. Search, auth and analytics handled by people whose whole job is that one thing | More moving parts. Several vendors, versions and sets of release notes |

---

## The example worth remembering

> [!example]- E-commerce platform outgrows its own auth and search
> The platform grows. Login and search were both built in house. Logins start to bottleneck, and search gets slower as the product table grows.
>
> Rather than scaling the whole application to fix two features, the team moves authentication to Auth0 and search to Elasticsearch. Logins are handled by a service built for it, and search is fast because Elasticsearch keeps an index designed for text queries.
>
> What they gained: the heavy work left their servers, scaling became the vendor's problem, security compliance came included, and the engineers went back to the parts of the product only they could build.

---

## Three decisions worth remembering

**Handle their failures, not just their successes.** Retry with [[exponential-backoff]], cap the retries, and decide what the user sees when the vendor is simply down.

**Webhooks or polling.**

| Approach | How it works | Trade |
| --- | --- | --- |
| **Webhook** | they call you the moment something happens | fast, but you must expose an endpoint and handle repeats |
| **Polling** | you ask every few minutes | simpler and predictable, but always slightly behind |

**Guard the keys.** Route calls through an API gateway, rotate keys on a schedule, prefer OAuth over long lived secrets.

---

## What to offload first

| Job | Use |
| --- | --- |
| Authentication | Auth0, Firebase Authentication, AWS Cognito |
| Search | Elasticsearch, Algolia |
| Analytics and monitoring | Datadog, Google Analytics, Mixpanel |
| Queueing | Kafka, RabbitMQ, AWS SQS |
