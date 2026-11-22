/* Asker Tools v0.3.0 - Asset & Texture Manager
   Read-only asset inventory; no paths are changed or relinked.
*/
global AT_AssetManager
struct AT_AssetManagerStruct (
    lastAssets = #(),
    fn scan = (
        local rows = #()
        local bitmaps = #()
        try (bitmaps = getClassInstances Bitmaptexture) catch()
        for b in bitmaps do (
            local p = ""
            try (p = b.filename) catch()
            local exists = (p != "" and doesFileExist p)
            append rows #(b, p, exists)
        )
        lastAssets = rows
        local missingCount = 0
        for r in rows where not r[3] do missingCount += 1
        AT_Logger.info ("Asset scan: " + rows.count as string + " bitmap references; " + missingCount as string + " missing")
        rows
    ),
    fn missing = (
        for r in lastAssets where not r[3] collect r
    ),
    fn show = (
        try (destroyDialog AT_AssetManagerRollout) catch()
        rollout AT_AssetManagerRollout "Asker Tools | Asset Manager" width:600 height:390 (
            button btnScan "Scan Bitmap Assets" width:160 align:#left
            label lblSummary "Read-only scan. No relinking or file changes." align:#left
            listbox lbAssets "Bitmap References" items:#() width:575 height:18
            on btnScan pressed do (
                local rows = AT_AssetManager.scan()
                lbAssets.items = for r in rows collect ((if r[3] then "FOUND | " else "MISSING | ") + r[2])
                lblSummary.text = rows.count as string + " references; " + (AT_AssetManager.missing().count as string) + " missing"
            )
        )
        createDialog AT_AssetManagerRollout
    )
)
AT_AssetManager = AT_AssetManagerStruct()
