# S3 Events and Use Cases

> [!tldr]
> S3 can call a Lambda function when an object is uploaded or modified, which turns a storage bucket into the trigger for a pipeline.

---

## Event driven processing

S3 can trigger AWS Lambda when objects are uploaded or changed. Three things people build with it:

| Pattern | What happens |
| --- | --- |
| Image processing | an upload triggers a function that resizes the image |
| Log processing | logs land in S3 and get analysed with Amazon Athena |
| Data pipelines | an upload starts a workflow in AWS Step Functions |

The shape is the same every time: the upload is the event, and nothing polls for new files. Compare that with the webhook against polling choice in [[third-party-integrations]], which is the same tradeoff one level up.

---

## Common use cases for S3

| Use case | Why S3 |
| --- | --- |
| Website hosting | store and serve static files directly |
| Backup and disaster recovery | eleven nines of durability, and cheap cold classes |
| Big data and analytics | hold large datasets for tools that read straight from S3 |
| Machine learning | store training datasets |
| Content distribution | serve images, video and assets, usually behind a [[cdn]] |

---

## Why this comes up in interviews

S3 is rarely the interesting part of a design on its own. It becomes interesting as the join between services: the place an upload arrives, the trigger that starts the work, and the durable store the results go back into. If you can name the event source and what consumes it, you have described most of an event driven architecture.
