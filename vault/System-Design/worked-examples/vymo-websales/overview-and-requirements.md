# Overview and Requirements

> [!tldr]
> Integrating TATA-AIA's web sales system with Vymo CRM, so leads captured on the website reach an agent quickly and their status flows back. Near real time sync, agent to lead interaction, and automated scheduling.

---

## Functional requirements

### 1. Lead creation and validation

- A lead, meaning the prospective policy holder, creates a profile on the TATA-AIA website with phone number validation over OTP.
- They give their policy requirements and pick a plan.
- The data goes to TATA-AIA's backend APIs.
- That backend calls Vymo's Lead Management System to create the lead.

### 2. Lead data management

- Vymo LMS stores the lead in its database and caches frequently read data in Redis.
- Vymo updates the hierarchy and assigns agents automatically using preconfigured assignment rules.
- Leads are visible to agents and officers, meaning Branch Managers, Trainer Managers, ZTMs and Circle Managers, according to role based access control.

> [!question] Open question from the original notes
> Whether the assignment rules belonged to the call centre rather than to LMS. Worth resolving before using this as a reference, because it changes who owns the routing logic.

### 3. Lead data synchronisation

- TATA-AIA uploads a daily lead data file over SFTP.
- Vymo's Distributed Data Processing service picks the file up and processes it asynchronously.
- Leads are created or updated in LMS, and status updates are pushed to the TATA-AIA call centre.

> [!question] Also unresolved
> Exactly how DDP processes the file asynchronously. The [[websales-lld]] lists the stages, but the queueing and parallelism inside it were not written down.

### 4. Communication with leads

- Agents can schedule meetings through the Zoom integration, auto scheduled by priority and availability.
- High net worth leads are connected with doctors automatically through Vymo LMS.
- SMS notifications go out through TATA-AIA's SMS gateway APIs.
- Push notifications reach the Vymo mobile app through Firebase Cloud Messaging.

### 5. Officer data management

- A weekly officer hierarchy file arrives over SFTP.
- Vymo DDP processes it and updates LMS.
- A re-trigger option exists for failures.
- Alerts fire when the file is corrupted.

---

## Non functional requirements

| Requirement | How it is met |
| --- | --- |
| Scalability | microservices, with Kafka for asynchronous communication |
| High availability | Redis caching and Kafka based reprocessing |
| Data consistency | a 30 second SLA for lead data synchronisation |
| Security | AES-256 encryption for sensitive lead information |
| Re-trigger | for failed file processing |
| Monitoring and alerts | Datadog for performance and errors |

The 30 second SLA is the number that shapes the design. It is loose enough to allow a queue between services, and tight enough that the batch path cannot be the only way data moves, which is why the live HTTP path exists alongside the daily file.
