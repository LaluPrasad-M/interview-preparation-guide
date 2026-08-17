# Blue Green Deployment

> [!tldr]
> Two identical environments, one live and one idle. Deploy to the idle one, test it, then flip traffic to it instantly, so rollback is just flipping back.

Blue is serving live traffic while green gets the new version. Once green looks healthy, the router switches to it in one step, and if something is wrong, switching back is just as fast as switching forward.

The cost is running two full environments at once, if only briefly, which is why canary release (shifting a small traffic percentage instead) is the cheaper alternative for a gradual rollout.

**Shows up in:** [[kubernetes-basics]], [[designing-the-four-layers]], [[zero-downtime-migration]].
