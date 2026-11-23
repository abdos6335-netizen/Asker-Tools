/* Asker Tools - Non-destructive exact coordination simulation
   Evaluates translated and pivot-rotated mesh snapshots only; never edits source scene nodes.
*/
global AT_CoordinationSimulation
struct AT_CoordinationSimulationResult (
 simulationId="", movingElementId="", ruleRevision=0, actionType="TRANSLATE", sourceTransform=undefined, sourcePivot=[0,0,0], offset=[0,0,0], rotationAxis=[0,0,1], angleDegrees=0.0, pivot=[0,0,0], targetClashIds=#(), baselineClashIds=#(), validated=false, status="NOT_RUN",
 resolvedClashIds=#(), introducedClashIds=#(), remainingClashIds=#(),
 ruleMissingIds=#(), criticalViolationIds=#(), affectedElementIds=#(),
 beforeCount=0, afterCount=0, diagnostics=#()
)
struct AT_CoordinationSimulationStruct (
 version="0.2.0", lastResults=#(), lastErrors=#(),
 fn translatedPoint p offset = (p+offset),
 fn cloneTranslatedMesh source offset = (
  local copy=AT_ExactMeshRecord()
  copy.nodeRef=source.nodeRef; copy.sourceTransform=source.sourceTransform; copy.sourcePivot=source.sourcePivot; copy.elementId=source.elementId; copy.nodeName=source.nodeName
  copy.faceCount=source.faceCount; copy.validFaceCount=source.validFaceCount; copy.invalidFaceCount=source.invalidFaceCount
  copy.requiredClearance=source.requiredClearance; copy.serviceClearance=source.serviceClearance; copy.installationClearance=source.installationClearance; copy.isClosed=source.isClosed; copy.isManifold=source.isManifold; copy.topologyChecked=source.topologyChecked
  copy.minimum=source.minimum+offset; copy.maximum=source.maximum+offset
  for t in source.triangles do append copy.triangles (AT_ExactTriangle a:(translatedPoint t.a offset) b:(translatedPoint t.b offset) c:(translatedPoint t.c offset) minimum:(t.minimum+offset) maximum:(t.maximum+offset) faceIndex:t.faceIndex)
  copy
 ),
 fn rotatePointAround point pivot axis angleDegrees = (
  local rotation=quatToMatrix (angleAxis angleDegrees (normalize axis))
  ((point-pivot)*rotation)+pivot
 ),
 fn cloneRotatedMesh source axis angleDegrees pivot = (
  local copy=AT_ExactMeshRecord()
  copy.nodeRef=source.nodeRef; copy.sourceTransform=source.sourceTransform; copy.sourcePivot=source.sourcePivot; copy.elementId=source.elementId; copy.nodeName=source.nodeName
  copy.faceCount=source.faceCount; copy.validFaceCount=source.validFaceCount; copy.invalidFaceCount=source.invalidFaceCount
  copy.requiredClearance=source.requiredClearance; copy.isClosed=source.isClosed; copy.isManifold=source.isManifold; copy.topologyChecked=source.topologyChecked
  local minPoint=[1.0e30,1.0e30,1.0e30]; local maxPoint=[-1.0e30,-1.0e30,-1.0e30]
  for tri in source.triangles do (
   local a=rotatePointAround tri.a pivot axis angleDegrees
   local b=rotatePointAround tri.b pivot axis angleDegrees
   local c=rotatePointAround tri.c pivot axis angleDegrees
   append copy.triangles (AT_ExactGeometryEngine.makeTriangle a b c tri.faceIndex)
   minPoint.x=amin minPoint.x (amin a.x (amin b.x c.x)); minPoint.y=amin minPoint.y (amin a.y (amin b.y c.y)); minPoint.z=amin minPoint.z (amin a.z (amin b.z c.z))
   maxPoint.x=amax maxPoint.x (amax a.x (amax b.x c.x)); maxPoint.y=amax maxPoint.y (amax a.y (amax b.y c.y)); maxPoint.z=amax maxPoint.z (amax a.z (amax b.z c.z))
  )
  copy.minimum=minPoint; copy.maximum=maxPoint
  copy
 ),
 fn cloneActionMesh source actionType offset rotationAxis angleDegrees pivot = (
  if actionType=="TRANSLATE" then cloneTranslatedMesh source offset
  else if actionType=="ROTATE" then cloneRotatedMesh source rotationAxis angleDegrees pivot
  else undefined
 ),
 fn clashKey a b = (if a<b then "MESH_"+a+"_"+b else "MESH_"+b+"_"+a),
 fn collectClashRecords records clearance epsilon pairOverrides:#() = (
  local found=#()
  for i=1 to records.count do for j=i+1 to records.count do (
   local pairRequired=AT_ExactGeometryEngine.pairClearance records[i] records[j] AT_DisciplineAdapter.lastInventory clearance pairOverrides:pairOverrides
   local r=AT_ExactGeometryEngine.inspectPair records[i] records[j] requiredClearance:pairRequired epsilon:epsilon
   local metadata=AT_ExactGeometryEngine.pairRuleMetadata records[i] records[j] pairOverrides:pairOverrides
   r.ruleSeverity=metadata[1]; r.ruleIds=metadata[2]
   if r.status!="SEPARATED" do append found r
  )
  found
 ),
 fn collectClashes records clearance epsilon pairOverrides:#() = (
  local ids=#()
  for r in (collectClashRecords records clearance epsilon pairOverrides:pairOverrides) do append ids r.clashId
  ids
 ),
 fn simulateAction records movingElementId actionType:"TRANSLATE" offset:[0,0,0] rotationAxis:[0,0,1] angleDegrees:0.0 pivot:[0,0,0] targetClashId:"" requiredClearance:0.0 ruleChecks:#() criticalViolationIds:#() simulationId:"" = (
  local result=AT_CoordinationSimulationResult()
  result.simulationId=if simulationId=="" then ("SIM_"+movingElementId) else simulationId
  result.movingElementId=movingElementId; result.ruleRevision=AT_RuleEngine.registryRevision; result.actionType=actionType
  result.offset=offset; result.rotationAxis=rotationAxis; result.angleDegrees=angleDegrees; result.pivot=pivot
  if actionType=="TRANSLATE" and classOf offset!=Point3 then (result.status="INVALID_OFFSET_VECTOR"; append lastResults result; return result)
  if actionType=="ROTATE" and (classOf rotationAxis!=Point3 or classOf pivot!=Point3 or (classOf angleDegrees!=Integer and classOf angleDegrees!=Float) or length rotationAxis<=1.0e-8) then (result.status="INVALID_ROTATION_PARAMETERS"; append lastResults result; return result)
  if actionType!="TRANSLATE" and actionType!="ROTATE" then (result.status="UNSUPPORTED_ACTION_TYPE"; append lastResults result; return result)
  if (classOf requiredClearance!=Integer and classOf requiredClearance!=Float) or requiredClearance<0 then (result.status="INVALID_REQUIRED_CLEARANCE"; append lastResults result; return result)
  if actionType=="ROTATE" and abs angleDegrees>180.0 then (result.status="ROTATION_ANGLE_OUT_OF_RANGE"; append lastResults result; return result)
  if not AT_ClashManager.validateCurrentScene jurisdiction:AT_ClashManager.lastScanJurisdiction then (
   result.status="BLOCKED_STALE_SCENE"
   append result.diagnostics AT_ClashManager.lastError
   append lastResults result
   return result
  )
  if targetClashId!="" do append result.targetClashIds targetClashId
  result.criticalViolationIds=criticalViolationIds
  for c in ruleChecks where c.status!="RULE_FOUND" do appendIfUnique result.ruleMissingIds (if c.ruleId=="" then c.reason else c.ruleId)
  if result.ruleMissingIds.count>0 then (result.status="BLOCKED_RULE_MISSING"; append result.diagnostics "One or more required rules are missing or unapproved"; append lastResults result; return result)
  if criticalViolationIds.count>0 then (result.status="BLOCKED_CRITICAL_RULE"; append lastResults result; return result)
  if ruleChecks.count==0 then (
   result.status="BLOCKED_RULE_CHECKS_NOT_SUPPLIED"
   append result.diagnostics "At least one approved rule evaluation is required before simulation can be validated"
   append lastResults result
   return result
  )
  local beforeRecords=collectClashRecords records requiredClearance 1.0e-6 pairOverrides:AT_ClashManager.lastPairClearances
  for clash in beforeRecords where clash.status=="CONTAINMENT_UNVERIFIED" and (clash.elementA==movingElementId or clash.elementB==movingElementId or clash.clashId==targetClashId) do (
   result.status="BLOCKED_UNVERIFIED_GEOMETRY"
   append result.diagnostics ("Containment could not be verified for "+clash.clashId)
   append lastResults result
   return result
  )
  local before=#()
  for clash in beforeRecords do append before clash.clashId
  local simulated=#(); local found=false
  for source in records do (
   if source.elementId==movingElementId then (
    result.sourceTransform=source.sourceTransform; result.sourcePivot=source.sourcePivot
    if actionType=="ROTATE" and pivot!=source.sourcePivot then (result.status="ROTATION_PIVOT_MISMATCH"; append lastResults result; return result)
    append simulated (cloneActionMesh source actionType offset rotationAxis angleDegrees pivot)
    found=true
   )
   else append simulated source
  )
  if not found then (result.status="BLOCKED_ELEMENT_NOT_FOUND"; append lastErrors #(movingElementId,"ELEMENT_NOT_FOUND"); append lastResults result; return result)
  local afterRecords=collectClashRecords simulated requiredClearance 1.0e-6 pairOverrides:AT_ClashManager.lastPairClearances
  for clash in afterRecords where clash.ruleSeverity=="CRITICAL" do appendIfUnique result.criticalViolationIds clash.clashId
  for clash in afterRecords where clash.status=="CONTAINMENT_UNVERIFIED" and (clash.elementA==movingElementId or clash.elementB==movingElementId) do (
   result.status="BLOCKED_UNVERIFIED_GEOMETRY"
   append result.diagnostics ("Containment could not be verified for "+clash.clashId)
   append lastResults result
   return result
  )
  local after=#()
  for clash in afterRecords do append after clash.clashId
  result.beforeCount=before.count; result.afterCount=after.count; result.baselineClashIds=before
  for id in before where (findItem after id)==0 do append result.resolvedClashIds id
  for id in after where (findItem before id)==0 do append result.introducedClashIds id
  for id in after do append result.remainingClashIds id
  result.affectedElementIds= #(movingElementId)
  local targetResolved=(targetClashId!="" and (findItem after targetClashId)==0 and (findItem before targetClashId)>0)
  if result.criticalViolationIds.count>0 then result.status="BLOCKED_CRITICAL_RULE"
  else if result.introducedClashIds.count>0 then result.status="NEW_CLASHES_INTRODUCED"
  else if targetClashId=="" then result.status="TARGET_CLASH_ID_REQUIRED"
  else if not targetResolved then result.status="TARGET_CLASH_REMAINS"
  else (result.validated=true; result.status="EXACT_GEOMETRY_SIMULATION_PASSED")
  append lastResults result
  result
 ),
 fn simulateTranslation records movingElementId offset targetClashId:"" requiredClearance:0.0 ruleChecks:#() criticalViolationIds:#() simulationId:"" = (
  simulateAction records movingElementId actionType:"TRANSLATE" offset:offset targetClashId:targetClashId requiredClearance:requiredClearance ruleChecks:ruleChecks criticalViolationIds:criticalViolationIds simulationId:simulationId
 ),
 fn simulateRotation records movingElementId axis angleDegrees pivot targetClashId:"" requiredClearance:0.0 ruleChecks:#() criticalViolationIds:#() simulationId:"" = (
  simulateAction records movingElementId actionType:"ROTATE" rotationAxis:axis angleDegrees:angleDegrees pivot:pivot targetClashId:targetClashId requiredClearance:requiredClearance ruleChecks:ruleChecks criticalViolationIds:criticalViolationIds simulationId:simulationId
 ),
 fn toProposalCandidate simulation description:"Exact geometry simulation result" risk:0.0 = (
  local c=AT_CoordinationActionCandidate()
  c.actionId=simulation.simulationId; c.description=description
  c.actionType=simulation.actionType; c.offset=simulation.offset
  c.rotationAxis=simulation.rotationAxis; c.angleDegrees=simulation.angleDegrees; c.pivot=simulation.pivot
  c.targetClashIds=simulation.baselineClashIds
  c.resolvedClashIds=simulation.resolvedClashIds
  c.introducedClashIds=simulation.introducedClashIds
  c.criticalViolationIds=simulation.criticalViolationIds
  c.missingRuleIds=simulation.ruleMissingIds
  c.affectedElementIds=simulation.affectedElementIds
  c.risk=risk
  c.simulationValidated=simulation.validated and simulation.status=="EXACT_GEOMETRY_SIMULATION_PASSED"
  c
 ),
 fn clear = (lastResults=#(); lastErrors=#(); true)
)
AT_CoordinationSimulation=AT_CoordinationSimulationStruct()
