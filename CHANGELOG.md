# Changelog

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
