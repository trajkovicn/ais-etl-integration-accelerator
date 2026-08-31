# Source-platform to Azure capability mapping

This mapping supports discovery workshops. It does not imply binary compatibility or automated conversion. Product editions and versions differ; verify every connector, protocol, delivery guarantee, transformation, and operational dependency against current vendor and Microsoft documentation.

## Cross-platform mapping

| Source platform | Inventory focus | Common source concepts | Azure capabilities to evaluate | Migration cautions |
| --- | --- | --- | --- | --- |
| Informatica PowerCenter and related estate | Repositories, mappings, mapplets, workflows, sessions, parameter files, schedules, connections, pushdown SQL, reusable transformations | Batch ETL, workflow control, data quality, database/file/SaaS connectivity | Azure Data Factory or Fabric Data Factory for orchestration and movement; Databricks or target-engine SQL for complex transformations; ADLS Gen2 for landing; Key Vault and Azure Monitor | Transformation semantics, pushdown behavior, restartability, row-level rejects, lineage, and CDC are workload-specific. Do not assume a mapping can be imported. |
| TIBCO BusinessWorks / EMS | Process definitions, shared resources, adapters, schemas, EMS destinations, deployment archives, custom Java, operational rules | EAI orchestration, adapters, request/reply, pub/sub and queues | Logic Apps for workflows; Service Bus for brokered messaging; API Management for APIs; Functions/Container Apps for custom code; Event Hubs for streams | EMS selectors, transactions, redelivery, ordering, adapter behavior, and BusinessWorks plug-ins require explicit redesign and testing. |
| MuleSoft Anypoint Platform | Mule apps, flows/subflows, connectors, DataWeave, API specs, policies, object stores, queues, CloudHub/runtime topology | API-led connectivity, mediation, transformations, orchestration, policy enforcement | API Management for API gateway policy; Logic Apps for orchestration/connectors; Service Bus/Event Hubs for messaging; Functions/Container Apps for code; Azure Monitor | DataWeave and Mule connector behavior do not translate directly. Separate API contract/governance from workflow and runtime concerns. |
| Oracle Integration Cloud and OCI integration services | Integrations, connections, lookups, schedules, agents, mappings, certificates, OCI Queue/Streaming/Functions events, adjacent SOA assets | SaaS integration, scheduled orchestration, file transfer, messaging and events | Logic Apps and supported connectors; Data Factory/Fabric for bulk data; Service Bus/Event Hubs/Event Grid by semantic; Functions for custom logic; APIM | Oracle application connectivity, private agents, staged files, fault policies, and mapping functions need proof. Distinguish OIC from OCI-native services and older SOA Suite assets. |
| IBM Integration Bus / App Connect Enterprise | Applications, message flows, ESQL, maps, BAR files, policies, MQ topology, configurable services, custom nodes | Message mediation, routing, transformation, MQ-centric integration | Logic Apps; Service Bus for Azure brokered messaging; supported IBM MQ connectivity where appropriate; Functions/Container Apps for ESQL/custom-node replacement; APIM | IBM MQ may remain a required system boundary. Transactions, message descriptors, ESQL behavior, custom nodes, and policy overrides need explicit treatment. |
| SAP PI/PO | ESR and Integration Directory objects, integration flows, communication channels, mappings, adapters, BPM/processes, SLD, certificates | SAP and partner integration, mappings, routing, B2B, process orchestration | Logic Apps with supported SAP connectivity; Integration Account for relevant B2B; Service Bus; APIM; Data Factory/Fabric for data movement; custom compute where justified | Coordinate with SAP's integration strategy. IDoc/BAPI/RFC behavior, exactly-once expectations, mappings, certificates, and network topology require SAP-specific validation. |
| BizTalk Server | Applications, orchestrations, pipelines, schemas, maps, ports, bindings, parties/agreements, BRE, BAM, custom assemblies, host topology | Stateful orchestration, adapters, MessageBox pub/sub, B2B/EDI, tracking | Logic Apps; Service Bus; Integration Account; APIM; Functions/Container Apps; Storage; Azure Monitor | Orchestration persistence, promoted-property routing, ordered delivery, transactions, pipelines, BRE, BAM, and custom assemblies are not one-to-one conversions. |

## Capability decomposition prompts

### Data movement and ETL

- Is processing batch, micro-batch, streaming, replication, or request/response?
- Which transformations depend on source-engine functions, pushdown SQL, lookup caches, or local files?
- What checkpoint, restart, reject, and reconciliation behavior exists?
- Where should transformation execute to minimize movement and preserve governance?

### Workflow and mediation

- Is the process stateless, stateful, long-running, or human-interactive?
- Which steps require transactions, compensation, correlation, ordered delivery, or concurrency controls?
- Which branches are business rules versus technical routing?
- Can the workflow be decomposed behind versioned contracts?

### APIs and connectors

- Is the source asset an API implementation, gateway policy, orchestration, or all three?
- Does Azure provide a supported connector for the exact protocol and authentication mode?
- Are private agents or on-premises gateways required during coexistence?
- What throttling, pagination, webhook, retry, and schema-evolution behavior must be preserved?

### Messaging and events

- Is the source semantic a command queue, publish/subscribe broker, event stream, or notification?
- What ordering, delivery, deduplication, transaction, retention, replay, and dead-letter guarantees are required?
- Are message headers or platform-specific metadata part of routing?
- Can producers and consumers migrate independently through a bridge?

### B2B and industry formats

- Inventory partners, agreements, envelopes, acknowledgements, certificates, schemas, maps, batching, and nonrepudiation requirements.
- Treat EDI, AS2, X12, EDIFACT, HL7, SWIFT, and proprietary formats as separate validated capabilities.
- Do not infer certification or regulatory suitability from the presence of a connector.

### Custom code and operations

- Identify unsupported libraries, native dependencies, proprietary SDKs, scripts, and administrator-run recovery procedures.
- Separate deterministic transformations from I/O and runtime-specific APIs before rebuilding.
- Define end-to-end correlation, business reconciliation, replay authorization, alert ownership, and data retention.

## BizTalk example

BizTalk remains one supported source family, not the organizing model for the accelerator.

| BizTalk concept | Candidate Azure capability | Required design work |
| --- | --- | --- |
| Orchestration | Logic Apps or code-based workflow | Revalidate persistence, correlation, compensation, timeout, and deployment behavior |
| Receive/send ports and adapters | Logic Apps connectors, APIs, Functions, or custom services | Verify protocol, identity, polling, batching, and retry semantics |
| MessageBox subscriptions | Service Bus topics/subscriptions or explicit routing | Rebuild promoted-property filters, ordering, transactions, and replay |
| Maps and pipelines | Integration Account maps, Logic Apps actions, Functions, or data engines | Test canonical schemas, encoding, flat files, validation, and custom components |
| Parties and agreements | Integration Account and Logic Apps B2B actions | Recreate partner configuration, certificates, acknowledgements, and operational controls |
| BRE | Workflow conditions or an explicitly selected rules implementation | Inventory vocabularies, policies, fact retrieval, versioning, and governance |
| BAM/HAT/tracking | Azure Monitor, Application Insights, Log Analytics, and business telemetry | Design correlation, business milestones, retention, dashboards, and support queries |
