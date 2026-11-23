# Changelog

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


## Unreleased — Coordination Engine Part 1
- Added a read-only triangle-mesh geometry engine for exact surface-intersection checks using separating-axis tests, including coplanar axes.
- Added minimum triangle-surface distance evaluation and explicit required-clearance shortfall reporting.
- Added result classification and face-level diagnostics; no scene edits or automatic approvals are performed.
- MAXScript runtime and 3ds Max version validation remain pending.
