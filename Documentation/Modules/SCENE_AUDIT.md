# Scene Audit

## Checks

| Code | Severity | Description |
|---|---|---|
| `DUPLICATE_NAME` | Warning | Reports object names shared by multiple scene nodes. |
| `MISSING_BITMAP` | Error | Reports bitmap texture references whose file path does not exist. |
| `ZERO_SCALE` | Warning | Reports scene nodes with a scale axis close to zero. |
| `CLEAN_SCENE` | OK | No findings from the current checks. |

## Safety

`AT_SceneAudit.scan()` is read-only. It does not rename nodes, relink maps, change transforms, or delete assets. `selectFinding()` only selects a referenced scene node when one exists. Missing bitmap findings have no node selection target because a bitmap texture can be shared by multiple materials or nodes.

## Use

```maxscript
AT_SceneAudit.show()
-- Or scan without opening the UI:
AT_SceneAudit.scan()
AT_SceneAudit.summary()
```

The checks are a first-pass production aid, not a complete scene validation standard. External assets other than bitmap textures and renderer-specific assets are not yet checked.
