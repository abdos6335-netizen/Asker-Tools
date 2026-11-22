/* Asker Tools v0.4.0 - Project Material & Map Manager
   Centralizes bitmap assets per project/revision using content hashes.
   File operations are explicit and logged; no scene files are duplicated.
*/
global AT_MaterialManager
struct AT_MaterialManagerStruct (
    version = "0.4.0",
    settingsFile = "",
    projectKey = "",
    mapsFolder = "",
    autoCollect = true,
    lastReport = #(),

    fn init = (
        local cfg = getDir #userScripts + "\\AskerTools\\Config"
        if not doesDirectoryExist cfg do makeDir cfg
        settingsFile = cfg + "\\material_projects.ini"
        true
    ),

    fn normalizeProjectName rawName = (
        local rx = dotNetObject "System.Text.RegularExpressions.Regex" "(?i)[ _.-]*REV(?:ISION)?[ _.-]*[0-9]+$"
        local result = rx.Replace rawName ""
        trimRight (trimLeft result)
    ),

    fn currentProjectKey = (
        local raw = getFilenameFile maxFileName
        if raw == "" then "" else normalizeProjectName raw
    ),

    fn sectionName = ("Project_" + projectKey),

    fn ensureProject = (
        if settingsFile == "" do init()
        local key = currentProjectKey()
        if key == "" do (
            AT_Logger.warn "Save the scene once before configuring its project MAPS folder"
            return false
        )
        projectKey = key
        local stored = getIniSetting settingsFile (sectionName()) "MapsFolder"
        if stored != "" and doesDirectoryExist stored then mapsFolder = stored
        true
    ),

    fn chooseMapsFolder = (
        if not ensureProject() do return false
        local startAt = if mapsFolder != "" then mapsFolder else maxFilePath
        local chosen = getSavePath caption:("Choose central MAPS folder for " + projectKey) initialDir:startAt
        if chosen == undefined or chosen == "" then return false
        if not doesDirectoryExist chosen do makeDir chosen
        mapsFolder = chosen
        setIniSetting settingsFile (sectionName()) "MapsFolder" mapsFolder
        AT_Logger.info ("Project MAPS folder set: " + mapsFolder)
        true
    ),

    fn assetManifest hash = (
        getIniSetting settingsFile (sectionName()) hash
    ),

    fn setAssetManifest hash path = (
        setIniSetting settingsFile (sectionName()) hash path
    ),

    fn hashFile path = (
        local shaClass = dotNetClass "System.Security.Cryptography.SHA256"
        local fileClass = dotNetClass "System.IO.File"
        local convert = dotNetClass "System.BitConverter"
        local bytes = fileClass.ReadAllBytes path
        local shaObject = shaClass.Create()
        local digest = shaObject.ComputeHash bytes
        shaObject.Dispose()
        substituteString (toLower (convert.ToString digest)) "-" ""
    ),

    fn ensureMapsFolder = (
        if mapsFolder == "" do (
            if not ensureProject() do return false
        )
        if mapsFolder == "" then false else (
            if not doesDirectoryExist mapsFolder do makeDir mapsFolder
            true
        )
    ),

    fn centralizeBitmap bitmap = (
        local source = ""
        try (source = bitmap.filename) catch()
        if source == "" or not doesFileExist source then (
            append lastReport #("MISSING", source, "")
            false
        ) else (
            local digest = ""
            try (digest = hashFile source) catch (
                AT_Logger.warn ("Could not hash bitmap: " + source)
                append lastReport #("HASH_ERROR", source, "")
                return false
            )
            local target = assetManifest digest
            if target == "" or not doesFileExist target then (
                local ext = getFilenameType source
                target = mapsFolder + "\\" + digest + ext
                if (toLower source) != (toLower target) do (
                    try ((dotNetClass "System.IO.File").Copy source target true)
                    catch (
                        AT_Logger.error ("Map copy failed: " + source + " -> " + target)
                        append lastReport #("COPY_ERROR", source, target)
                        return false
                    )
                )
                setAssetManifest digest target
                append lastReport #("COPIED", source, target)
            ) else (
                append lastReport #("REUSED", source, target)
            )
            if (toLower source) != (toLower target) do (
                try (bitmap.filename = target) catch (
                    AT_Logger.error ("Could not relink bitmap reference: " + source)
                    append lastReport #("RELINK_ERROR", source, target)
                    return false
                )
            )
            true
        )
    ),

    fn processSceneAssets = (
        if not ensureMapsFolder() do (
            AT_Logger.warn "Material Manager skipped: project MAPS folder is not configured"
            return false
        )
        lastReport = #()
        local maps = #()
        try (maps = getClassInstances Bitmaptexture) catch()
        for b in maps do centralizeBitmap b
        local copied = 0
        local reused = 0
        local missing = 0
        local failed = 0
        for r in lastReport do (
            case r[1] of (
                "COPIED": copied += 1
                "REUSED": reused += 1
                "MISSING": missing += 1
                default: failed += 1
            )
        )
        AT_Logger.info ("Material Manager: " + copied as string + " copied, " + reused as string + " reused, " + missing as string + " missing, " + failed as string + " failed")
        true
    ),

    fn changeMapsFolder = (
        if not ensureMapsFolder() do return false
        local oldFolder = mapsFolder
        local chosen = getSavePath caption:("Move project MAPS location for " + projectKey) initialDir:oldFolder
        if chosen == undefined or chosen == "" then return false
        if (toLower chosen) == (toLower oldFolder) then return true
        if not doesDirectoryExist chosen do makeDir chosen

        local section = sectionName()
        local keys = getIniSetting settingsFile section
        for hash in keys do (
            local oldPath = getIniSetting settingsFile section hash
            if oldPath != "" and doesFileExist oldPath do (
                local newPath = chosen + "\\" + getFilenameFile oldPath + getFilenameType oldPath
                if (toLower oldPath) != (toLower newPath) do (
                    try (
                        if not doesFileExist newPath do ((dotNetClass "System.IO.File").Copy oldPath newPath)
                        for b in (getClassInstances Bitmaptexture) where (try ((toLower b.filename) == (toLower oldPath)) catch false) do b.filename = newPath
                        setAssetManifest hash newPath
                    ) catch (AT_Logger.error ("Could not migrate map: " + oldPath))
                )
            )
        )
        mapsFolder = chosen
        setIniSetting settingsFile section "MapsFolder" mapsFolder
        AT_Logger.info ("Project MAPS location changed to: " + mapsFolder)
        true
    ),

    fn installCallbacks = (
        callbacks.removeScripts id:#AT_MaterialManager
        callbacks.addScript #filePostMerge "AT_MaterialManager.processSceneAssets()" id:#AT_MaterialManager persistent:false
        callbacks.addScript #postImport "AT_MaterialManager.processSceneAssets()" id:#AT_MaterialManager persistent:false
        true
    ),

    fn show = (
        if settingsFile == "" do init()
        ensureProject()
        try (destroyDialog AT_MaterialManagerRollout) catch()
        rollout AT_MaterialManagerRollout "Asker Tools | Project Material Manager" width:500 height:330 (
            label lblProject "Project: not configured" align:#left
            label lblFolder "MAPS: not configured" align:#left
            button btnSet "Set / Change MAPS Folder" width:190 height:30 align:#left
            button btnScan "Collect Maps Now" width:190 height:30 align:#left
            button btnMove "Move Existing MAPS" width:190 height:30 align:#left
            checkbox chkAuto "Auto-collect after Merge / Import" checked:true align:#left
            label lblStatus "No operation run yet" align:#left
            listbox lbReport "Last operation" items:#() width:475 height:12
            fn refreshLabels = (
                lblProject.text = "Project: " + (if AT_MaterialManager.projectKey == "" then "not configured" else AT_MaterialManager.projectKey)
                lblFolder.text = "MAPS: " + (if AT_MaterialManager.mapsFolder == "" then "not configured" else AT_MaterialManager.mapsFolder)
            )
            on AT_MaterialManagerRollout open do (
                refreshLabels()
                chkAuto.checked = AT_MaterialManager.autoCollect
                if AT_MaterialManager.autoCollect then AT_MaterialManager.installCallbacks() else callbacks.removeScripts id:#AT_MaterialManager
            )
            on btnSet pressed do (
                if AT_MaterialManager.chooseMapsFolder() do refreshLabels()
            )
            on btnScan pressed do (
                if AT_MaterialManager.processSceneAssets() then (
                    lbReport.items = for r in AT_MaterialManager.lastReport collect (r[1] + " | " + r[2] + (if r[3] != "" then " -> " + r[3] else ""))
                    lblStatus.text = AT_MaterialManager.lastReport.count as string + " bitmap references processed"
                )
            )
            on btnMove pressed do (
                if AT_MaterialManager.changeMapsFolder() do refreshLabels()
            )
            on chkAuto changed state do (
                AT_MaterialManager.autoCollect = state
                setIniSetting AT_MaterialManager.settingsFile "General" "AutoCollect" (state as string)
                if state then AT_MaterialManager.installCallbacks()
                else callbacks.removeScripts id:#AT_MaterialManager
            )
        )
        createDialog AT_MaterialManagerRollout style:#(#style_titlebar, #style_sysmenu, #style_toolwindow)
    )
)
AT_MaterialManager = AT_MaterialManagerStruct()
try (AT_MaterialManager.init(); AT_MaterialManager.ensureProject(); if AT_MaterialManager.autoCollect do AT_MaterialManager.installCallbacks()) catch()
