# Asker Tools

A modular MAXScript toolkit for Autodesk 3ds Max, designed around practical interior-design and visualization production workflows.

## Release status

**0.6.0 — Coordination Engine implementation milestone.** Adds triangle-mesh intersection/distance, closed-mesh containment checks, eight-discipline metadata adapters, approved-source rule hierarchy with jurisdiction and unit normalization, rule-derived pair clearances, translation and pivot-rotation candidates/simulation, a Clash Manager review workflow, explicit approval/apply/rollback guards, XML project persistence, revision-aware integration contracts, CSV report families, and an in-host self-test harness. This remains a development milestone: MAXScript runtime and version compatibility are unverified; full B-rep/solid-kernel handling, semantic discipline envelopes, rerouting/redistribution, non-clearance rule validators, real upstream module connections, and PDF/XLSX output remain incomplete.

Target versions: 3ds Max 2022–2026. 3ds Max 2027 is pending validation. Corona and V-Ray are not yet certified; renderer integrations will be feature-specific and version-checked.

## Install

1. In 3ds Max, evaluate `getDir #userScripts` to locate the user scripts folder.
2. Copy the complete `AskerTools` folder there.
3. Run `AskerTools.ms` from the MAXScript editor.
4. Open tools with `AT_SceneAudit.show()`, `AT_SceneManager.show()`, `AT_AssetManager.show()`, `AT_Cleanup.show()`, and `AT_MaterialManager.show()`.

Logs and settings are written under the same user scripts directory, in `AskerTools/Logs` and `AskerTools/Config`.

## Safety notes

All scans are read-only. Scene Manager visibility commands are explicit actions; Restore Visibility returns nodes to their pre-isolation hidden states. Cleanup only reports candidates and does not delete anything. Coordination simulation is non-destructive. Scene changes are only possible through a separate explicit governance apply call after a validated simulation and named approval; current apply actions are world translation and pivot rotation, with XML-persisted project rules/tracking/audit history. Active approvals are not restored after loading a project. A material not directly assigned to a node may still be referenced indirectly, so candidates require manual review.

## Repository layout

- `Core/` bootstrap services, logging, settings, compatibility checks.
- `Modules/` independent tools.
- `Integrations/` renderer and external application adapters (planned).
- `UI/` shared interface components (planned).
- `Tests/` static checks and in-host test checklist.
- `Documentation/` architecture and module guides.
- `Installer/` packaging helpers (planned).

## Validation limits

Run `python Tests/validate_structure.py` for static checks. No 3ds Max runtime is available in the build environment, so actual MAXScript execution and UI behavior still require in-host validation. Do not treat version targets or renderer integrations as certified until tested in the corresponding installed builds.
