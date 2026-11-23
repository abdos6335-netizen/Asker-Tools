# Asker Tools

A modular MAXScript toolkit for Autodesk 3ds Max, designed around practical interior-design and visualization production workflows.

## Release status

**0.6.0 — Coordination Engine implementation milestone.** Adds triangle-mesh intersection/distance, closed-shell containment with edge and vertex-link checks, eight-discipline classification/mapping, approved-source rules with jurisdiction and master-unit normalization, pair-specific clearance checks, translation and pivot-rotation alternatives, stale-scene revalidation, severity/discipline filters, assignment/tracking, single-use approval and rollback, XML project persistence, revision-aware integration contracts, UTF-8 CSV report builders, and an in-host self-test runner. This remains a development milestone: MAXScript runtime and version compatibility are unverified; full B-rep/solid-kernel handling, geometric service/installation envelopes, rerouting/redistribution, non-clearance rule validators, real upstream module connections, and PDF/XLSX output remain incomplete.

Target versions: 3ds Max 2022–2026. 3ds Max 2027 is pending validation. Corona and V-Ray are not yet certified; renderer integrations will be feature-specific and version-checked.

## Install

1. In 3ds Max, evaluate `getDir #userScripts` to locate the user scripts folder.
2. Copy the complete `AskerTools` folder there.
3. Run `AskerTools.ms` from the MAXScript editor.
4. Open tools with `AT_SceneAudit.show()`, `AT_SceneManager.show()`, `AT_AssetManager.show()`, `AT_Cleanup.show()`, `AT_MaterialManager.show()`, and `AT_ClashManager.show()`. The Clash Manager opens the Rule Manager and Discipline Manager; run `AT_CoordinationSelfTests.run()` for the non-destructive in-host checks.

Logs and settings are written under the same user scripts directory, in `AskerTools/Logs` and `AskerTools/Config`.

## Safety notes

All scans are read-only. Scene Manager visibility commands are explicit actions; Restore Visibility returns nodes to their pre-isolation hidden states. Cleanup only reports candidates and does not delete anything. Coordination simulation is non-destructive. Scene changes are only possible through a separate explicit governance apply call after a validated simulation and named approval; current apply actions are world translation and pivot rotation, with XML-persisted rules, required checks, discipline mappings/envelope metadata, tracking, integration revision tokens and audit history. Active approvals and scene transactions are not restored after loading a project. Risk scoring remains explicitly NOT_ASSESSED until a validated risk model exists. A material not directly assigned to a node may still be referenced indirectly, so candidates require manual review.

## Repository layout

- `Core/` bootstrap services, logging, settings, compatibility checks.
- `Modules/` independent tools.
- `Integrations/` renderer and external application adapters (planned).
- `UI/` shared interface components (planned).
- `Tests/` static checks, self-test harness and in-host QA matrix.
- `Documentation/` architecture and module guides.
- `Installer/` packaging helpers (planned).

## Validation limits

Run `python Tests/validate_structure.py` for static checks. No 3ds Max runtime is available in the build environment, so actual MAXScript execution and UI behavior still require in-host validation. Do not treat version targets or renderer integrations as certified until tested in the corresponding installed builds.
