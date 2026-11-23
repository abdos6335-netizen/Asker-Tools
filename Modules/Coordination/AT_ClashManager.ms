/* Asker Tools - Coordination Clash Manager
   Review, filter, select and track detected clash records. Read-only scene operations.
*/
global AT_ClashManager
struct AT_ClashTrackingRecord (clashId="", owner="", status="OPEN", dueDate="", note="", severity="INFORMATION")
struct AT_ClashManagerStruct (
 version="0.3.0", clashes=#(), tracking=#(), selectedIndex=0, lastError="", lastSimulations=#(), lastSimulationCandidates=#(), lastSimulationResults=#(), lastPairClearances=#(), lastRuleMissingPairs=#(), lastGeometryErrors=#(), lastDisciplineErrors=#(), lastScanRuleRevision=-1, lastScanJurisdiction="", lastScanRequiredChecks=#(), lastDisciplineMappingRevision=-1, lastDisciplineMetadataRevision=-1, lastDisciplineInventory=#(), lastScanMeshes=#(), visibleClashIndices=#(),
 fn severityFor clash = (
  local base="INFORMATION"
  if clash.status=="EXACT_MESH_INTERFERENCE" or clash.status=="SOLID_CONTAINMENT_INTERFERENCE" or clash.status=="CONTAINMENT_UNVERIFIED" then base="HIGH"
  else if clash.status=="CLEARANCE_VIOLATION" then base="MEDIUM"
  local baseRank=findItem #("INFORMATION","LOW","MEDIUM","HIGH","CRITICAL") base
  local ruleRank=findItem #("INFORMATION","LOW","MEDIUM","HIGH","CRITICAL") clash.ruleSeverity
  if ruleRank!=undefined and ruleRank>baseRank then clash.ruleSeverity else base
 ),
 fn clashLabel clash = (
  local distanceText=if clash.minimumDistanceKnown then (formattedPrint clash.minimumDistance format:".4f") else "not measured"
  (severityFor clash)+" | "+clash.status+" | "+clash.disciplineA+":"+clash.nameA+" <> "+clash.disciplineB+":"+clash.nameB+" | d="+distanceText
 ),
 fn load clashes = (AT_ClashManager.clashes=clashes; selectedIndex=if clashes.count>0 then 1 else 0; lastSimulations=#(); lastSimulationCandidates=#(); lastSimulationResults=#(); true),
 fn trackingFor clashId = (
  local severity="INFORMATION"
  for clash in clashes where clash.clashId==clashId do severity=severityFor clash
  for t in tracking where t.clashId==clashId do (t.severity=severity; return t)
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
  local result=#(#("CRITICAL",0),#("HIGH",0),#("MEDIUM",0),#("LOW",0),#("INFORMATION",0))
  for c in clashes do (
   local s=severityFor c
   for item in result where item[1]==s do item[2]+=1
  )
  result
 ),
 fn filteredClashIndices severityFilter:"ALL" disciplineFilter:"ALL" statusFilter:"ALL" searchText:"" = (
  local matches=#()
  local query=toLower searchText
  for i=1 to clashes.count do (
   local clash=clashes[i]
   local severity=severityFor clash
   local severityMatch=(severityFilter=="ALL" or severity==severityFilter)
   local disciplineMatch=(disciplineFilter=="ALL" or clash.disciplineA==disciplineFilter or clash.disciplineB==disciplineFilter)
   local haystack=toLower (clash.nameA+" "+clash.nameB+" "+clash.elementA+" "+clash.elementB)
   local trackingStatus="OPEN"
   for record in tracking where record.clashId==clash.clashId do trackingStatus=record.status
   local statusMatch=(statusFilter=="ALL" or trackingStatus==statusFilter)
   local textMatch=(query=="" or (findString haystack query)!=undefined)
   if severityMatch and disciplineMatch and statusMatch and textMatch do append matches i
  )
  visibleClashIndices=matches
  matches
 ),
 fn refreshClashList listControl severityFilter:"ALL" disciplineFilter:"ALL" statusFilter:"ALL" searchText:"" = (
  local indices=filteredClashIndices severityFilter:severityFilter disciplineFilter:disciplineFilter statusFilter:statusFilter searchText:searchText
  listControl.items=for i in indices collect (clashLabel clashes[i])
  true
 ),
 fn selectVisibleClash visibleIndex = (
  if visibleIndex<1 or visibleIndex>visibleClashIndices.count then return false
  selectClash visibleClashIndices[visibleIndex]
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
  "CRITICAL "+(values[1][2] as string)+" | HIGH "+(values[2][2] as string)+" | MEDIUM "+(values[3][2] as string)+" | LOW "+(values[4][2] as string)+" | INFO "+(values[5][2] as string)
 ),
 fn disciplineInventoryMatches oldInventory newInventory = (
  if oldInventory.count!=newInventory.count then return false
  for old in oldInventory do (
   local current=undefined
   for item in newInventory where item.elementId==old.elementId do current=item
   if current==undefined then return false
   if old.nodeName!=current.nodeName or old.discipline!=current.discipline or old.elementType!=current.elementType or old.source!=current.source or old.sourceRevision!=current.sourceRevision or old.requiredClearance!=current.requiredClearance or (old.serviceEnvelope as string)!=(current.serviceEnvelope as string) or (old.installationEnvelope as string)!=(current.installationEnvelope as string) or old.boundsMin!=current.boundsMin or old.boundsMax!=current.boundsMax then return false
  )
  true
 ),
 fn meshInventoryMatches oldRecords newRecords = (
  if oldRecords.count!=newRecords.count then return false
  for old in oldRecords do (
   local current=undefined
   for item in newRecords where item.elementId==old.elementId do current=item
   if current==undefined or not isValidNode current.nodeRef then return false
   if old.sourceTransform!=current.sourceTransform or old.sourcePivot!=current.sourcePivot or old.triangles.count!=current.triangles.count or old.invalidFaceCount!=current.invalidFaceCount then return false
   for i=1 to old.triangles.count do (
    local a=old.triangles[i]; local b=current.triangles[i]
    if a.a!=b.a or a.b!=b.b or a.c!=b.c or a.faceIndex!=b.faceIndex then return false
   )
  )
  true
 ),
 fn validateCurrentScene jurisdiction:"" = (
  if lastScanRuleRevision!=AT_RuleEngine.registryRevision or jurisdiction!=lastScanJurisdiction or (AT_RuleEngine.requiredCheckTypes as string)!=(lastScanRequiredChecks as string) then (lastError="RULES_OR_JURISDICTION_CHANGED_RESCAN_REQUIRED"; return false)
  if lastDisciplineMappingRevision!=AT_DisciplineAdapter.mappingRevision or lastDisciplineMetadataRevision!=AT_DisciplineAdapter.metadataRevision then (lastError="DISCIPLINE_METADATA_CHANGED_RESCAN_REQUIRED"; return false)
  local savedInventory=lastDisciplineInventory
  AT_DisciplineAdapter.inspect()
  if not disciplineInventoryMatches savedInventory AT_DisciplineAdapter.lastInventory then (lastError="DISCIPLINE_INVENTORY_CHANGED_RESCAN_REQUIRED"; return false)
  if AT_DisciplineAdapter.lastErrors.count>0 then (lastError="DISCIPLINE_INSPECTION_ERRORS_PRESENT"; return false)
  local savedMeshes=lastScanMeshes
  AT_ExactGeometryEngine.inspect()
  AT_ExactGeometryEngine.applyDisciplineMetadata AT_ExactGeometryEngine.lastMeshes AT_DisciplineAdapter.lastInventory
  if not meshInventoryMatches savedMeshes AT_ExactGeometryEngine.lastMeshes then (lastError="SCENE_GEOMETRY_CHANGED_RESCAN_REQUIRED"; return false)
  if AT_ExactGeometryEngine.lastErrors.count>0 then (lastError="GEOMETRY_INSPECTION_ERRORS_PRESENT"; return false)
  lastError=""
  true
 ),
 fn generateAlternatives index clearance:0.0 angles:#(15.0,-15.0,30.0,-30.0) = (
  lastSimulations=#(); lastSimulationCandidates=#(); lastSimulationResults=#()
  AT_CoordinationSolutionGenerator.clear(); AT_SolutionEngine.clearResults()
  if index<1 or index>clashes.count or AT_ExactGeometryEngine.lastMeshes.count==0 then return #()
  if not validateCurrentScene jurisdiction:lastScanJurisdiction then (
   AT_CoordinationSolutionGenerator.clear(); AT_SolutionEngine.clearResults()
   return #()
  )
  local required=amax clearance clashes[index].requiredClearance
  AT_CoordinationSolutionGenerator.generateAllAlternatives AT_ExactGeometryEngine.lastMeshes #(clashes[index]) clearance:required angles:angles
 ),
 fn simulateAlternative index jurisdiction:"" = (
  local actions=AT_CoordinationSolutionGenerator.lastCandidates+AT_CoordinationSolutionGenerator.lastRotationCandidates
  if index<1 or index>actions.count then return undefined
  if lastScanRuleRevision!=AT_RuleEngine.registryRevision or jurisdiction!=lastScanJurisdiction or (AT_RuleEngine.requiredCheckTypes as string)!=(lastScanRequiredChecks as string) then (lastError="RULES_OR_JURISDICTION_CHANGED_RESCAN_REQUIRED"; return undefined)
  if lastDisciplineMappingRevision!=AT_DisciplineAdapter.mappingRevision or lastDisciplineMetadataRevision!=AT_DisciplineAdapter.metadataRevision then (lastError="DISCIPLINE_METADATA_CHANGED_RESCAN_REQUIRED"; return undefined)
  local action=actions[index]
  local movingId=action.affectedElementIds[1]
  for missing in lastRuleMissingPairs where missing[1]==movingId or missing[2]==movingId do (
   lastError="RULE_MISSING_FOR_AFFECTED_ELEMENT: "+missing[3]+" | "+missing[4]
   return undefined
  )
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
 fn rollbackTransaction transactionId reason = (
  if transactionId=="" or reason=="" then return false
  AT_CoordinationGovernance.rollback transactionId reason
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
 fn scan requiredClearance:0.0 jurisdiction:"" = (
  if (classOf requiredClearance!=Integer and classOf requiredClearance!=Float) or requiredClearance<0 then (lastError="INVALID_REQUIRED_CLEARANCE"; load #(); return #())
  load #()
  lastError=""
  AT_UnitConversionEngine.clearErrors()
  lastSimulations=#(); lastSimulationCandidates=#(); lastSimulationResults=#()
  lastPairClearances=#(); lastRuleMissingPairs=#()
  AT_CoordinationSolutionGenerator.clear(); AT_SolutionEngine.clearResults()
  AT_CoordinationSimulation.clear(); AT_RuleEngine.clearEvaluations()
  lastScanRuleRevision=AT_RuleEngine.registryRevision
  lastScanJurisdiction=jurisdiction
  lastScanRequiredChecks=AT_RuleEngine.requiredCheckTypes
  AT_DisciplineAdapter.inspect()
  lastDisciplineMappingRevision=AT_DisciplineAdapter.mappingRevision
  lastDisciplineMetadataRevision=AT_DisciplineAdapter.metadataRevision
  lastDisciplineInventory=AT_DisciplineAdapter.lastInventory
  AT_ExactGeometryEngine.inspect()
  lastScanMeshes=AT_ExactGeometryEngine.lastMeshes
  AT_ExactGeometryEngine.applyDisciplineMetadata lastScanMeshes lastDisciplineInventory
  lastGeometryErrors=AT_ExactGeometryEngine.lastErrors
  lastDisciplineErrors=AT_DisciplineAdapter.lastErrors
  for meshRecord in AT_ExactGeometryEngine.lastMeshes do for element in AT_DisciplineAdapter.lastInventory where element.elementId==meshRecord.elementId do meshRecord.requiredClearance=element.requiredClearance
  for i=1 to AT_ExactGeometryEngine.lastMeshes.count do for j=i+1 to AT_ExactGeometryEngine.lastMeshes.count do (
   local meshA=AT_ExactGeometryEngine.lastMeshes[i]
   local meshB=AT_ExactGeometryEngine.lastMeshes[j]
   local elementA=undefined; local elementB=undefined
   for item in AT_DisciplineAdapter.lastInventory do (
    if item.elementId==meshA.elementId then elementA=item
    if item.elementId==meshB.elementId then elementB=item
   )
   local pairRequired=requiredClearance
   if meshA.requiredClearance!=undefined do pairRequired=amax pairRequired meshA.requiredClearance
   if meshB.requiredClearance!=undefined do pairRequired=amax pairRequired meshB.requiredClearance
   if elementA==undefined or elementB==undefined or elementA.discipline=="UNKNOWN" or elementB.discipline=="UNKNOWN" then append lastRuleMissingPairs #(meshA.elementId,meshB.elementId,"","DISCIPLINE_CLASSIFICATION_REQUIRED")
   else (
    local pair=AT_ExactClashRecord elementA:meshA.elementId elementB:meshB.elementId disciplineA:elementA.discipline disciplineB:elementB.discipline
    local evaluations=AT_RuleEngine.evaluateClash pair jurisdiction:jurisdiction recordResults:false
    local ruleIds=#(); local pairSeverity="INFORMATION"
    for evaluation in evaluations do (
     if evaluation.status!="RULE_FOUND" then append lastRuleMissingPairs #(meshA.elementId,meshB.elementId,evaluation.checkType,evaluation.reason)
     else if (findItem #("CLEARANCE","MIN_CLEARANCE","SERVICE_CLEARANCE","INSTALLATION_CLEARANCE") evaluation.checkType)>0 and evaluation.unitConversionValid then (
      pairRequired=amax pairRequired evaluation.valueInSystemUnits
      appendIfUnique ruleIds evaluation.ruleId
      if (findItem #("INFORMATION","LOW","MEDIUM","HIGH","CRITICAL") evaluation.severity)>(findItem #("INFORMATION","LOW","MEDIUM","HIGH","CRITICAL") pairSeverity) do pairSeverity=evaluation.severity
     )
    )
    if pairRequired>0 or ruleIds.count>0 do append lastPairClearances (AT_ExactPairClearanceRecord elementA:meshA.elementId elementB:meshB.elementId requiredClearance:pairRequired severity:pairSeverity ruleIds:ruleIds)
   )
  )
  local found=AT_ExactGeometryEngine.detectClashesWithClearances AT_DisciplineAdapter.lastInventory defaultClearance:requiredClearance pairOverrides:lastPairClearances
  for clash in found do (
   for element in AT_DisciplineAdapter.lastInventory do (
    if element.elementId==clash.elementA then (clash.nameA=element.nodeName; clash.disciplineA=element.discipline)
    if element.elementId==clash.elementB then (clash.nameB=element.nodeName; clash.disciplineB=element.discipline)
   )
  )
  load found
  for record in tracking do for clash in found where clash.clashId==record.clashId do record.severity=severityFor clash
  found
 ),
 fn show = (
  try (destroyDialog AT_ClashManagerRollout) catch()
  rollout AT_ClashManagerRollout "Asker Tools | Clash Manager" width:760 height:900 (
   button btnScan "Detect Exact Mesh Clashes" width:190 height:28 align:#left
   button btnRules "Manage Project Rules" width:190 height:28 align:#left
   button btnDisciplines "Manage Disciplines and Envelopes" width:230 height:28 align:#left
   label lblSummary "Ready" align:#left
   label lblCounts "CRITICAL 0 | HIGH 0 | MEDIUM 0 | LOW 0 | INFO 0" align:#left
   label lblRuleMissing "Missing rule checks: 0" align:#left
   label lblGeometryErrors "Geometry inspection errors: 0" align:#left
   label lblDisciplineErrors "Discipline inspection errors: 0" align:#left
   dropdownList ddlSeverityFilter "Severity filter" items:#("ALL","CRITICAL","HIGH","MEDIUM","LOW","INFORMATION") width:180
   dropdownList ddlDisciplineFilter "Discipline filter" items:#("ALL","ARCHITECTURE","STRUCTURE","ELECTRICAL","HVAC","FIRE_FIGHTING","PLUMBING","LOW_CURRENT","INTERIOR_ELEMENTS") width:260
   dropdownList ddlStatusFilter "Status filter" items:#("ALL","OPEN","IN_PROGRESS","UNDER_REVIEW","RESOLVED","WONT_FIX") width:200
   editText edtClashSearch "Search element / ID" text:"" width:300
   button btnFilter "Apply Filters" width:140 height:26
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
    editText edtRollbackTransactionId "Transaction ID to rollback" text:"" width:300
    editText edtRollbackReason "Rollback reason" text:"" width:300
    button btnRollback "Rollback Applied Action" width:200 height:26
   )
   group "CSV reports" (
    editText edtReportPath "CSV / HTML output path" text:"" width:580
    button btnExportClashes "Export Clash Report" width:180 height:26
    button btnExportGeometryErrors "Export Geometry Errors" width:200 height:26
    button btnExportDisciplineErrors "Export Discipline Errors" width:220 height:26
    button btnExportMissing "Export Missing Rules" width:180 height:26
    button btnExportTracking "Export Tracking" width:180 height:26
    button btnExportAudit "Export Audit History" width:200 height:26
    button btnExportApprovals "Export Approved Solutions" width:210 height:26
    button btnExportProposals "Export Proposal Results" width:210 height:26
    button btnExportHTML "Export Printable Full Report (HTML / PDF-ready)" width:300 height:28
   )
   group "Internal QA" (
    button btnSelfTests "Run Non-Destructive Internal Self-Tests" width:270 height:28
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
   on btnExportHTML pressed do (
    local ok=AT_CoordinationReports.exportFullHTML edtReportPath.text
    lblSummary.text=if ok then "Printable HTML report exported; open it in a browser and Print to PDF" else "HTML report export failed; inspect CoordinationReports.lastErrors"
   )
   on btnExportClashes pressed do (
    local rows=AT_CoordinationReports.buildClashRows AT_ClashManager.clashes
    local ok=AT_CoordinationReports.exportCSV rows edtReportPath.text
    lblSummary.text=if ok then "Clash CSV exported" else "Clash CSV export failed"
   )
   on btnExportGeometryErrors pressed do (
    local rows=AT_CoordinationReports.buildGeometryErrorRows AT_ClashManager.lastGeometryErrors
    local ok=AT_CoordinationReports.exportCSV rows edtReportPath.text
    lblSummary.text=if ok then "Geometry error CSV exported" else "Geometry error CSV export failed"
   )
   on btnExportDisciplineErrors pressed do (
    local rows=AT_CoordinationReports.buildDisciplineErrorRows AT_ClashManager.lastDisciplineErrors
    local ok=AT_CoordinationReports.exportCSV rows edtReportPath.text
    lblSummary.text=if ok then "Discipline error CSV exported" else "Discipline error CSV export failed"
   )
   on btnExportMissing pressed do (
    local rows=AT_CoordinationReports.buildRuleMissingRows AT_ClashManager.lastRuleMissingPairs
    local ok=AT_CoordinationReports.exportCSV rows edtReportPath.text
    lblSummary.text=if ok then "Missing-rule CSV exported" else "Missing-rule CSV export failed"
   )
   on btnExportTracking pressed do (
    local rows=AT_CoordinationReports.buildTrackingRows AT_ClashManager.tracking
    local ok=AT_CoordinationReports.exportCSV rows edtReportPath.text
    lblSummary.text=if ok then "Tracking CSV exported" else "Tracking CSV export failed"
   )
   on btnExportApprovals pressed do (
    local rows=AT_CoordinationReports.buildApprovalRows AT_CoordinationGovernance.approvals
    local ok=AT_CoordinationReports.exportCSV rows edtReportPath.text
    lblSummary.text=if ok then "Approval CSV exported" else "Approval CSV export failed"
   )
   on btnExportProposals pressed do (
    local rows=AT_CoordinationReports.buildProposalRows AT_SolutionEngine.lastResults
    local ok=AT_CoordinationReports.exportCSV rows edtReportPath.text
    lblSummary.text=if ok then "Proposal CSV exported" else "Proposal CSV export failed"
   )
   on btnExportAudit pressed do (
    local rows=AT_CoordinationReports.buildAuditRows AT_CoordinationGovernance.auditLog
    local ok=AT_CoordinationReports.exportCSV rows edtReportPath.text
    lblSummary.text=if ok then "Audit CSV exported" else "Audit CSV export failed"
   )
   on btnSelfTests pressed do (
    local testPath=AT_Core.root+"\\Tests\\AT_CoordinationSelfTests.ms"
    if doesFileExist testPath then (
     try (
      fileIn testPath
      AT_CoordinationSelfTests.run()
      lblSummary.text=AT_CoordinationSelfTests.summary()
     ) catch (lblSummary.text="Internal self-test failed to load/run: "+getCurrentException())
    ) else lblSummary.text="Self-test file not found: "+testPath
   )
   on btnSaveProject pressed do (
    local ok=AT_CoordinationProjectStore.save edtStorePath.text
    lblSummary.text=if ok then "Project data saved with backup" else "Project save failed; inspect ProjectStore.lastErrors"
   )
   on btnLoadProject pressed do (
    local ok=AT_CoordinationProjectStore.load edtStorePath.text
    lblSummary.text=if ok then "Project data loaded; rule and tracking state restored" else "Project load failed; prior state retained"
    if ok then (lbClashes.items=#(); lbSolutions.items=#(); lblCounts.text=AT_ClashManager.countsLabel(); lblRuleMissing.text="Missing rule checks: 0"; lblGeometryErrors.text="Geometry inspection errors: 0"; lblDisciplineErrors.text="Discipline inspection errors: 0")
   )
   on btnRules pressed do AT_RuleManager.show()
   on btnDisciplines pressed do AT_DisciplineManager.show()
   on btnScan pressed do (
    local found=AT_ClashManager.scan jurisdiction:edtJurisdiction.text
    ddlSeverityFilter.selection=1; ddlDisciplineFilter.selection=1; ddlStatusFilter.selection=1; edtClashSearch.text=""
    AT_ClashManager.refreshClashList lbClashes severityFilter:"ALL" disciplineFilter:"ALL" statusFilter:"ALL" searchText:""
    lblSummary.text=(found.count as string)+" clashes | exact mesh analysis"
    lblCounts.text=AT_ClashManager.countsLabel()
    lblRuleMissing.text="Missing rule checks: "+(AT_ClashManager.lastRuleMissingPairs.count as string)
    lblGeometryErrors.text="Geometry inspection errors: "+(AT_ClashManager.lastGeometryErrors.count as string)
    lblDisciplineErrors.text="Discipline inspection errors: "+(AT_ClashManager.lastDisciplineErrors.count as string)
    lbSolutions.items=#()
   )
   on btnFilter pressed do (
    AT_CoordinationSolutionGenerator.clear(); AT_SolutionEngine.clearResults()
    AT_ClashManager.lastSimulations=#(); AT_ClashManager.lastSimulationCandidates=#(); AT_ClashManager.lastSimulationResults=#()
    lbSolutions.items=#()
    AT_ClashManager.refreshClashList lbClashes severityFilter:(ddlSeverityFilter.items[amax 1 ddlSeverityFilter.selection]) disciplineFilter:(ddlDisciplineFilter.items[amax 1 ddlDisciplineFilter.selection]) statusFilter:(ddlStatusFilter.items[amax 1 ddlStatusFilter.selection]) searchText:edtClashSearch.text
   )
   on btnGenerate pressed do (
    local actualClashIndex=if lbClashes.selection>0 and lbClashes.selection<=AT_ClashManager.visibleClashIndices.count then AT_ClashManager.visibleClashIndices[lbClashes.selection] else 0
    local actions=AT_ClashManager.generateAlternatives actualClashIndex
    local ranked=AT_ClashManager.rankAlternatives()
    lbSolutions.items=for item in ranked collect (item.description+" | risk "+item.riskAssessment+" | "+(item.reasons as string))
    lblSummary.text=if actions.count>0 then ((actions.count as string)+" alternatives generated; simulation and approval required") else (if AT_ClashManager.lastError!="" then AT_ClashManager.lastError else "No alternatives generated")
   )
   on btnSimulate pressed do (
    local result=AT_ClashManager.simulateAlternative lbSolutions.selection jurisdiction:edtJurisdiction.text
    if result==undefined then (
     lblSummary.text=if AT_ClashManager.lastError!="" then AT_ClashManager.lastError else "Simulation could not start; configure required rule checks and select an alternative"
    ) else (
     local simulation=result[1]
     lblSummary.text=simulation.status+" | resolved "+(simulation.resolvedClashIds.count as string)+" | new "+(simulation.introducedClashIds.count as string)
     if lbSolutions.selection<=lbSolutions.items.count do lbSolutions.items[lbSolutions.selection]=simulation.status+" | "+(result[3][1].reasons as string)
    )
   )
   on btnSetChecks pressed do (
    local checkTypes=filterString edtRequiredChecks.text "; "
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
   on btnSelect pressed do AT_ClashManager.selectVisibleClash lbClashes.selection
   on lbClashes selected index do (
    AT_CoordinationSolutionGenerator.clear(); AT_SolutionEngine.clearResults()
    AT_ClashManager.lastSimulations=#(); AT_ClashManager.lastSimulationCandidates=#(); AT_ClashManager.lastSimulationResults=#()
    lbSolutions.items=#()
    if index>0 and index<=AT_ClashManager.visibleClashIndices.count do (
     local actualIndex=AT_ClashManager.visibleClashIndices[index]
     local record=AT_ClashManager.getTracking AT_ClashManager.clashes[actualIndex].clashId
     edtOwner.text=record.owner
     edtDue.text=record.dueDate
     edtNote.text=record.note
     local statusIndex=findItem ddlStatus.items record.status
     ddlStatus.selection=if statusIndex>0 then statusIndex else 1
    )
   )
   on btnRollback pressed do (
    local ok=AT_ClashManager.rollbackTransaction edtRollbackTransactionId.text edtRollbackReason.text
    lblSummary.text=if ok then "Transaction rolled back" else "Rollback blocked; verify transaction ID, target state and reason"
   )
   on btnSave pressed do (
    if lbClashes.selection>0 and lbClashes.selection<=AT_ClashManager.visibleClashIndices.count then (
     local actualIndex=AT_ClashManager.visibleClashIndices[lbClashes.selection]
     local clashId=AT_ClashManager.clashes[actualIndex].clashId
     local status=if ddlStatus.selection>0 then ddlStatus.items[ddlStatus.selection] else "OPEN"
     AT_ClashManager.setTracking clashId owner:edtOwner.text status:status dueDate:edtDue.text note:edtNote.text
     AT_ClashManager.refreshClashList lbClashes severityFilter:(ddlSeverityFilter.items[amax 1 ddlSeverityFilter.selection]) disciplineFilter:(ddlDisciplineFilter.items[amax 1 ddlDisciplineFilter.selection]) statusFilter:(ddlStatusFilter.items[amax 1 ddlStatusFilter.selection]) searchText:edtClashSearch.text
     lblSummary.text="Tracking saved for "+clashId
    )
   )
  )
  createDialog AT_ClashManagerRollout style:#(#style_titlebar,#style_sysmenu,#style_resizing)
 ),
 fn clear = (clashes=#(); tracking=#(); selectedIndex=0; lastError=""; lastSimulations=#(); lastSimulationCandidates=#(); lastSimulationResults=#(); lastPairClearances=#(); lastRuleMissingPairs=#(); lastGeometryErrors=#(); lastDisciplineErrors=#(); lastScanRuleRevision=-1; lastScanJurisdiction=""; lastScanRequiredChecks=#(); lastDisciplineMappingRevision=-1; lastDisciplineMetadataRevision=-1; lastDisciplineInventory=#(); lastScanMeshes=#(); visibleClashIndices=#(); true)
)
AT_ClashManager=AT_ClashManagerStruct()
