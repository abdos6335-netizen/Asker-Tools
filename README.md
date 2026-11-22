# Asker Tools

A modular MAXScript toolkit for Autodesk 3ds Max, designed around practical interior-design and visualization production workflows.

## Release status

**0.2.0 — foundation + first production utility.** Includes a bootstrap, file logger, INI settings, compatibility reporting, environment diagnostics, and Scene Audit. Scene Audit checks duplicate object names, missing bitmap files, and near-zero object scale. Its scan is read-only; it does not rename, relink, delete, or modify scene objects.

Target versions: 3ds Max 2022–2026. 3ds Max 2027 is pending validation. Corona and V-Ray are not yet certified; renderer integrations will be feature-specific and version-checked.

## Install

1. In 3ds Max, evaluate `getDir #userScripts` to locate the user scripts folder.
2. Copy the complete `AskerTools` folder there.
3. Run `AskerTools.ms` from the MAXScript editor.
4. Open Scene Audit with `AT_SceneAudit.show()`.

Logs and settings are written under the same user scripts directory, in `AskerTools/Logs` and `AskerTools/Config`.

## Repository layout

- `Core/` bootstrap services, logging, settings, compatibility checks.
- `Modules/` independent tools.
- `Integrations/` renderer and external application adapters (planned).
- `UI/` shared interface components (planned).
- `Tests/` static checks and in-host test checklist.
- `Documentation/` architecture and compatibility notes.
- `Installer/` packaging helpers (planned).

## Validation limits

Static checks can be run with `python Tests/validate_structure.py`. No 3ds Max runtime is available in the build environment, so actual MAXScript execution and UI behavior still require in-host validation. Do not treat version targets or renderer integrations as certified until tested in the corresponding installed builds.
