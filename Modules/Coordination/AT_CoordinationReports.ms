/* Asker Tools - Coordination Reports
   Produces deterministic in-memory report rows and optional CSV export.
*/
global AT_CoordinationReports
struct AT_CoordinationReportsStruct (
 version="0.1.0", lastRows=#(), lastErrors=#(),
 fn buildClashRows clashes = (
  local rows=#(#("Clash ID","Element A","Element B","Status","Minimum Distance","Required Clearance","Shortfall","Severity"))
  for c in clashes do append rows #(c.clashId,c.elementA,c.elementB,c.status,c.minimumDistance,c.requiredClearance,c.clearanceShortfall,if c.status=="EXACT_MESH_INTERFERENCE" then "HIGH" else if c.status=="CLEARANCE_VIOLATION" then "MEDIUM" else "INFORMATION")
  lastRows=rows; rows
 ),
 fn buildProposalRows results = (
  local rows=#(#("Proposal ID","Description","Eligible","Score","Rank","Requires Approval","Reasons"))
  for r in results do append rows #(r.proposalId,r.description,r.eligible,r.score,r.rank,r.requiresApproval,(r.reasons as string))
  lastRows=rows; rows
 ),
 fn csvEscape value = (
  local s=value as string
  local escaped=""
  for i=1 to s.count do (
   local ch=substring s i 1
   if ch=="\"" then escaped+="\"\"" else escaped+=ch
  )
  if (findString s ",")!=undefined or (findString s "\"")!=undefined or (findString s "\n")!=undefined then "\"" + escaped + "\"" else escaped
 ),
 fn exportCSV rows path = (
  if rows.count==0 or path=="" then return false
  local stream=undefined
  try (
   stream=createFile path
   for row in rows do (
    local line=""
    for i=1 to row.count do (
     if i>1 then line+=","
     line+=csvEscape row[i]
    )
    format "%\n" line to:stream
   )
   close stream
   true
  ) catch (
   if stream!=undefined do try (close stream) catch()
   append lastErrors #(path,getCurrentException())
   false
  )
 ),
 fn clear = (lastRows=#(); lastErrors=#(); true)
)
AT_CoordinationReports=AT_CoordinationReportsStruct()
