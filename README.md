# Asker Tools

A modular MAXScript toolkit for Autodesk 3ds Max, designed around practical interior-design and visualization production workflows.

## Release status

**0.4.0 — Project Material & Map Manager.** Adds project-aware central MAPS storage, automatic collection after Merge/Import, SHA-256 content deduplication, revision-name association (REV-01, REV-02, etc.), persistent MAPS location settings, and a manual move/relink workflow. The v0.3.0 scene-management tools remain included.

Target versions: 3ds Max 2022–2026. 3ds Max 2027 is pending validation. Corona and V-Ray are not yet certified; renderer integrations will be feature-specific and version-checked.

## Install

1. In 3ds Max, evaluate `getDir #userScripts` to locate the user scripts folder.
2. Copy the complete `AskerTools` folder there.
3. Run `AskerTools.ms` from the MAXScript editor.
4. Open tools with `AT_SceneAudit.show()`, `AT_SceneManager.show()`, `AT_AssetManager.show()`, `AT_Cleanup.show()`, and `AT_MaterialManager.show()`.

Logs and settings are written under the same user scripts directory, in `AskerTools/Logs` and `AskerTools/Config`.

## Safety notes

All scans are read-only. Scene Manager visibility commands are explicit actions; Restore Visibility returns nodes to their pre-isolation hidden states. Cleanup only reports candidates and does not delete anything. A material not directly assigned to a node may still be referenced indirectly, so candidates require manual review.

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
