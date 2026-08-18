# Content Delivery Network (CDN)

> [!tldr]
> A cache that sits in front of your servers in hundreds of cities, so a user downloads your images and scripts from a machine near them instead of from wherever your origin lives.

Those nearby machines are called edge servers, and the data centres holding them are Points of Presence (PoPs). Your own server is the origin. Distance is the whole point: light in fibre is fast but not instant, and a request to another continent pays for the round trip several times over during connection setup.

> [!example]- One user in Chennai, one origin in Virginia
> | Situation | Path taken | Round trip |
> | --- | --- | --- |
> | No CDN | Chennai to Virginia and back, every file | around 250 ms each |
> | CDN miss | Chennai edge asks Virginia once, then stores the file | 250 ms for the unlucky first user |
> | CDN hit | Chennai edge answers directly | around 15 ms for everyone after |

The second benefit is load. If 100,000 people request the same product image, the origin serves it once and the edge serves it 99,999 times, so that traffic never reaches your servers at all.

You control how long the edge keeps a copy with the `Cache-Control` header, and you force an early refresh by purging the file or changing its name. A build that emits `app.7f3a9c.js` never needs purging, because a new build is a new filename.

> [!warning] It only caches what is the same for everyone
> A logged in user's dashboard is different per user, so it cannot be cached at the edge without leaking one user's page to another. Static files, public pages and API responses that do not vary per user are the real targets.

Spreading requests across several origin servers is something many CDNs can also do, but it is a side job, not the reason you put one in front of your system.

**Shows up in:** [[zero-to-millions]], [[read-scaling]], [[building-blocks]], [[capacity-estimation]], [[s3-events]], [[designing-the-four-layers]].
