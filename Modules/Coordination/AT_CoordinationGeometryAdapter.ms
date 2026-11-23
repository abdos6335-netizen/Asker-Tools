/* Asker Tools - Coordination Geometry Adapter
   Read-only broad-phase scene inspection and AABB move simulation.
   This module never transforms, clones, or edits scene nodes.
*/
global AT_CoordinationGeometryAdapter

struct AT_CoordinationAABBRecord (
    nodeRef, elementId = "", nodeName = "",
    minimum = [0,0,0], maximum = [0,0,0]
)

struct AT_CoordinationGeometryMove (
    actionId = "", description = "",
    movingElementId = "", targetClashId = "",
    offset = [0,0,0],
    resolvedClashIds = #(), introducedClashIds = #(),
    affectedElementIds = #(),
    aabbClear = false,
    simulationValidated = false,
    status = "UNVALIDATED_AABB_CANDIDATE"
)

struct AT_CoordinationGeometryAdapterStruct (
    version = "0.1.0",
    lastInventory = #(),
    lastClashes = #(),
    lastCandidates = #(),
    lastErrors = #(),

    fn elementId node = (
        try ((getHandleByAnim node) as string) catch ("")
    ),

    fn getBounds node offset:[0,0,0] = (
        local bounds = nodeGetBoundingBox node node.objectTransform
        #(bounds[1] + offset, bounds[2] + offset)
    ),

    fn boundsOverlap aMin aMax bMin bMax = (
        (aMin.x < bMax.x and aMax.x > bMin.x) and
        (aMin.y < bMax.y and aMax.y > bMin.y) and
        (aMin.z < bMax.z and aMax.z > bMin.z)
    ),

    fn inspect nodes:undefined includeHidden:false = (
        local sourceNodes = if nodes == undefined then objects as array else nodes
        local records = #()
        lastErrors = #()
        for node in sourceNodes where isValidNode node do if includeHidden or not node.isHidden do (
            if (includeHidden or not node.isHidden) do (
                try (
                    local bounds = getBounds node
                    append records (AT_CoordinationAABBRecord nodeRef:node
                        elementId:(elementId node) nodeName:node.name
                        minimum:bounds[1] maximum:bounds[2])
                ) catch (
                    append lastErrors #((elementId node), "BOUNDING_BOX_READ_FAILED")
                )
            )
        )
        lastInventory = records
        records
    ),

    fn clashId idA idB = (
        local firstId = idA
        local secondId = idB
        if firstId > secondId do (
            local swapId = firstId
            firstId = secondId
            secondId = swapId
        )
        "AABB_" + firstId + "_" + secondId
    ),

    fn detectClashes records:undefined = (
        local sourceRecords = if records == undefined then lastInventory else records
        local clashes = #()
        for i = 1 to sourceRecords.count do (
            for j = (i + 1) to sourceRecords.count do (
                if j <= sourceRecords.count do (
                    local a = sourceRecords[i]
                    local b = sourceRecords[j]
                    if boundsOverlap a.minimum a.maximum b.minimum b.maximum do
                        append clashes #(clashId a.elementId b.elementId, a.elementId, b.elementId)
                )
            )
        )
        lastClashes = clashes
        clashes
    ),

    fn candidateOffset moving other axis direction clearance = (
        local result = [0,0,0]
        local distance = 0.0
        if axis == 1 then (
            distance = if direction > 0 then (other.maximum.x - moving.minimum.x + clearance)
                       else (other.minimum.x - moving.maximum.x - clearance)
            result.x = distance
        )
        if axis == 2 then (
            distance = if direction > 0 then (other.maximum.y - moving.minimum.y + clearance)
                       else (other.minimum.y - moving.maximum.y - clearance)
            result.y = distance
        )
        if axis == 3 then (
            distance = if direction > 0 then (other.maximum.z - moving.minimum.z + clearance)
                       else (other.minimum.z - moving.maximum.z - clearance)
            result.z = distance
        )
        result
    ),

    fn simulateAABBMove movingRecord targetRecord records offset = (
        local movedBounds = getBounds movingRecord.nodeRef offset:offset
        local introduced = #()
        for record in records where record.elementId != movingRecord.elementId do (
            if boundsOverlap movedBounds[1] movedBounds[2] record.minimum record.maximum do (
                local id = clashId movingRecord.elementId record.elementId
                if id != clashId movingRecord.elementId targetRecord.elementId do
                    appendIfUnique introduced id
            )
        )
        local targetStillOverlaps = boundsOverlap movedBounds[1] movedBounds[2] targetRecord.minimum targetRecord.maximum
        #(not targetStillOverlaps, introduced)
    ),

    fn generateMoveCandidates records:undefined clashes:undefined clearance:0.0 = (
        local sourceRecords = if records == undefined then lastInventory else records
        local sourceClashes = if clashes == undefined then lastClashes else clashes
        local candidates = #()
        lastErrors = #()
        if classOf clearance != Integer and classOf clearance != Float then (
            append lastErrors #("", "INVALID_CLEARANCE_VALUE")
            return candidates
        )
        if clearance < 0 then (
            append lastErrors #("", "NEGATIVE_CLEARANCE_NOT_ALLOWED")
            return candidates
        )
        for clash in sourceClashes do (
            local recordA = undefined
            local recordB = undefined
            for record in sourceRecords do (
                if record.elementId == clash[2] do recordA = record
                if record.elementId == clash[3] do recordB = record
            )
            if recordA != undefined and recordB != undefined do (
                for movingRecord in #(recordA, recordB) do (
                    local targetRecord = if movingRecord.elementId == recordA.elementId then recordB else recordA
                    for axis = 1 to 3 do (
                        for direction in #(-1, 1) do (
                            local offset = candidateOffset movingRecord targetRecord axis direction clearance
                            local simulation = simulateAABBMove movingRecord targetRecord sourceRecords offset
                            local resolved = if simulation[1] then #(clash[1]) else #()
                            local action = AT_CoordinationGeometryMove()
                            action.actionId = "MOVE_" + movingRecord.elementId + "_" + clash[1] + "_" + (axis as string) + "_" + (direction as string)
                            action.description = "Translate " + movingRecord.nodeName + " along axis " + (axis as string) + " by " + (offset as string)
                            action.movingElementId = movingRecord.elementId
                            action.targetClashId = clash[1]
                            action.offset = offset
                            action.resolvedClashIds = resolved
                            action.introducedClashIds = simulation[2]
                            action.affectedElementIds = #(movingRecord.elementId)
                            action.aabbClear = (simulation[1] and simulation[2].count == 0)
                            action.simulationValidated = false
                            action.status = if action.aabbClear then "AABB_CLEAR_ONLY_REQUIRES_EXACT_VALIDATION" else "AABB_COLLISION_REMAINS_OR_INTRODUCED"
                            append candidates action
                        )
                    )
                )
            )
        )
        lastCandidates = candidates
        candidates
    ),

    fn toProposalCandidates = (
        local result = #()
        for move in lastCandidates do (
            local candidate = AT_CoordinationActionCandidate()
            candidate.actionId = move.actionId
            candidate.description = move.description
            candidate.targetClashIds = #(move.targetClashId)
            candidate.resolvedClashIds = move.resolvedClashIds
            candidate.introducedClashIds = move.introducedClashIds
            candidate.affectedElementIds = move.affectedElementIds
            candidate.risk = 0.0
            candidate.requiresEngineeringApproval = true
            candidate.simulationValidated = false
            append result candidate
        )
        result
    ),

    fn clear = (
        lastInventory = #()
        lastClashes = #()
        lastCandidates = #()
        lastErrors = #()
        true
    )
)
AT_CoordinationGeometryAdapter = AT_CoordinationGeometryAdapterStruct()
