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
 fn clear = (clashes=#(); tracking=#(); selectedIndex=0; lastError=""; true)
)
AT_ClashManager=AT_ClashManagerStruct()
