# Triangle surface-distance regression coverage — 2026-11-23
- Added direct triangle-to-triangle minimum-distance regression cases for parallel offset surfaces and coplanar separated triangles with known expected distances.

# Coordination containment topology — 2026-11-23
- Added global face-connectivity validation for closed mesh records. Disconnected closed shells are conservatively excluded from single-solid containment classification and reported as unverified.
- Preserved connectivity metadata through translated and rotated simulation snapshots; added connected/disconnected face-graph regression cases.

# Coordination geometry input validation — 2026-11-23
- Added explicit rejection of negative and nonnumeric geometry tolerances in both clash-detection entry points, with a dedicated `INVALID_GEOMETRY_TOLERANCE` error and in-host regression coverage.

# Coordination geometry scale handling — 2026-11-23
- Replaced fixed absolute face-area and segment-length degeneracy cutoffs with scale-relative tests, so small but well-shaped geometry is not silently discarded as degenerate.
- Added tiny-segment point-distance and parallel-overlap regression cases.

# Coordination geometry SAT hardening — 2026-11-23
- Normalized usable separating axes before projection, making the SAT epsilon a world-space distance instead of an axis-magnitude-dependent value.
- Replaced the absolute near-zero-axis cutoff with per-axis thresholds relative to the originating edge/normal magnitudes, improving behavior for tiny, long-thin and non-uniformly scaled triangles.
- Tightened closed-mesh ray-hit deduplication from 1e-6 to a scale-aware 1e-9 tolerance to reduce accidental merging of distinct nearby crossings.
- Added in-host regression coverage for coplanar overlap/separation, vertex/edge touch, near-parallel separation, tiny triangles and high-aspect-ratio overlap. MAXScript runtime validation remains pending inside 3ds Max.

# Coordination geometry regression coverage — 2026-11-23
- Extended the segment-distance regression suite with point-to-segment perpendicular distance, zero-length segment handling, and skew segments whose closest points lie in both segment interiors.

# Coordination geometry — 2026-11-23
- Fixed the parallel-segment distance degeneracy in the exact mesh narrow phase. The prior closest-point calculation could miss an interior overlap when parallel segment projections overlapped but the first endpoint projected outside the opposite segment, overstating mesh clearance.
- Added a dedicated point-to-segment distance primitive and a stable parallel fallback using all four endpoint projections; retained the interior closest-point solution for non-parallel segments.
- Added in-host regression cases for collinear overlapping segments and parallel separated segments, plus static validator markers. Runtime MAXScript validation remains pending inside 3ds Max.

### Coordination governance hardening — 2026-11-23
- Approval now verifies the complete simulation-derived clash/rule/affected-element identity sets, not only action ID and transform parameters.
- Added in-host regression cases for order-independent identity matching and tampered resolved/introduced clash sets.

# Changelog

## [0.6.1] - 2026-11-23
- Add a print-styled HTML coordination report covering clashes, clearance, disciplines, missing rules, inspection errors, tracking, approvals, critical proposal issues, proposals, governance audit, and integration revision history.
- Add a Clash Manager action to export the full report as HTML for browser-based printing to PDF.
- Keep CSV as the native tabular export; native PDF and XLSX generation remain unimplemented.

## 0.6.0 - Coordination Engine implementation milestone
- Added explicit metadata-driven adapters for the eight coordination disciplines; unmapped elements remain UNKNOWN.
- Added approved engineering rule lookup with mandatory-code, authority, manufacturer, project, and default source priority.
- Added deterministic six-direction translation and three-axis pivot-rotation candidate generation with non-destructive transformed-mesh simulation.
- Added closed-manifold mesh containment detection, open/non-manifold containment warnings, and degenerate-face handling.
- Added per-element and rule-derived pair clearances with explicit conversion to 3ds Max master units.
- Added jurisdiction-required rule resolution, same-priority conflict detection, and rule-revision invalidation of stale scans/approvals.
- Added project Rule and Discipline Manager UIs, per-element clearance/envelope metadata, severity/discipline/text filters, stale scan/simulation/approval/apply revalidation, XML persistence for rules/mappings/envelopes/tracking/integration tokens/audit history, and an in-host self-test runner.
- Added single-use named engineering approvals, translation/pivot-rotation apply, guarded rollback, immutable target/action snapshots and transaction audit records.
- Added explicit NOT_ASSESSED risk status; unassessed risk is excluded from ranking penalties instead of being represented as zero risk.
- Added revision-aware integration contracts and expanded clash, clearance, discipline, tracking, approval, audit and critical-issue CSV report builders.
- Added UTF-8 CSV export, geometry/discipline/rule-missing reports, source-level validation markers and expanded in-host QA matrix; MAXScript runtime validation remains pending.
- Updated core version to 0.6.0.

## 0.5.0 - Coordination Solution Engine foundation
- Added structured candidate-to-proposal generation from discipline adapter simulation results.
- Added target/resolved clash identity validation and duplicate candidate rejection reporting.
- Kept unvalidated proposals visible but ineligible until simulation is confirmed.
- Added deterministic evaluation and ranking of structured coordination proposals.
- Blocked ineligible proposals with critical violations, missing required rules, or newly introduced clashes.
- Added configurable scoring weights and stable tie-breaking by proposal ID.
- Kept evaluation read-only; no automatic geometry changes or engineering approvals.
- Added module documentation and static validation coverage.
- Added read-only 3ds Max AABB scene inspection and clash discovery.
- Added six-axis move candidate generation with broad-phase rechecks against inventoried nodes.
- Kept all geometry-derived candidates unvalidated pending exact geometry and approved-rule simulation.
- Updated core version to 0.5.0.

## 0.4.0 - Project Material & Map Manager
- Added project-aware MAPS folder configuration persisted per project.
- Added revision filename normalization for REV/REVISION numbered suffixes.
- Added post-Merge and post-Import automatic bitmap collection.
- Added SHA-256 content-based deduplication and relinking of all bitmap references.
- Added configurable auto-collect preference and MAPS folder migration.
- Added material manager documentation and static validation markers.
- Updated core version to 0.4.0.

## 0.3.0 - Scene Manager & Asset Management
- Added scene inventory with class/layer metadata and explicit selection and visibility helpers.
- Added bitmap texture inventory and missing-file detection; no automatic relinking.
- Added cleanup candidate review for hidden nodes and unassigned scene materials; no deletion.
- Added module documentation and expanded static validation.
- Updated core version to 0.3.0.

## 0.2.0 - Scene Audit module
- Added read-only scene audit for duplicate node names, missing bitmap files, and near-zero object scale.
- Added a compact UI for scanning, reviewing findings, and selecting the related scene node.
- Hardened launcher with a clear missing-install message.
- Expanded static validation.

## 0.1.0 - Foundation
- Added bootstrap, logging, persistent settings, compatibility reporting, and environment diagnostics.


## Historical note — Coordination Engine Part 1
- Added a read-only triangle-mesh geometry engine for exact surface-intersection checks using separating-axis tests, including coplanar axes.
- Added minimum triangle-surface distance evaluation and explicit required-clearance shortfall reporting.
- Added result classification and face-level diagnostics; no scene edits or automatic approvals are performed.
- MAXScript runtime and 3ds Max version validation remain pending.

- 2026-11-23: Improved closed-mesh ray parity boundary handling: inclusive shared-edge/shared-vertex ray hits, scale-relative determinant rejection, normalized voting directions, and coincident-hit deduplication. Added in-host shared-edge and shared-vertex regression cases; runtime execution remains pending in 3ds Max.
