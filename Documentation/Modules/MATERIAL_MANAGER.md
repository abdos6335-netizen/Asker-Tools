# Project Material & Map Manager (v0.4.0)

## Project identity and revisions
The manager derives a project key from the saved MAX file name. Numbered suffixes such as `REV-01`, `REV-02`, `REVISION 3`, and equivalent separator variations are removed from the end of the name. For example, `Villa.max`, `Villa-REV-01.max`, and `Villa_REV-02.max` share the same project configuration.

The first setup requires the scene to be saved and the user to choose a central MAPS folder. That folder is stored in `Config/material_projects.ini` under the normalized project key. The MAPS location can be changed later from the manager.

## Automatic collection
When enabled, callbacks run after Merge (`#filePostMerge`) and Import (`#postImport`). The manager scans bitmap texture references, copies external files into the configured MAPS folder, and updates the scene bitmap paths to the centralized copies.

Each file is identified by a SHA-256 digest of its contents. If an identical digest is already registered and the central file still exists, the existing copy is reused. This deduplicates content even when source files have different names. The stored asset name is the digest plus the original extension.

## Manual actions
- **Set / Change MAPS Folder:** configure or replace the project's central folder.
- **Collect Maps Now:** scan the currently open scene on demand.
- **Move Existing MAPS:** copy registered assets to a new folder and update matching bitmap references in the current scene. The old folder is intentionally left untouched as a safety backup.

## Preferences and limitations
- Automatic collection can be turned off and the preference persists.
- v0.4.0 currently handles standard `Bitmaptexture` references. Renderer-specific map classes (CoronaBitmap, V-Ray bitmap/proxy assets, IES/HDRI special cases, caches, and proxies) need separate adapters and per-version validation.
- Collection is triggered after Merge and Import. Direct drag/drop, XRef workflows, and renderer-specific asset types require additional event/API verification.
- Hashing reads the full source file into memory; very large textures may take time and memory.
- If a source file is missing or cannot be copied, the manager reports it in the operation list and log; it does not silently replace it.
- No 3ds Max scene file is duplicated. No source asset is deleted.
- In-host testing is intentionally deferred until the user is ready to test. Static repository checks are not proof of MAXScript runtime correctness.
