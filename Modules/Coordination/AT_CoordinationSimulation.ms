/* Asker Tools - Non-destructive exact coordination simulation
   Evaluates translated mesh snapshots only; never edits source scene nodes.
*/
global AT_CoordinationSimulation
struct AT_CoordinationSimulationResult (
 simulationId="", movingElementId="", offset=[0,0,0], targetClashIds=#(), baselineClashIds=#(), validated=false, status="NOT_RUN",
 resolvedClashIds=#(), introducedClashIds=#(), remainingClashIds=#(),
 ruleMissingIds=#(), criticalViolationIds=#(), affectedElementIds=#(),
 beforeCount=0, afterCount=0, diagnostics=#()
)
struct AT_CoordinationSimulationStruct (
 version="0.1.0", lastResults=#(), lastErrors=#(),
 fn translatedPoint p offset = (p+offset),
 fn cloneTranslatedMesh source offset = (
  local copy=AT_ExactMeshRecord()
  copy.nodeRef=source.nodeRef; copy.elementId=source.elementId; copy.nodeName=source.nodeName
  copy.faceCount=source.faceCount
  copy.minimum=source.minimum+offset; copy.maximum=source.maximum+offset
  for t in source.triangles do append copy.triangles (AT_ExactTriangle a:(translatedPoint t.a offset) b:(translatedPoint t.b offset) c:(translatedPoint t.c offset) minimum:(t.minimum+offset) maximum:(t.maximum+offset) faceIndex:t.faceIndex)
  copy
 ),
 fn clashKey a b = (if a<b then "MESH_"+a+"_"+b else "MESH_"+b+"_"+a),
 fn collectClashes records clearance epsilon = (
  local ids=#()
  for i=1 to records.count do for j=i+1 to records.count do (
   local r=AT_ExactGeometryEngine.inspectPair records[i] records[j] requiredClearance:clearance epsilon:epsilon
   if r.status!="SEPARATED" do appendIfUnique ids r.clashId
  )
  ids
 ),
 fn simulateTranslation records movingElementId offset targetClashId:"" requiredClearance:0.0 ruleChecks:#() criticalViolationIds:#() simulationId:"" = (
  local result=AT_CoordinationSimulationResult()
  result.simulationId=if simulationId=="" then ("SIM_"+movingElementId) else simulationId
  result.movingElementId=movingElementId; result.offset=offset
  if targetClashId!="" do append result.targetClashIds targetClashId
  result.criticalViolationIds=criticalViolationIds
  for c in ruleChecks where c.status!="RULE_FOUND" do appendIfUnique result.ruleMissingIds (if c.ruleId=="" then c.reason else c.ruleId)
  if result.ruleMissingIds.count>0 then (result.status="BLOCKED_RULE_MISSING"; append result.diagnostics "One or more required rules are missing or unapproved"; append lastResults result; return result)
  if criticalViolationIds.count>0 then (result.status="BLOCKED_CRITICAL_RULE"; append lastResults result; return result)
  local before=collectClashes records requiredClearance 1.0e-6
  local simulated=#(); local found=false
  for source in records do (
   if source.elementId==movingElementId then (append simulated (cloneTranslatedMesh source offset); found=true)
   else append simulated source
  )
  if not found then (result.status="BLOCKED_ELEMENT_NOT_FOUND"; append lastErrors #(movingElementId,"ELEMENT_NOT_FOUND"); append lastResults result; return result)
  local after=collectClashes simulated requiredClearance 1.0e-6
  result.beforeCount=before.count; result.afterCount=after.count; result.baselineClashIds=before
  for id in before where (findItem after id)==0 do append result.resolvedClashIds id
  for id in after where (findItem before id)==0 do append result.introducedClashIds id
  for id in after do append result.remainingClashIds id
  result.affectedElementIds= #(movingElementId)
  local targetResolved=(targetClashId!="" and (findItem after targetClashId)==0 and (findItem before targetClashId)>0)
  if result.introducedClashIds.count>0 then result.status="NEW_CLASHES_INTRODUCED"
  else if targetClashId=="" then result.status="TARGET_CLASH_ID_REQUIRED"
  else if not targetResolved then result.status="TARGET_CLASH_REMAINS"
  else (result.validated=true; result.status="EXACT_GEOMETRY_SIMULATION_PASSED")
  append lastResults result
  result
 ),
 fn toProposalCandidate simulation description:"Exact geometry simulation result" risk:0.0 = (
  local c=AT_CoordinationActionCandidate()
  c.actionId=simulation.simulationId; c.description=description
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
