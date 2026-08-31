# Assessment and migration guide

Use this guide to turn a heterogeneous integration estate into an evidence-based modernization backlog. Keep source exports immutable, record collection dates and environments, and avoid storing credentials or production payloads in this repository.

## 1. Establish scope

Define business domains, environments, source-platform versions, runtime locations, regulatory boundaries, in-flight projects, support dates, and accountable owners. Include shadow integrations such as scripts, scheduled jobs, database procedures, managed file transfers, and manually operated recovery steps.

## 2. Build the inventory

Create one record per independently deployable or operable interface. At minimum capture:

| Category | Fields |
| --- | --- |
| Identity | Stable ID, source platform, application/domain, environment, owner, support team |
| Trigger and schedule | Protocol/event, schedule, polling interval, timezone, blackout windows |
| Endpoints | Producers, consumers, connection type, network zone, authentication method |
| Contracts | Schemas, formats, versions, validation, canonical models, sensitive-data classification |
| Processing | Routing, transformation, enrichment, state, correlation, ordering, transactions, custom code |
| Nonfunctional | Volume, message size, latency, concurrency, availability, RTO/RPO, retention |
| Operations | Retry, replay, dead-letter/suspend behavior, reconciliation, alerts, dashboards, runbooks |
| Dependencies | Shared libraries, maps, connectors/adapters, certificates, databases, queues, partner agreements |
| Delivery | Source repository, build and deployment method, configuration, test evidence, release frequency |
| Economics | Licenses, runtime and infrastructure allocation, support effort, vendor services, data transfer |

Collect runtime evidence in addition to design-time configuration. Disabled interfaces, duplicate assets, stale connections, and undocumented operational work often change the migration decision.

## 3. Assess and disposition

Assign one primary disposition and document the evidence:

- **Retire:** no active business use or an approved replacement already exists.
- **Retain:** leave in place for now because risk or dependencies outweigh current value.
- **Rehost:** move the runtime with minimal change as a time-bounded transition.
- **Replatform:** preserve the contract and behavior on managed Azure capabilities.
- **Refactor:** redesign boundaries, contracts, state, or transformations to remove platform coupling.
- **Replace:** adopt a SaaS or packaged capability instead of rebuilding custom integration.

Unknowns are not low complexity. Record them as discovery actions with owners and due dates.

## 4. Score migration candidates

Use a consistent local scale, such as 1 (low) through 5 (high), for:

- Business criticality and outage impact
- Dependency count and coupling
- Contract and transformation complexity
- Custom code and unsupported protocol risk
- Data sensitivity and network complexity
- Transaction, ordering, and state requirements
- Volume, latency, and performance uncertainty
- Testability and quality of current evidence
- Operational maturity and recoverability
- Business value, lifecycle urgency, and expected change demand

Do not collapse the result into a single opaque score. Use the dimensions to explain why a workload belongs in a given wave.

## 5. Define target patterns

Select capabilities only after workload decomposition. For example:

| Workload shape | Candidate pattern to validate |
| --- | --- |
| Bulk scheduled extraction and transformation | Data Factory/Fabric pipelines or Databricks with governed ADLS landing zones |
| Stateful application integration | Logic Apps with Service Bus decoupling and explicit compensation/replay |
| Synchronous managed API | API Management in front of Logic Apps, Functions, Container Apps, or an application service |
| High-volume event stream | Event Hubs with independently scalable consumers |
| Reliable commands or business events | Service Bus queues/topics, idempotent handlers, dead-letter and replay process |
| B2B/EDI exchange | Logic Apps and Integration Account, validated partner agreements and acknowledgements |
| Unsupported connector or custom library | Supported custom service or Function behind a stable contract; avoid embedding product-specific runtime assumptions |

These are starting hypotheses. A proof must verify semantics, quotas, performance, security, and operability.

## 6. Plan waves

Prefer waves that are:

- Small enough to observe and reverse
- Representative enough to prove the target platform
- Bounded by a business domain or stable contract
- Ordered around shared dependencies
- Equipped with test data, business acceptance, and support ownership

Avoid choosing only trivial pilots; they do not expose the custom code, partner, network, and failure-handling risks that dominate later waves.

## 7. Prove and cut over

Each workload needs explicit gates:

1. Contract and transformation tests pass.
2. Identity, network, and secret handling meet the approved design.
3. Production-like load and payload-size tests meet agreed thresholds.
4. Retries, duplicate delivery, poison messages, timeout, and downstream outage behavior are demonstrated.
5. End-to-end correlation, alerts, replay, reconciliation, and runbooks are accepted by operations.
6. Parallel-run differences are explained and approved when parallel execution is feasible.
7. Cutover, rollback, retention, and source decommission criteria are approved.

## 8. Decommission deliberately

Remove source assets only after consumers and producers have moved, support and rollback windows have closed, audit data is retained, licenses and infrastructure dependencies are understood, and business owners approve retirement. Update the inventory so the modernization backlog remains the system of record.
