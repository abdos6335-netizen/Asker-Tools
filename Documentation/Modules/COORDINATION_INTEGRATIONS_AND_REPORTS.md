# Coordination integrations and reporting

## Integration registry (0.1.0)
The integration bridge registers providers by module name and revision, declares supported operation capabilities, and exchanges payloads only when the caller supplies a source revision and the operation is explicitly supported. This is a contract layer, not a completed adapter for every Asker Tools module.

Planned provider connections include Architectural Plan Builder, Ceiling Builder, Electrical/HVAC/Fire Fighting/Plumbing/Low Current tools, Shop Drawing workflows, and quantity takeoff/BOQ. Until a provider is registered, the integration remains unavailable; no module is assumed to exist or silently synchronized. Revision tokens and exchange history are retained in memory.

API: `register moduleName revision provider capabilities:<array>`, `unregister integrationId`, `get integrationId`, `exchange integrationId operation payload sourceRevision`.

## Reporting (0.1.0)
Creates structured clash and proposal report rows and exports CSV. Rows include measured geometric distance/clearance and current provisional severity; proposal rows preserve eligibility, score, rank, approval requirement, and reasons. No PDF/Excel exporter is claimed in this milestone.

API: `buildClashRows clashes`, `buildProposalRows results`, `exportCSV rows path`.

## Remaining production gates
Persistent project database, linked-file revision diff/merge, two-way DWG synchronization, actual integrations to the other modules, PDF/XLSX formatting, as-built history, and user-authenticated approvals remain future implementation work. Integration contracts do not imply that the upstream tools are already connected.
