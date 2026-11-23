# Coordination integrations and reporting

## Integration registry (0.1.0)
The integration bridge registers providers by module name and revision, declares supported operation capabilities, and exchanges payloads only when the caller supplies a source revision, the operation is explicitly supported, and the expected previous revision matches the last synchronized token. A mismatch returns `REVISION_CONFLICT` without calling the provider. The provider receives both the new source revision and the expected previous revision for its own transactional checks. This is a contract layer, not a completed adapter for every Asker Tools module.

Planned provider connections include Architectural Plan Builder, Ceiling Builder, Electrical/HVAC/Fire Fighting/Plumbing/Low Current tools, Shop Drawing workflows, and quantity takeoff/BOQ. Until a provider is registered, the integration remains unavailable; no module is assumed to exist or silently synchronized. The last source-revision token is preserved when a provider is re-registered during the same session, and exchange history is retained in memory.

API: `register moduleName revision provider capabilities:<array>`, `unregister integrationId`, `get integrationId`, `exchange integrationId operation payload sourceRevision expectedPreviousRevision:<string>`.

## Reporting (0.3.0)
Creates structured clash and proposal report rows and exports CSV. Rows include measured geometric distance/clearance and current provisional severity; proposal rows preserve eligibility, score, rank, approval requirement, and reasons. A print-ready HTML report is also available. It can be opened in a browser and printed to PDF; this is not a native PDF or XLSX writer.

APIs: `buildClashRows clashes`, `buildClearanceRows clashes`, `buildDisciplineRows clashes`, `buildProposalRows results`, `buildTrackingRows tracking`, `buildRuleMissingRows missingPairs`, `buildGeometryErrorRows errors`, `buildDisciplineErrorRows errors`, `buildApprovalRows approvals`, `buildRevisionRows syncHistory`, `buildAuditRows auditLog`, `exportCSV rows path`, `buildFullReportSections()`, `buildHTML sections title:<string>`, `exportHTML sections path title:<string>`, and `exportFullHTML path`. The full HTML report combines clash, clearance, discipline, missing-rule, geometry/discipline errors, tracking, approvals, proposals, audit and integration revision history. It is print-styled and suitable for browser Print-to-PDF. CSV remains the native tabular export and can be opened in Excel; native XLSX and direct PDF generation are not included.

## Remaining production gates
Persistent project database, linked-file revision diff/merge, two-way DWG synchronization, actual integrations to the other modules, PDF/XLSX formatting, as-built history, and user-authenticated approvals remain future implementation work. Integration contracts do not imply that the upstream tools are already connected.


## Project persistence (0.1.0)
The project store writes an XML document using .NET XML APIs and a temporary-file replacement with a `.bak` backup. It persists registered rule data, required check-type identifiers, discipline mappings and element envelope overrides, clash tracking, integration source-revision tokens/history and governance audit events. Loading validates rules before replacing the active registry and restores previous in-memory state if loading fails. Active approvals and scene transactions are intentionally not reauthorized after reload; an approval must be repeated against the current scene snapshot. The store's .NET API behavior still requires runtime validation in supported 3ds Max versions.
