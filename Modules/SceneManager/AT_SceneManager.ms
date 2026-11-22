/* Asker Tools v0.3.0 - Scene Manager
   Non-destructive scene inventory and selection utilities.
*/
global AT_SceneManager
struct AT_SceneManagerStruct (
    lastInventory = #(),
    visibilitySnapshot = #(),
    fn inventory = (
        local rows = #()
        for n in objects do (
            local layerName = "Default"
            try (if n.layer != undefined do layerName = n.layer.name) catch()
            local className = (classOf n) as string
            append rows #(n, n.name, className, layerName, n.isHidden, n.isFrozen)
        )
        lastInventory = rows
        AT_Logger.info ("Scene inventory created: " + rows.count as string + " nodes")
        rows
    ),
    fn selectByClass className = (
        local hits = for n in objects where ((classOf n) as string) == className collect n
        if hits.count > 0 then (select hits; hits.count) else 0
    ),
    fn selectByLayer layerName = (
        local hits = for n in objects where (try (n.layer.name == layerName) catch false) collect n
        if hits.count > 0 then (select hits; hits.count) else 0
    ),
    fn hideByLayer layerName hidden:true = (
        local hits = for n in objects where (try (n.layer.name == layerName) catch false) collect n
        for n in hits do n.isHidden = hidden
        hits.count
    ),
    fn isolateNodes nodes = (
        visibilitySnapshot = for n in objects collect #(n, n.isHidden)
        if nodes.count > 0 do (
            for n in objects do n.isHidden = true
            for n in nodes where isValidNode n do n.isHidden = false
            select nodes
        )
        nodes.count
    ),
    fn restoreVisibility = (
        for item in visibilitySnapshot where isValidNode item[1] do item[1].isHidden = item[2]
        visibilitySnapshot = #()
        true
    ),
    fn show = (
        try (destroyDialog AT_SceneManagerRollout) catch()
        rollout AT_SceneManagerRollout "Asker Tools | Scene Manager" width:420 height:310 (
            button btnRefresh "Refresh Inventory" width:150 align:#left
            label lblCount "No inventory yet" align:#left
            listbox lbNodes "Scene Nodes" items:#() width:395 height:17
            button btnSelect "Select Node" width:110 align:#left
            button btnRestore "Restore Visibility" width:110 align:#left
            on btnRefresh pressed do (
                local rows = AT_SceneManager.inventory()
                lbNodes.items = for r in rows collect (r[2] + " | " + r[3] + " | " + r[4])
                lblCount.text = rows.count as string + " scene nodes"
            )
            on btnSelect pressed do (
                if lbNodes.selection > 0 and lbNodes.selection <= AT_SceneManager.lastInventory.count do
                    select AT_SceneManager.lastInventory[lbNodes.selection][1]
            )
            on btnRestore pressed do AT_SceneManager.restoreVisibility()
        )
        createDialog AT_SceneManagerRollout
    )
)
AT_SceneManager = AT_SceneManagerStruct()
