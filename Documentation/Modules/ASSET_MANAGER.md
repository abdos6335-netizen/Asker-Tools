# Asset & Texture Manager

The v0.3.0 implementation inventories `Bitmaptexture` references and checks local file existence. It is intentionally read-only. Missing paths are displayed for manual investigation; relinking, copying, replacing, or modifying external assets is not automated.

Future work: broaden asset coverage to renderer-specific proxies, IES files, HDRI, caches, and renderer maps after per-version API verification.
