# Coordination Engine — Final QA Matrix

This is the required in-host validation plan for the completed nine-part implementation. Static source checks are not substitutes for these tests.

## Geometry
- Axis-aligned box overlap, clear separation, face/edge/vertex contact.
- Coplanar triangles, near-parallel triangles, tiny triangles, degenerate faces.
- Rotated, concave, hollow, open, edge-non-manifold, vertex-non-manifold and nested meshes.
- Fully contained closed meshes with no surface intersection (must be detected or explicitly reported unsupported).
- Degenerate/zero-area faces: skipped from triangle math, counted, and must prevent a mesh from being treated as watertight.
- Multiple clash pairs and explicit non-zero clearance.
- Large meshes and dense scenes: runtime and memory profiling.

## Rotation alternatives
- Candidate count and axis/angle metadata for both moving sides of a clash.
- Rotation snapshot changes geometry bounds as expected while leaving the source node transform unchanged.
- Rotation simulation target resolution, introduced clashes, and stale-pivot rejection.

## Discipline mappings and envelopes
- Map each supported discipline through explicit user-property, layer, class or node-name keys; unknown remains UNKNOWN.
- Remove/change a mapping and confirm the scan revision invalidates prior alternatives.
- Apply numeric clearance with mm/cm/m/in/ft/system units and confirm master-unit conversion.
- Save/load mapping and envelope overrides in the project XML store.
- Service and installation envelope references remain metadata until geometric expansion is implemented.

## Discipline adapters
- Verify all eight discipline labels.
- User-property, exact layer, class and exact-name mapping precedence.
- Unknown and conflicting metadata; invalid mapping values.
- Missing bounds, hidden nodes, deleted nodes, duplicate names and stable handles.
- Explicit service/installation envelopes and missing-envelope warnings.

## Units and validator coverage
- Verify mm/cm/m/km/in/ft values convert through `units.decodeValue` to master units for different scene display-unit settings.
- Unsupported unit identifiers and malformed numeric values block rule evaluation.
- Non-clearance rule types without a registered geometry/semantic validator must remain blocked, not be treated as passed.

## Rules
- Verify source precedence and jurisdiction filtering.
- Mandatory law/code, authority approval, manufacturer, project specification, defaults.
- Unapproved-only, missing, expired/revised and conflicting rules.
- Missing rule blocks candidate eligibility; no inferred numeric value.
- Critical violations cannot be overridden by lower-priority sources.

## Candidate generation and simulation
- Unassessed risk must be labeled NOT_ASSESSED and omitted from score penalty, never displayed as zero risk.
- Six translation candidates for each side of a clash.
- Target clash resolution, remaining clashes, introduced clashes.
- Exact mesh simulation against every other inventory element.
- General, service and installation clearance enforcement with unit conversion and invalid negative/non-numeric inputs.
- Rule-missing and critical-rule blocks.
- Confirm source scene transforms and geometry remain unchanged during simulation.
- Change a node transform, pivot, vertex position, classification, mapping or envelope between scan/simulation/approval/apply; every stale snapshot must be blocked.

## Clash manager and governance
- Stable clash selection, owner/status/due date persistence behavior.
- Reject approval without exact validated simulation, approver, date, and reason.
- Reject candidate/simulation identity mismatch and affected-element mismatch.
- Apply translation, exception during apply, rollback, repeated rollback, deleted node.
- Confirm audit sequence and transaction state transitions.

## Approval identity integrity
- Candidate target, resolved, introduced, critical, missing-rule and affected-element ID sets must exactly match the validated simulation; order is irrelevant but duplicates are rejected.
- Tampering with any simulation-derived ID set after simulation must block engineering approval and add an audit event.

## Project persistence
- Save and reload rules, required check types, discipline mappings, element clearance/envelope metadata, clash tracking, integration revision tokens/history and audit history.
- Reject unsupported schema versions, invalid/duplicate tracking IDs and malformed rule records without replacing the prior in-memory project state.
- Verify backup creation and recovery when destination replacement fails.
- Confirm active approvals and scene transactions are cleared on project load and must be re-approved.
- Confirm a single approval cannot be applied twice; rollback does not re-arm it.

## Integrations and reports
- Missing provider, unsupported capability, missing revision, provider exception.
- Revision mismatch and stale sync token behavior.
- UTF-8 CSV escaping for commas, quotes, Unicode, CR/LF and file permission errors.
- Verify clash/proposal report counts and values against source records.

## Version matrix
Run the full matrix on 3ds Max 2022, 2023, 2024, 2025 and 2026. Treat 2027 as pending until separately tested. Record exact build number, OS, test scene, pass/fail, logs and known deviations. Corona and V-Ray must be tested separately only where renderer-specific scene objects or materials are involved.

## Release gate
Do not label this engine production-ready or merge it to main until all critical geometry, rule, transaction and regression tests pass in-host and the results are reviewed.


## In-host self-test harness
Run `fileIn (getDir #userScripts + "\\\\AskerTools\\\\Tests\\\\AT_CoordinationSelfTests.ms")` after the coordination modules are loaded, then run `AT_CoordinationSelfTests.run()` and inspect `AT_CoordinationSelfTests.summary()` plus `lastResults`. The harness creates uniquely named temporary boxes and a plane, deletes only those test nodes, and restores the prior geometry/rule-engine result arrays and rule registry. Run it on a disposable scene first; confirm no test objects remain afterward.
