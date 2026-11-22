# Tests

Run static validation from the repository root:

```bash
python Tests/validate_structure.py
```

The validator checks required files, balanced MAXScript delimiters, and feature markers. These checks do not execute MAXScript. Before release, run the in-host checklist in a disposable copy of a test scene in every supported 3ds Max version.

## In-host checklist
1. Launch `AskerTools.ms` after installing the complete folder under `getDir #userScripts`.
2. Confirm startup log and settings file are created and all modules load.
3. Run `AT_SceneAudit.show()` against a disposable scene with known duplicate names, a missing bitmap, and a zero-scale node.
4. Run `AT_SceneManager.show()`; verify inventory metadata and node selection.
5. Test layer selection and visibility helpers on a disposable scene; verify Unhide All restores visibility.
6. Run `AT_AssetManager.show()` with existing and missing bitmap paths.
7. Run `AT_Cleanup.show()`; verify it reports candidates and never deletes or modifies scene content.
8. Repeat on each supported Max version; validate 2027 separately before marking it supported.
