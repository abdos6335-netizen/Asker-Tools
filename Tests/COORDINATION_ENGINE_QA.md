# Coordination Engine — Final QA Matrix

This is the required in-host validation plan for the completed nine-part implementation. Static source checks are not substitutes for these tests.

## Geometry
- Axis-aligned box overlap, clear separation, face/edge/vertex contact.
- Coplanar overlap/separation and edge/vertex contact; near-parallel separation, tiny triangles and high-aspect-ratio triangles.
- SAT axes are normalized before projection so the configured epsilon is a world-space distance; near-zero axes are rejected using thresholds relative to the source edge/normal magnitudes.
- Triangle degeneracy uses area relative to the longest edge squared, rather than a fixed world-unit area cutoff; short-segment degeneracy checks are likewise scale-relative.
- Include tiny valid triangles/segments and very high-aspect-ratio geometry in the numerical regression suite.
- Reject negative or nonnumeric geometry tolerances before entering pairwise triangle tests; verify the error is explicit and no clash result is emitted.
- Closed-mesh ray parity deduplication uses a tighter scale-aware hit tolerance; distinct nearby surface crossings must remain distinct.
- Parallel, collinear segment pairs with overlapping projections must return zero distance; parallel separated segments must return the perpendicular gap.
- Point-to-segment checks cover perpendicular projection, zero-length segments, and skew segment pairs with an interior closest point.
- Triangle-to-triangle distance checks cover parallel offset surfaces and coplanar separated triangles with known exact squared distances.
- Rotated, concave, hollow, open, edge-non-manifold, vertex-non-manifold and nested meshes.
- Disconnected closed shells inside one mesh object must not be treated as one connected solid for containment; report containment as unverified.
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
- Numeric per-element service and installation clearances must propagate from the discipline inventory into scan snapshots, exact pair clearance, stale-scene validation, and non-destructive simulation. Textual service/installation envelope references remain metadata until a geometric envelope provider is implemented.
- Clash scan and stale-scene validation must not call undeclared geometry-engine methods; static validation explicitly guards this integration contract.

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
- Candidate and proposal ID sets must contain unique, non-empty identifiers; candidate target and affected-element sets cannot be empty.
- Proposal count fields must exactly match their corresponding resolved/new/critical/missing/affected ID arrays; tampered counts and malformed non-array ID fields must be rejected before ranking without throwing.
- Six translation candidates for each side of a clash.
- Target clash resolution, remaining clashes, introduced clashes.
- Exact mesh simulation against every other inventory element.
- General, service and installation clearance enforcement with unit conversion and invalid negative/non-numeric inputs.
- Rule-missing and critical-rule blocks.
- Confirm source scene transforms and geometry remain unchanged during simulation.
- Change a node transform, pivot, vertex position, classification, mapping or envelope between scan/simulation/approval/apply; every stale snapshot must be blocked.

## Clash manager and governance
- Stable clash selection, owner/status/due date persistence behavior.
- Frame the selected clash in the active viewport.
- Isolate the two clash elements, then restore the exact prior hidden/visible state; closing or clearing Clash Manager must also restore visibility.
- Failed apply must verify whether the original transform/object transform/pivot were restored; distinguish a successful restoration from APPLY_FAILED_RESTORE_FAILED. Failed rollback must enter an explicit ROLLBACK_FAILED state and retain an audit event.
- Current apply/approval transaction scope is one affected node per approved action. Multi-node atomic batch transactions remain unsupported and must not be represented as atomic.
- Reject approval without exact validated simulation, approver, date, and reason.
- Reject candidate/simulation identity mismatch and affected-element mismatch.
- Apply translation, exception during apply, rollback, repeated rollback, deleted node.
- Confirm audit sequence and transaction state transitions.

## Approval identity integrity
- Candidate target, resolved, introduced, critical, missing-rule and affected-element ID sets must exactly match the validated simulation; order is irrelevant but duplicates are rejected.
- Tampering with any simulation-derived ID set after simulation must block engineering approval and add an audit event.

## Project persistence
- Save and reload rules, required check types, discipline mappings, element clearance/envelope metadata, clash tracking, integration revision tokens/history and audit history.
- Reject unsupported schema versions, invalid/duplicate tracking IDs, duplicate or incomplete integration identities, and malformed rule records without replacing the prior in-memory project state.
- Verify backup creation and recovery when destination replacement fails. Recovery must validate the backup XML root/schema before replacing the active project, retain the source backup, and preserve the previous active file as a pre-restore copy.
- Confirm active approvals and scene transactions are cleared on project load and must be re-approved.
- Confirm a single approval cannot be applied twice; rollback does not re-arm it.

## Integrations and reports
- Missing provider, unsupported capability, missing revision, provider exception.
- Revision mismatch and stale sync token behavior.
- Re-register a provider at a new revision and confirm its prior revision's lastSyncToken is invalidated; only a separately persisted token matching the new revision may be restored.
- UTF-8 CSV escaping for commas, quotes, Unicode, CR/LF and file permission errors.
- Verify clash/proposal report counts and values against source records.
- Full reports must include registered rule provenance: source type/name, revision, jurisdiction, approval/mandatory state, effective date, value, unit and severity.

## Version matrix
Run the full matrix on 3ds Max 2022, 2023, 2024, 2025 and 2026. Treat 2027 as pending until separately tested. Record exact build number, OS, test scene, pass/fail, logs and known deviations. Corona and V-Ray must be tested separately only where renderer-specific scene objects or materials are involved.

## Release gate
Do not label this engine production-ready or merge it to main until all critical geometry, rule, transaction and regression tests pass in-host and the results are reviewed.


## In-host self-test harness
Run `fileIn (getDir #userScripts + "\\\\AskerTools\\\\Tests\\\\AT_CoordinationSelfTests.ms")` after the coordination modules are loaded, then run `AT_CoordinationSelfTests.run()` and inspect `AT_CoordinationSelfTests.summary()` plus `lastResults`. The harness creates uniquely named temporary boxes and a plane, deletes only those test nodes, and restores the prior geometry/rule-engine result arrays and rule registry. Run it on a disposable scene first; confirm no test objects remain afterward.


### Closed-mesh ray parity boundary handling — 2026-11-23
- Replaced strict-interior-only ray/triangle hit testing with scale-relative determinant rejection and inclusive barycentric edge/vertex hits.
- Closed-mesh parity now normalizes its three deterministic ray directions and deduplicates coincident hit distances, preventing a shared triangulation edge or vertex from being counted twice.
- Added in-host regression cases for a ray passing exactly through a shared triangle edge and shared vertex. These cases validate equal hit parameters from adjacent faces; full containment parity still requires 3ds Max runtime execution.
- This is a robustness improvement, not a watertight-predicate guarantee. Extremely ill-conditioned triangles, near-coincident distinct surfaces, and adversarial mesh topology still require runtime/numerical QA.
