# Authorization

> [!tldr]
> Authorization answers "what are you allowed to do". It grants or denies access rights to an entity that has already been authenticated.

Authentication comes first and is a separate job, see [[authentication]].

---

## The models

**Role-based Access Control (RBAC).** Permissions are attached to predefined roles, and users are assigned roles. Simple to manage, and granular enough for most applications.

**Attribute-based Access Control (ABAC).** Access is decided from attributes of the user, the resource and the environment. Policies combine things like the user's role, the user's own attributes, attributes of the resource, and environmental conditions.

**Rule-based Access Control.** Rules define permissions from conditions and actions, which allows finer control than roles alone. A rule can use the time of day, the user's location, or other dynamic factors.

**Permission tickets.** Authorization tokens issued for a specific resource or a specific action. They can be time limited, granting temporary access based on the permissions the ticket carries.

> [!warning] Two of these share the abbreviation RBAC
> Role-based and Rule-based are both written RBAC, and they are different models. If someone says RBAC without qualifying it they almost always mean **Role**-based. Say "rule-based" in full when you mean the other one.

The practical difference between roles and attributes: a role is a label you assign in advance, while an attribute is a fact evaluated at the moment of the request. Roles are easier to reason about and audit. Attributes express things roles cannot, such as "only during business hours" or "only from the office network".

---

## Roles and permissions in an application

Assign roles to users, associate permissions with each role, define those permissions at a granular level, and check them at runtime before performing the operation.

The runtime check is the part that matters. A permission model nobody consults is decoration, and the check has to sit at the point the action happens rather than only in the UI that offers it.

---

## In a microservices architecture

The usual approach is a centralised authentication and authorization service, or a token based system. Each microservice validates the incoming token and verifies the necessary permissions before processing the request.

That gives you one place to issue trust and many places to check it, which is the only arrangement that scales. The alternative, each service asking a central service on every request, turns the auth service into a bottleneck and a single point of failure.

---

## The principle of least privilege

Grant the minimum privileges necessary to do the task, and nothing more.

It matters for three reasons: it reduces the chance of unauthorised access, it limits the damage when an account is compromised, and it keeps the overall blast radius small. The second is the one worth saying out loud, because it assumes a breach rather than hoping to prevent one.
