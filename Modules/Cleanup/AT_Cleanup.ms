/* Asker Tools v0.3.0 - Cleanup Candidate Review
   Detection only. This module never deletes scene nodes or materials.
*/
global AT_Cleanup
struct AT_CleanupStruct (
    lastCandidates = #(),
    fn scan = (
        local candidates = #()
        for n in objects where n.isHidden do
            append candidates #("HIDDEN_NODE", n.name, n)
        local used = #()
        for n in objects where n.material != undefined do appendIfUnique used n.material
        for m in sceneMaterials where (findItem used m) == 0 do
            append candidates #("UNASSIGNED_MATERIAL_CANDIDATE", m.name, m)
        lastCandidates = candidates
        AT_Logger.info ("Cleanup review candidates: " + candidates.count as string)
        candidates
    ),
    fn show = (
        try (destroyDialog AT_CleanupRollout) catch()
        rollout AT_CleanupRollout "Asker Tools | Cleanup Review" width:580 height:360 (
            button btnScan "Find Review Candidates" width:180 align:#left
            label lblNote "Candidates only — nothing will be deleted." align:#left
            listbox lbCandidates "Review List" items:#() width:555 height:17
            on btnScan pressed do (
                local rows = AT_Cleanup.scan()
                lbCandidates.items = for r in rows collect (r[1] + " | " + r[2])
                lblNote.text = rows.count as string + " candidates found. Review manually before any cleanup."
            )
        )
        createDialog AT_CleanupRollout
    )
)
AT_Cleanup = AT_CleanupStruct()
