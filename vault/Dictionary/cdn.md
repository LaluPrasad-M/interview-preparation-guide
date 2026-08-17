# Content Delivery Network (CDN)

> [!tldr]
> A cache layer sitting in front of your load balancer, serving copies of your static files from a machine near the user.

Its edge servers sit all over the world, so a user in Chennai is served from near Chennai, not from Virginia, which cuts latency. Keeping copies of frequently requested images, video and scripts on those edge servers also takes load off your own servers, since those requests never reach your origin. It is not a CDN's main job, but many can also spread requests across several origin servers when volume is high.

**Shows up in:** [[zero-to-millions]], [[read-scaling]], [[building-blocks]], [[capacity-estimation]], [[s3-events]], [[designing-the-four-layers]].
