# Validation

Run `python Tests/validate_structure.py` from any working directory. This checks required files, basic delimiter balance, and the presence of the Scene Audit checks. It is a static sanity check, not a substitute for running MAXScript inside each supported 3ds Max release.

In-host validation checklist:
1. Launch `AskerTools.ms` from the MAXScript editor after installing the folder under `getDir #userScripts`.
2. Confirm startup log and settings file are created.
3. Run `AT_SceneAudit.show()` and scan a disposable scene containing duplicate names, a missing bitmap path, and a zero-scale node.
4. Confirm selecting a finding selects only its associated scene node.
5. Repeat on each supported Max version; validate 2027 separately before marking it supported.
