/* Asker Tools - Coordination Clash Manager
   Review, filter, select and track detected clash records. Read-only scene operations.
*/
global AT_ClashManager
struct AT_ClashTrackingRecord (clashId="", owner="", status="OPEN", dueDate="", note="", severity="INFORMATION")
struct AT_ClashManagerStruct (
 version="0.1.0", clashes=#(), tracking=#(), selectedIndex=0, lastError="",
 fn severityFor clash = (
  if clash.status=="EXACT_MESH_INTERFERENCE" then "HIGH"
  else if clash.status=="CLEARANCE_VIOLATION" then "MEDIUM"
  else "INFORMATION"
 ),
 fn load clashes = (this.clashes=clashes; selectedIndex=if clashes.count>0 then 1 else 0; true),
 fn trackingFor clashId = (for t in tracking where t.clashId==clashId do return t; local t=AT_ClashTrackingRecord clashId:clashId; append tracking t; t),
 fn setTracking clashId owner:"" status:"OPEN" dueDate:"" note:"" = (
  local t=trackingFor clashId
  t.owner=owner; t.status=status; t.dueDate=dueDate; t.note=note; true
 ),
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
 fn scan requiredClearance:0.0 = (
  AT_DisciplineAdapter.inspect()
  AT_ExactGeometryEngine.inspect()
  local found=AT_ExactGeometryEngine.detectClashes requiredClearance:requiredClearance
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
   listbox lbClashes "Detected clashes" items:#() width:620 height:18
   button btnSelect "Select Clash Elements" width:160 height:28 align:#left
   on btnScan pressed do (
    local found=AT_ClashManager.scan()
    lbClashes.items=for c in found collect (c.status+" | "+c.disciplineA+":"+c.nameA+" <> "+c.disciplineB+":"+c.nameB+" | d="+(formattedPrint c.minimumDistance format:".4f"))
    lblSummary.text=found.count as string+" clashes | exact mesh surface analysis"
   )
   on btnSelect pressed do AT_ClashManager.selectClash lbClashes.selection
  )
  createDialog AT_ClashManagerRollout style:#(#style_titlebar,#style_sysmenu,#style_resizing)
 ),
 fn clear = (clashes=#(); tracking=#(); selectedIndex=0; lastError=""; true)
)
AT_ClashManager=AT_ClashManagerStruct()
