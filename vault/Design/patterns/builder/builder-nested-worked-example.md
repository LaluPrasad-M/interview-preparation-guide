# Nested Builder Worked Example

> [!tldr]
> The production version: scope the builder inside the class, use a type-aware build method, and provide fluent chaining for every setter.

Part of [[builder]].

---

This is the version to write in a machine coding round, because it keeps the builder scoped inside the class it builds.

```ts
class Email {
    readonly to: string;
    readonly subject: string;
    readonly cc: string[];
    readonly bcc: string[];
    readonly body: string;
    readonly priority: string;
    readonly attachments: string[];

    private constructor(builder: InstanceType<typeof Email.Builder>) {
        this.to = builder.toAddr;
        this.subject = builder.subjectText;
        this.cc = [...builder.ccList];
        this.bcc = [...builder.bccList];
        this.body = builder.bodyText;
        this.priority = builder.priorityText;
        this.attachments = [...builder.attachmentList];
    }

    toString(): string {
        return `Email{
to='${this.to}',
subject='${this.subject}',
cc=[${this.cc.join(", ")}],
bcc=[${this.bcc.join(", ")}],
body='${this.body}',
priority='${this.priority}',
attachments=[${this.attachments.join(", ")}]
}`;
    }

    static Builder = class {
        toAddr: string;
        subjectText: string;
        ccList: string[] = [];
        bccList: string[] = [];
        bodyText: string = "";
        priorityText: string = "normal";
        attachmentList: string[] = [];

        constructor(to: string, subject: string) {
            this.toAddr = to;
            this.subjectText = subject;
        }

        cc(cc: string): this {
            this.ccList.push(cc);
            return this;
        }

        bcc(bcc: string): this {
            this.bccList.push(bcc);
            return this;
        }

        setBody(body: string): this {
            this.bodyText = body;
            return this;
        }

        setPriority(priority: string): this {
            this.priorityText = priority;
            return this;
        }

        attachment(attachment: string): this {
            this.attachmentList.push(attachment);
            return this;
        }

        build(): Email {
            return new Email(this);
        }
    };
}

const email1 = new Email.Builder("alice@example.com", "Meeting Tomorrow")
    .setBody("Let's meet at 10am in conference room B.")
    .build();

const email2 = new Email.Builder("bob@example.com", "Project Update")
    .cc("carol@example.com")
    .cc("dave@example.com")
    .bcc("manager@example.com")
    .setBody("Attached is the Q4 report.")
    .setPriority("high")
    .attachment("q4-report.pdf")
    .attachment("summary.xlsx")
    .build();

console.log(email1.toString());
console.log(email2.toString());
```

The call sequence:

```text
new Email.Builder(...)
   |
Builder object created
   |
.cc(...)  -> Builder updated
   |
.setBody(...)  -> Builder updated
   |
.attachment(...)  -> Builder updated
   |
.build()
   |
new Email(builder)
   |
Email constructor copies values
   |
Email object returned
```
