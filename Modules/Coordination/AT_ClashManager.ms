/* Asker Tools - Coordination Clash Manager
   Review, filter, select and track detected clash records. Read-only scene operations.
*/
global AT_ClashManager
struct AT_ClashTrackingRecord (clashId="", owner="", status="OPEN", dueDate="", note="", severity="INFORMATION")
struct AT_ClashManagerStruct (
 version="0.2.0", clashes=#(), tracking=#(), selectedIndex=0, lastError="", lastSimulations=#(), lastSimulationCandidates=#(), lastSimulationResults=#(),
 fn severityFor clash = (
  if clash.status=="EXACT_MESH_INTERFERENCE" or clash.status=="SOLID_CONTAINMENT_INTERFERENCE" then "HIGH"
  else if clash.status=="CLEARANCE_VIOLATION" then "MEDIUM"
  else if clash.status=="CONTAINMENT_UNVERIFIED" then "HIGH"
  else "INFORMATION"
 ),
 fn clashLabel clash = (
  local distanceText=if clash.minimumDistanceKnown then (formattedPrint clash.minimumDistance format:".4f") else "not measured"
  clash.status+" | "+clash.disciplineA+":"+clash.nameA+" <> "+clash.disciplineB+":"+clash.nameB+" | d="+distanceText
 ),
 fn load clashes = (AT_ClashManager.clashes=clashes; selectedIndex=if clashes.count>0 then 1 else 0; lastSimulations=#(); lastSimulationCandidates=#(); lastSimulationResults=#(); true),
 fn trackingFor clashId = (
  for t in tracking where t.clashId==clashId do return t
  local severity="INFORMATION"
  for clash in clashes where clash.clashId==clashId do severity=severityFor clash
  local record=AT_ClashTrackingRecord clashId:clashId severity:severity
  append tracking record
  record
 ),
 fn setTracking clashId owner:"" status:"OPEN" dueDate:"" note:"" = (
  if (findItem #("OPEN","IN_PROGRESS","UNDER_REVIEW","RESOLVED","WONT_FIX") status)==0 then return false
  local t=trackingFor clashId
  t.owner=owner; t.status=status; t.dueDate=dueDate; t.note=note; true
 ),
 fn getTracking clashId = (trackingFor clashId),
 fn counts = (
  local result=#(#("HIGH",0),#("MEDIUM",0),#("LOW",0),#("INFORMATION",0))
  for c in clashes do (
   local s=severityFor c
   for item in result where item[1]==s do item[2]+=1
  )
  result
 ),
 fn selectClash index = (
  if index<1 or index>clashes.count then return false
  selectedIndex=index
  select #()
  local c=clashes[index]
  for id in #(c.elementA,c.elementB) do (
   local handle=try (id as integer) catch (0)
   if handle>0 do (
    local n=getNodeByHandle handle
    if isValidNode n do selectMore n
   )
  )
  true
 ),
 fn countsLabel = (
  local values=counts()
  "HIGH "+(values[1][2] as string)+" | MEDIUM "+(values[2][2] as string)+" | LOW "+(values[3][2] as string)+" | INFO "+(values[4][2] as string)
 ),
 fn generateAlternatives index clearance:0.0 angles:#(15.0,-15.0,30.0,-30.0) = (
  lastSimulations=#(); lastSimulationCandidates=#(); lastSimulationResults=#()
  if index<1 or index>clashes.count or AT_ExactGeometryEngine.lastMeshes.count==0 then return #()
  AT_CoordinationSolutionGenerator.generateAllAlternatives AT_ExactGeometryEngine.lastMeshes #(clashes[index]) clearance:clearance angles:angles
 ),
 fn simulateAlternative index jurisdiction:"" = (
  local actions=AT_CoordinationSolutionGenerator.lastCandidates+AT_CoordinationSolutionGenerator.lastRotationCandidates
  if index<1 or index>actions.count then return undefined
  local action=actions[index]
  local clash=undefined
  for c in clashes where c.clashId==action.targetClashIds[1] do clash=c
  if clash==undefined then return undefined
  local checks=AT_RuleEngine.evaluateClash clash jurisdiction:jurisdiction
  local simulation=AT_CoordinationSimulation.simulateAction AT_ExactGeometryEngine.lastMeshes action.affectedElementIds[1] actionType:action.actionType offset:action.offset rotationAxis:action.rotationAxis angleDegrees:action.angleDegrees pivot:action.pivot targetClashId:clash.clashId ruleChecks:checks simulationId:action.actionId
  local candidate=AT_CoordinationSimulation.toProposalCandidate simulation action.description
  local ranked=AT_SolutionEngine.generateAndRank #(candidate)
  while lastSimulations.count<index do (append lastSimulations undefined; append lastSimulationCandidates undefined; append lastSimulationResults undefined)
  lastSimulations[index]=simulation; lastSimulationCandidates[index]=candidate; lastSimulationResults[index]=ranked
  #(simulation,candidate,ranked)
 ),
 fn approveAlternative index approver reason approvalDate = (
  if index<1 or index>lastSimulations.count or index>lastSimulationCandidates.count then return false
  AT_CoordinationGovernance.approve lastSimulationCandidates[index] lastSimulations[index] approver reason approvalDate
 ),
 fn applyAlternative index transactionId = (
  if index<1 or index>lastSimulationCandidates.count then return undefined
  local candidate=lastSimulationCandidates[index]
  if candidate==undefined or candidate.affectedElementIds.count!=1 then return undefined
  local node=getNodeByHandle (candidate.affectedElementIds[1] as integer)
  if not isValidNode node then return undefined
  AT_CoordinationGovernance.applyAction candidate.actionId node transactionId
 ),
 fn rankAlternatives = (
  local candidates=AT_CoordinationSolutionGenerator.toProposalCandidates()
  AT_SolutionEngine.generateAndRank candidates
 ),
 fn scan requiredClearance:0.0 = (
  lastSimulations=#(); lastSimulationCandidates=#(); lastSimulationResults=#()
  AT_DisciplineAdapter.inspect()
  AT_ExactGeometryEngine.inspect()
  for meshRecord in AT_ExactGeometryEngine.lastMeshes do for element in AT_DisciplineAdapter.lastInventory where element.elementId==meshRecord.elementId do meshRecord.requiredClearance=element.requiredClearance
  local found=AT_ExactGeometryEngine.detectClashesWithClearances AT_DisciplineAdapter.lastInventory defaultClearance:requiredClearance
  for clash in found do (
   for element in AT_DisciplineAdapter.lastInventory do (
    if element.elementId==clash.elementA then (clash.nameA=element.nodeName; clash.disciplineA=element.discipline)
    if element.elementId==clash.elementB then (clash.nameB=element.nodeName; clash.disciplineB=element.discipline)
   )
  )
  load found
  found
 ),
 fn show = (
  try (destroyDialog AT_ClashManagerRollout) catch()
  rollout AT_ClashManagerRollout "Asker Tools | Clash Manager" width:760 height:900 (
   button btnScan "Detect Exact Mesh Clashes" width:190 height:28 align:#left
   button btnRules "Manage Project Rules" width:190 height:28 align:#left
   label lblSummary "Ready" align:#left
   label lblCounts "HIGH 0 | MEDIUM 0 | LOW 0 | INFO 0" align:#left
   listbox lbClashes "Detected clashes" items:#() width:620 height:18
   button btnSelect "Select Clash Elements" width:160 height:28 align:#left
   button btnGenerate "Generate Solution Alternatives" width:220 height:28 align:#left
   listbox lbSolutions "Generated alternatives" items:#() width:620 height:8
   button btnSimulate "Simulate Selected Alternative" width:220 height:28 align:#left
   group "Engineering approval and application" (
    editText edtApprover "Approver" text:"" width:300
    editText edtApprovalDate "Approval date" text:"" width:300
    editText edtApprovalReason "Approval reason" text:"" width:580
    editText edtJurisdiction "Project jurisdiction" text:"" width:300
    editText edtRequiredChecks "Required check types (; separated)" text:"" width:580
    button btnSetChecks "Set required project checks" width:220 height:26
    button btnApprove "Approve Selected Simulation" width:220 height:26
    editText edtTransactionId "Transaction ID" text:"" width:300
    button btnApply "Apply Approved Action" width:180 height:26
   )
   group "Project data persistence" (
    editText edtStorePath "Project XML path" text:"" width:580
    button btnSaveProject "Save Project Data" width:180 height:26
    button btnLoadProject "Load Project Data" width:180 height:26
   )
   group "Assignment and status" (
    editText edtOwner "Owner" text:"" width:300
    dropdownList ddlStatus "Status" items:#("OPEN","IN_PROGRESS","UNDER_REVIEW","RESOLVED","WONT_FIX") width:300
    editText edtDue "Due date" text:"" width:300
    editText edtNote "Note" text:"" width:580
    button btnSave "Save clash tracking" width:180 height:26
   )
   on btnSaveProject pressed do (
    local ok=AT_CoordinationProjectStore.save edtStorePath.text
    lblSummary.text=if ok then "Project data saved with backup" else "Project save failed; inspect ProjectStore.lastErrors"
   )
   on btnLoadProject pressed do (
    local ok=AT_CoordinationProjectStore.load edtStorePath.text
    lblSummary.text=if ok then "Project data loaded; rule and tracking state restored" else "Project load failed; prior state retained"
   )
   on btnRules pressed do AT_RuleManager.show()
   on btnScan pressed do (
    local found=AT_ClashManager.scan()
    lbClashes.items=for c in found collect (AT_ClashManager.clashLabel c)
    lblSummary.text=found.count as string+" clashes | exact mesh analysis"
    lblCounts.text=AT_ClashManager.countsLabel()
    lbSolutions.items=#()
   )
   on btnGenerate pressed do (
    local actions=AT_ClashManager.generateAlternatives lbClashes.selection
    local ranked=AT_ClashManager.rankAlternatives()
    lbSolutions.items=for item in ranked collect (item.description+" | "+(item.reasons as string))
    lblSummary.text=actions.count as string+" alternatives generated; all await exact simulation and engineering approval"
   )
   on btnSimulate pressed do (
    local result=AT_ClashManager.simulateAlternative lbSolutions.selection jurisdiction:edtJurisdiction.text
    if result==undefined then lblSummary.text="Simulation could not start; configure required rule checks and select an alternative"
    else (
     local simulation=result[1]
     lblSummary.text=simulation.status+" | resolved "+(simulation.resolvedClashIds.count as string)+" | new "+(simulation.introducedClashIds.count as string)
     if lbSolutions.selection<=lbSolutions.items.count do lbSolutions.items[lbSolutions.selection]=simulation.status+" | "+(result[3][1].reasons as string)
    )
   )
   on btnSetChecks pressed do (
    local checkTypes=filterString edtRequiredChecks.text ";"
    local ok=AT_RuleEngine.setRequiredCheckTypes checkTypes
    lblSummary.text=if ok then "Required project checks configured" else "Invalid required check type list"
   )
   on btnApprove pressed do (
    local ok=AT_ClashManager.approveAlternative lbSolutions.selection edtApprover.text edtApprovalReason.text edtApprovalDate.text
    lblSummary.text=if ok then "Engineering approval recorded" else "Approval rejected; simulation and approval details must be valid"
   )
   on btnApply pressed do (
    local tx=AT_ClashManager.applyAlternative lbSolutions.selection edtTransactionId.text
    lblSummary.text=if tx==undefined then "Apply blocked; verify approval, transaction ID and unchanged scene" else tx.state
   )
   on btnSelect pressed do AT_ClashManager.selectClash lbClashes.selection
   on lbClashes selected index do (
    if index>0 and index<=AT_ClashManager.clashes.count do (
     local record=AT_ClashManager.getTracking AT_ClashManager.clashes[index].clashId
     edtOwner.text=record.owner
     edtDue.text=record.dueDate
     edtNote.text=record.note
     local statusIndex=findItem ddlStatus.items record.status
     ddlStatus.selection=if statusIndex>0 then statusIndex else 1
    )
   )
   on btnSave pressed do (
    if lbClashes.selection>0 and lbClashes.selection<=AT_ClashManager.clashes.count then (
     local clashId=AT_ClashManager.clashes[lbClashes.selection].clashId
     local status=if ddlStatus.selection>0 then ddlStatus.items[ddlStatus.selection] else "OPEN"
     AT_ClashManager.setTracking clashId owner:edtOwner.text status:status dueDate:edtDue.text note:edtNote.text
     lblSummary.text="Tracking saved for "+clashId
    )
   )
  )
  createDialog AT_ClashManagerRollout style:#(#style_titlebar,#style_sysmenu,#style_resizing)
 ),
 fn clear = (clashes=#(); tracking=#(); selectedIndex=0; lastError=""; lastSimulations=#(); lastSimulationCandidates=#(); lastSimulationResults=#(); true)
)
AT_ClashManager=AT_ClashManagerStruct()
