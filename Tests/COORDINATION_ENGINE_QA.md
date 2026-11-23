# Coordination Engine — Final QA Matrix

This is the required in-host validation plan for the completed nine-part implementation. Static source checks are not substitutes for these tests.

## Geometry
- Axis-aligned box overlap, clear separation, face/edge/vertex contact.
- Coplanar triangles, near-parallel triangles, tiny triangles, degenerate faces.
- Rotated, concave, hollow, open, non-manifold and nested meshes.
- Fully contained closed meshes with no surface intersection (must be detected or explicitly reported unsupported).
- Degenerate/zero-area faces: skipped from triangle math, counted, and must prevent a mesh from being treated as watertight.
- Multiple clash pairs and explicit non-zero clearance.
- Large meshes and dense scenes: runtime and memory profiling.

## Rotation alternatives
- Candidate count and axis/angle metadata for both moving sides of a clash.
- Rotation snapshot changes geometry bounds as expected while leaving the source node transform unchanged.
- Rotation simulation target resolution, introduced clashes, and stale-pivot rejection.

## Discipline adapters
- Verify all eight discipline labels.
- User-property, exact layer, class and exact-name mapping precedence.
- Unknown and conflicting metadata; invalid mapping values.
- Missing bounds, hidden nodes, deleted nodes, duplicate names and stable handles.
- Explicit service/installation envelopes and missing-envelope warnings.

## Rules
- Verify source precedence and jurisdiction filtering.
- Mandatory law/code, authority approval, manufacturer, project specification, defaults.
- Unapproved-only, missing, expired/revised and conflicting rules.
- Missing rule blocks candidate eligibility; no inferred numeric value.
- Critical violations cannot be overridden by lower-priority sources.

## Candidate generation and simulation
- Six translation candidates for each side of a clash.
- Target clash resolution, remaining clashes, introduced clashes.
- Exact mesh simulation against every other inventory element.
- Clearance enforcement and invalid negative/non-numeric inputs.
- Rule-missing and critical-rule blocks.
- Confirm source scene transforms and geometry remain unchanged during simulation.

## Clash manager and governance
- Stable clash selection, owner/status/due date persistence behavior.
- Reject approval without exact validated simulation, approver, date, and reason.
- Reject candidate/simulation identity mismatch and affected-element mismatch.
- Apply translation, exception during apply, rollback, repeated rollback, deleted node.
- Confirm audit sequence and transaction state transitions.

## Integrations and reports
- Missing provider, unsupported capability, missing revision, provider exception.
- Revision mismatch and stale sync token behavior.
- CSV escaping for commas, quotes, Unicode and newlines; file permission errors.
- Verify clash/proposal report counts and values against source records.

## Version matrix
Run the full matrix on 3ds Max 2022, 2023, 2024, 2025 and 2026. Treat 2027 as pending until separately tested. Record exact build number, OS, test scene, pass/fail, logs and known deviations. Corona and V-Ray must be tested separately only where renderer-specific scene objects or materials are involved.

## Release gate
Do not label this engine production-ready or merge it to main until all critical geometry, rule, transaction and regression tests pass in-host and the results are reviewed.


## In-host self-test harness
Run `fileIn (getDir #userScripts + "\\\\AskerTools\\\\Tests\\\\AT_CoordinationSelfTests.ms")` after the coordination modules are loaded, then run `AT_CoordinationSelfTests.run()` and inspect `AT_CoordinationSelfTests.summary()` plus `lastResults`. The harness creates uniquely named temporary boxes and a plane, deletes only those test nodes, and restores the prior geometry/rule-engine result arrays and rule registry. Run it on a disposable scene first; confirm no test objects remain afterward.
