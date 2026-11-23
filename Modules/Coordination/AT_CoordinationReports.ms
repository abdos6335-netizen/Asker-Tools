/* Asker Tools - Coordination Reports
   Produces deterministic in-memory report rows and optional CSV export.
*/
global AT_CoordinationReports
struct AT_CoordinationReportsStruct (
 version="0.2.0", lastRows=#(), lastErrors=#(),
 fn buildClashRows clashes = (
  local rows=#(#("Clash ID","Element A","Element B","Status","Minimum Distance","Distance Measured","Required Clearance","Shortfall","Severity"))
  for c in clashes do append rows #(c.clashId,c.elementA,c.elementB,c.status,c.minimumDistance,c.minimumDistanceKnown,c.requiredClearance,c.clearanceShortfall,AT_ClashManager.severityFor c)
  lastRows=rows; rows
 ),
 fn buildProposalRows results = (
  local rows=#(#("Proposal ID","Description","Eligible","Score","Rank","Requires Approval","Risk Assessment","Reasons"))
  for r in results do append rows #(r.proposalId,r.description,r.eligible,r.score,r.rank,r.requiresApproval,r.riskAssessment,(r.reasons as string))
  lastRows=rows; rows
 ),
 fn buildClearanceRows clashes = (
  local rows=#(#("Clash ID","Element A","Element B","Minimum Distance","Required Clearance","Shortfall","Discipline A","Discipline B"))
  for c in clashes where c.status=="CLEARANCE_VIOLATION" do append rows #(c.clashId,c.elementA,c.elementB,c.minimumDistance,c.requiredClearance,c.clearanceShortfall,c.disciplineA,c.disciplineB)
  lastRows=rows; rows
 ),
 fn buildDisciplineRows clashes = (
  local rows=#(#("Clash ID","Discipline A","Element A","Discipline B","Element B","Status","Severity"))
  for c in clashes do append rows #(c.clashId,c.disciplineA,c.nameA,c.disciplineB,c.nameB,c.status,AT_ClashManager.severityFor c)
  lastRows=rows; rows
 ),
 fn buildDisciplineErrorRows errors = (
  local rows=#(#("Element ID","Reason"))
  for item in errors do append rows #(item[1],item[2])
  lastRows=rows; rows
 ),
 fn buildGeometryErrorRows errors = (
  local rows=#(#("Element ID","Reason"))
  for item in errors do append rows #(item[1],item[2])
  lastRows=rows; rows
 ),
 fn buildRuleMissingRows missingPairs = (
  local rows=#(#("Element A","Element B","Check Type","Reason"))
  for item in missingPairs do append rows #(item[1],item[2],item[3],item[4])
  lastRows=rows; rows
 ),
 fn buildTrackingRows tracking = (
  local rows=#(#("Clash ID","Owner","Status","Due Date","Note"))
  for item in tracking do append rows #(item.clashId,item.owner,item.status,item.dueDate,item.note)
  lastRows=rows; rows
 ),
 fn buildApprovalRows approvals = (
  local rows=#(#("Proposal ID","Approved","Consumed","Action Type","Element ID","Approver","Approval Date","Reason","Simulation ID"))
  for item in approvals do append rows #(item.proposalId,item.approved,item.consumed,item.actionType,item.elementId,item.approver,item.approvalDate,item.reason,item.simulationId)
  lastRows=rows; rows
 ),
 fn buildRevisionRows history = (
  local rows=#(#("Event","Record"))
  for item in history do append rows #(item[1],item as string)
  lastRows=rows; rows
 ),
 fn buildAuditRows audit = (
  local rows=#(#("Event","Record"))
  for item in audit do append rows #(item[1],item as string)
  lastRows=rows; rows
 ),
 fn buildCriticalRows results = (
  local rows=#(#("Proposal ID","Description","Critical Issue","Reasons"))
  for item in results where (findItem item.reasons "CRITICAL_RULE_VIOLATION")>0 do append rows #(item.proposalId,item.description,"CRITICAL_RULE_VIOLATION",item.reasons as string)
  lastRows=rows; rows
 ),
 fn csvEscape value = (
  if value==undefined then return ""
  local s=value as string
  local escaped=""
  for i=1 to s.count do (
   local ch=substring s i 1
   if ch=="\"" then escaped+="\"\"" else escaped+=ch
  )
  if (findString s ",")!=undefined or (findString s "\"")!=undefined or (findString s "\n")!=undefined or (findString s "\r")!=undefined or (findString s "\r")!=undefined then "\"" + escaped + "\"" else escaped
 ),
 fn exportCSV rows path = (
  if rows.count==0 or path=="" then return false
  local writer=undefined
  try (
   local writerClass=dotNetClass "System.IO.StreamWriter"
   local encodingClass=dotNetClass "System.Text.UTF8Encoding"
   local encoding=encodingClass true
   writer=writerClass path false encoding
   for row in rows do (
    local line=""
    for i=1 to row.count do (
     if i>1 then line+=","
     line+=csvEscape row[i]
    )
    writer.WriteLine line
   )
   writer.Close()
   true
  ) catch (
   if writer!=undefined do try (writer.Close()) catch()
   append lastErrors #(path,getCurrentException())
   false
  )
 ),
  fn clear = (lastRows=#(); lastErrors=#(); true)
)
AT_CoordinationReports=AT_CoordinationReportsStruct()
