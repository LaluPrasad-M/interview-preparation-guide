# GitHub Actions and CI/CD

> [!tldr]
> At its core, GitHub Actions is a way to rent a temporary computer for a few minutes. Everything else is vocabulary on top of that.

---

## The core mental model

Before automation, developers manually ran tests, built applications and uploaded files to servers. Actions exists to eliminate the human element, automating the flow from code push to deployment.

You are telling GitHub to spin up a fresh computer, download your code, and run a list of commands whenever a specific event happens.

---

## The vocabulary, as a restaurant kitchen

**The event, the trigger.** A customer places an order. In GitHub, this is what starts everything, like a developer pushing to main.

**The workflow, the recipe.** The documented instructions the kitchen follows. In GitHub, a `.yml` file in your repository listing exactly what happens.

**The runner, the chef.** The person executing the recipe. In GitHub, the temporary computer, usually an Ubuntu server, executing the job.

**The job, the station.** A phase of cooking, like prepping vegetables or cooking meat. In GitHub, jobs are groupings of tasks that run in parallel by default.

**The step, the task.** The individual actions like chopping onions. In GitHub, the actual terminal commands running in the shell, such as `npm install`.

---

## Intermediate concepts

**Job dependencies, `needs`.** Since jobs run in parallel by default, you can force them sequential. A deploy job should only run if test and build pass.

**Matrix strategy.** Run the same job multiple times with different variables, heavily used for cross platform or cross version testing.

**Caching, `actions/cache`.** Downloading heavy dependencies on every run wastes time. Cache the folder based on a hash of your lockfile to save minutes off the build.

**Artifacts, `actions/upload-artifact`.** Because jobs run on fresh isolated runners, they do not share a file system. Job A must upload its output as an artifact so job B can download it and continue.

**Secrets against variables.** Secrets are encrypted environment variables passed to runners and masked in logs. Variables are for non sensitive configuration.

---

## Advanced concepts

**Reusable workflows, `workflow_call`.** Instead of copying the same build steps across 20 microservices, define one central workflow that triggers on a `workflow_call`.

**Composite actions.** Bundle multiple individual steps into a single custom action, for example combining checkout, setup and authentication into one reusable step.

**Environments and protection rules.** Deploying to production automatically is dangerous. Environments let you add gates like required manual approvals before a deployment job runs.

**OIDC.** Storing long lived cloud credentials in secrets is a major security risk. OIDC lets GitHub request short lived temporary access tokens directly from the cloud provider based on cryptographic trust, so no permanent secrets are stored.

**Self hosted runners.** Enterprises often require jobs to run inside their own private network. Install the runner agent on your own instance or pod to keep execution entirely private.

---

## Comparing the alternatives

| Feature | GitHub Actions | Jenkins | GitLab CI |
| --- | --- | --- | --- |
| The analogy | the modern food truck parked outside your farm | the DIY kitchen where you build your own appliances | the all in one corporate mega kitchen |
| Setup and hosting | managed SaaS, zero setup | self hosted, high maintenance overhead | both SaaS and self hosted |
| Ecosystem | massive community marketplace of pre built actions | a massive but sometimes outdated plugin ecosystem | built in features, less reliance on third party plugins |
| Code proximity | workflows live in your repository | workflows live in code, but the server is entirely separate | workflows live in your repository |
| Learning curve | low to medium, YAML based and readable | steep, requires Groovy scripting for advanced pipelines | medium, YAML based and very structured |
| Best for | teams already on GitHub wanting frictionless CI/CD | legacy enterprise systems needing extreme custom configuration | teams wanting one strict application for the whole DevOps lifecycle |
