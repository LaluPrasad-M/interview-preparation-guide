# Vymo Websales Integration

> [!tldr]
> A real integration, written up end to end: a life insurance website hands leads to a CRM, agents work them, and status flows back. Read this when you want to see the concepts in [[design]] applied to one system rather than described in the abstract.

> [!warning] This one is from work
> It names a real client and carries real numbers: the SLA, the encryption standard, the cache TTLs and the officer hierarchy. Fine while this repo is private. Check it before the repo is ever made public, and do not paste it into an interview answer as your employer's internals. The transferable patterns are collected in [[patterns-worth-stealing]], which is safe to talk about.

---

## The files

| Note | Covers |
| --- | --- |
| [[overview-and-requirements]] | what the system does, functional and non functional requirements |
| [[hld]] | components, service contracts, the request sequence, architecture diagram |
| [[websales-lld]] | endpoint by endpoint: file processing, lead creation, assignment, call centre, scheduling, metrics |
| [[caching-and-errors]] | what is cached and for how long, and what happens when each thing fails |
| [[patterns-worth-stealing]] | the reusable lessons, with no client detail |

---

## In one paragraph

A policy holder fills in a form on the TATA-AIA website. That lead reaches Vymo's Lead Management System over HTTP, gets stored and cached, and is assigned to an agent by rule. The agent is notified on their phone, calls the lead or books a Zoom meeting, and the outcome flows back to the client's call centre. Alongside that live path, two files arrive over SFTP on a schedule, one daily with leads and one weekly with the officer hierarchy, and both are processed asynchronously.

The interesting parts are the two paths, live and batch, sharing one data model, and everything after lead creation being asynchronous over Kafka.

---

## Original design link

The diagram this was drawn from lives in an [Eraser workspace](https://app.eraser.io/workspace/VATEMRG0rlWiS4a1f0kZ). Treat that link as work material too.
