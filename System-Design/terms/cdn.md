# CDN (Content Delivery Network)

> [!tldr]
> A cache layer sitting in front of your load balancer, serving copies of your static files from a machine near the user.

---

## What it does for you

| What it does | How |
| --- | --- |
| **Takes load off your servers** | Keeps copies of frequently requested images, video and scripts on its own edge servers, so those requests never reach your origin. |
| **Cuts latency** | Edge servers sit all over the world, so a user in Chennai is served from near Chennai, not from Virginia. |
| **Sometimes balances load** | Not its main job, but many CDNs can also spread requests across several origin servers when volume is high. |
