# Blue Green Deployment

> [!tldr]
> Run two identical environments, one live and one idle. Deploy to the idle one, test it properly, then point all traffic at it in a single switch, so rolling back is just switching back.

Blue is the environment serving real users. Green sits there running the new version with no traffic on it, so you can hit it with smoke tests and a real login while nobody is affected. When green looks healthy the router moves everyone across at once.

> [!example]- What the switch actually looks like
> Blue runs v1.4 behind the load balancer and green runs v1.5 with zero traffic.
> You run the test suite against green's own hostname, check its dashboards, then update the load balancer target group from blue to green.
> Ten minutes later the error rate doubles, so you point the target group back at blue, which is still sitting there warm with v1.4 on it.
> Total rollback time is one config change, not a redeploy.

The comparison worth having ready, because the interviewer usually asks why you would not just do the cheaper one.

| Strategy | How traffic moves | Rollback | What it costs |
| --- | --- | --- | --- |
| Rolling update | replace a few instances at a time | roll the old version forward again, slowly | one environment |
| Blue green | all at once, in one switch | flip the switch back, seconds | two full environments at the same time |
| Canary release | 1 percent, then 5, then 50 | stop shifting, send everyone back | one environment plus traffic splitting |

> [!warning] The database is the hard part
> Two application environments are easy to duplicate, one database is not. Any schema change has to work with both versions at once, which is why the switch is only truly instant when your migrations are backward compatible.

**Shows up in:** [[kubernetes-basics]], [[designing-the-four-layers]], [[zero-downtime-migration]], [[study-roadmap]].
