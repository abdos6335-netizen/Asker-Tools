/* Asker Tools - Scene Audit
   Read-only scene checks. No scene data is changed by scan().
   MAXScript target: 3ds Max 2022-2026 (2027 pending in-host validation).
*/
global AT_SceneAudit
struct AT_SceneAuditStruct (
    lastResults = #(),
    fn addResult results severity code subject details node = (
        append results #(severity, code, subject, details, node)
    ),
    fn scan = (
        local results = #()
        local nameMap = dotNetObject "System.Collections.Hashtable"
        local duplicateNodes = #()
        local missingMaps = #()
        local nodes = for n in objects collect n

        -- Duplicate object names (reported as groups, not renamed automatically).
        for n in nodes do (
            local key = toLower n.name
            if nameMap.ContainsKey key then (
                local existing = nameMap.Item[key]
                if (findItem duplicateNodes existing) == 0 do append duplicateNodes existing
                appendIfUnique duplicateNodes n
            ) else nameMap.Add key n
        )
        for n in duplicateNodes do addResult results "WARNING" "DUPLICATE_NAME" n.name "Another scene node uses this name" n

        -- Missing bitmap files. Bitmap references are inspected only; no relinking occurs.
        local bitmaps = #()
        try (bitmaps = getClassInstances Bitmaptexture) catch()
        for b in bitmaps do (
            local path = ""
            try (path = b.filename) catch()
            if path != "" and not doesFileExist path do
                addResult results "ERROR" "MISSING_BITMAP" (getFilenameFile path) path undefined
        )

        -- Nodes with zero scale on any axis can cause export/transform issues.
        for n in nodes do (
            local s = n.scale
            if (abs s.x < 0.000001 or abs s.y < 0.000001 or abs s.z < 0.000001) do
                addResult results "WARNING" "ZERO_SCALE" n.name "One or more scale axes are approximately zero" n
        )

        if results.count == 0 do addResult results "OK" "CLEAN_SCENE" "Scene" "No issues found by the current checks" undefined
        lastResults = results
        AT_Logger.info ("Scene audit completed: " + (results.count as string) + " findings")
        results
    ),
    fn summary = (
        local errors = 0
        local warnings = 0
        for r in lastResults do (
            if r[1] == "ERROR" then errors += 1
            if r[1] == "WARNING" then warnings += 1
        )
        #(errors, warnings, lastResults.count)
    ),
    fn selectFinding index = (
        if index >= 1 and index <= lastResults.count then (
            local n = lastResults[index][5]
            if isValidNode n then (select n; true) else false
        ) else false
    ),
    fn show = (
        try (destroyDialog AT_SceneAuditRollout) catch()
        rollout AT_SceneAuditRollout "Asker Tools | Scene Audit" width:560 height:390 (
            button btnScan "Scan Scene" width:120 height:28 align:#left
            label lblSummary "Ready" align:#left
            listbox lbFindings "Findings" items:#() width:535 height:15
            button btnSelect "Select Finding Object" width:170 height:28 align:#left
            on btnScan pressed do (
                local found = AT_SceneAudit.scan()
                local labels = for r in found collect (r[1] + " | " + r[2] + " | " + r[3] + " — " + r[4])
                lbFindings.items = labels
                local s = AT_SceneAudit.summary()
                lblSummary.text = (s[1] as string) + " errors, " + (s[2] as string) + " warnings, " + (s[3] as string) + " total"
            )
            on btnSelect pressed do AT_SceneAudit.selectFinding lbFindings.selection
        )
        createDialog AT_SceneAuditRollout style:#(#style_titlebar, #style_sysmenu, #style_toolwindow)
    )
)
AT_SceneAudit = AT_SceneAuditStruct()
