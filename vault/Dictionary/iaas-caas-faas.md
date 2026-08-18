# Infrastructure, Container and Function as a Service (IaaS, CaaS, FaaS)

> [!tldr]
> The same cloud compute, handed to you at three different levels. Infrastructure as a Service gives you a bare machine, Container as a Service gives you somewhere to run containers, and Function as a Service takes only your code. Each step up removes work you were doing and removes control you had.

| | IaaS | CaaS | FaaS |
| --- | --- | --- | --- |
| Example on AWS | EC2 | ECS or EKS | Lambda |
| You hand over | a virtual machine to configure | a container image | a single function |
| You still manage | operating system, patching, runtime, scaling | the image and how many copies run | nothing but the code |
| They manage | the hardware | the hardware and the host operating system | all of it, including when to run you |
| You pay for | the machine, running or not | the machine the containers sit on | each invocation and its milliseconds |
| Scales by | you adding machines | you adding container replicas | itself, per request |
| Cold start | none, it is always up | small, a container start | real, see [[cold-start]] |

> [!example]- The same small API at each level
> **EC2.** Launch an instance, install Node, run the app under a process manager, set up the load balancer, patch the operating system every month, and pay for the instance at 3am when nobody is using it.
> **ECS.** Build a container image, tell ECS to keep three copies running behind a load balancer, and stop thinking about the operating system.
> **Lambda.** Upload the handler, and get charged only when a request arrives, but accept a cold start on the first call and a hard timeout on every call.

These are not three products for three different jobs. They are one capability, and choosing between them is choosing how much operational work you want to own. See [[ec2-ecs-lambda]] for how that decision actually goes.

**Shows up in:** [[ec2-ecs-lambda]].
