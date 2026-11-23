/* Asker Tools - Coordination Clash Manager
   Review, filter, select and track detected clash records. Read-only scene operations.
*/
global AT_ClashManager
struct AT_ClashTrackingRecord (clashId="", owner="", status="OPEN", dueDate="", note="", severity="INFORMATION")
struct AT_ClashManagerStruct (
 version="0.1.0", clashes=#(), tracking=#(), selectedIndex=0, lastError="",
 fn severityFor clash = (
  if clash.status=="EXACT_MESH_INTERFERENCE" or clash.status=="SOLID_CONTAINMENT_INTERFERENCE" then "HIGH"
  else if clash.status=="CLEARANCE_VIOLATION" then "MEDIUM"
  else if clash.status=="CONTAINMENT_UNVERIFIED" then "INFORMATION"
  else "INFORMATION"
 ),
 fn clashLabel clash = (
  local distanceText=if clash.minimumDistanceKnown then (formattedPrint clash.minimumDistance format:".4f") else "not measured"
  clash.status+" | "+clash.disciplineA+":"+clash.nameA+" <> "+clash.disciplineB+":"+clash.nameB+" | d="+distanceText
 ),
 fn load clashes = (this.clashes=clashes; selectedIndex=if clashes.count>0 then 1 else 0; true),
 fn trackingFor clashId = (for t in tracking where t.clashId==clashId do return t; local t=AT_ClashTrackingRecord clashId:clashId; append tracking t; t),
 fn setTracking clashId owner:"" status:"OPEN" dueDate:"" note:"" = (
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
  if index<1 or index>clashes.count or AT_ExactGeometryEngine.lastMeshes.count==0 then return #()
  AT_CoordinationSolutionGenerator.generateAllAlternatives AT_ExactGeometryEngine.lastMeshes #(clashes[index]) clearance:clearance angles:angles
 ),
 fn rankAlternatives = (
  local candidates=AT_CoordinationSolutionGenerator.toProposalCandidates()
  AT_SolutionEngine.generateAndRank candidates
 ),
 fn scan requiredClearance:0.0 = (
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
  rollout AT_ClashManagerRollout "Asker Tools | Clash Manager" width:650 height:430 (
   button btnScan "Detect Exact Mesh Clashes" width:190 height:28 align:#left
   label lblSummary "Ready" align:#left
   label lblCounts "HIGH 0 | MEDIUM 0 | LOW 0 | INFO 0" align:#left
   listbox lbClashes "Detected clashes" items:#() width:620 height:18
   button btnSelect "Select Clash Elements" width:160 height:28 align:#left
   button btnGenerate "Generate Solution Alternatives" width:220 height:28 align:#left
   listbox lbSolutions "Generated alternatives (simulation required)" items:#() width:620 height:8
   group "Assignment and status" (
    editText edtOwner "Owner" text:"" width:300
    dropdownList ddlStatus "Status" items:#("OPEN","IN_PROGRESS","UNDER_REVIEW","RESOLVED","WONT_FIX") width:300
    editText edtDue "Due date" text:"" width:300
    editText edtNote "Note" text:"" width:580
    button btnSave "Save clash tracking" width:180 height:26
   )
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
 fn clear = (clashes=#(); tracking=#(); selectedIndex=0; lastError=""; true)
)
AT_ClashManager=AT_ClashManagerStruct()
