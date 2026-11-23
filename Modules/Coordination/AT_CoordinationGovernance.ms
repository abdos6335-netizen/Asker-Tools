/* Asker Tools - Coordination Review, Approval and Apply Transactions
   Applies only an explicitly approved, exactly simulated translation candidate.
*/
global AT_CoordinationGovernance
struct AT_CoordinationApproval (
 proposalId="", approved=false, approver="", approvalDate="", reason="",
 simulationId="", sourceTransform=undefined, offset=[0,0,0], candidate=undefined
)
struct AT_CoordinationTransaction (
 transactionId="", proposalId="", elementId="", nodeRef=undefined,
 beforeTransform=undefined, afterTransform=undefined,
 state="PREPARED", appliedAt="", rollbackReason=""
)
struct AT_CoordinationGovernanceStruct (
 version="0.1.0", approvals=#(), transactions=#(), auditLog=#(),
 fn findApproval proposalId = (for a in approvals where a.proposalId==proposalId do return a; undefined),
 fn approve candidate simulation approver reason approvalDate = (
  if candidate==undefined or simulation==undefined or approver=="" or reason=="" or approvalDate=="" then return false
  if not candidate.simulationValidated or not simulation.validated or simulation.status!="EXACT_GEOMETRY_SIMULATION_PASSED" then return false
  if candidate.actionId!=simulation.simulationId or candidate.affectedElementIds.count!=1 or candidate.affectedElementIds[1]!=simulation.movingElementId then return false
  if simulation.introducedClashIds.count>0 or simulation.ruleMissingIds.count>0 or simulation.criticalViolationIds.count>0 or simulation.sourceTransform==undefined then return false
  local a=AT_CoordinationApproval proposalId:candidate.actionId approved:true approver:approver approvalDate:approvalDate reason:reason simulationId:simulation.simulationId sourceTransform:simulation.sourceTransform offset:simulation.offset candidate:candidate
  local old=findApproval candidate.actionId
  if old!=undefined then (local idx=findItem approvals old; deleteItem approvals idx)
  append approvals a
  append auditLog #("APPROVED",candidate.actionId,approver,approvalDate,reason)
  true
 ),
 fn applyTranslation proposalId nodeRef offset transactionId = (
  local a=findApproval proposalId
  if a==undefined or not a.approved or not isValidNode nodeRef or transactionId=="" then return undefined
  local expectedId=try ((getHandleByAnim nodeRef) as string) catch ("")
  if (findItem a.candidate.affectedElementIds expectedId)==0 or expectedId!=a.candidate.affectedElementIds[1] then return undefined
  if offset!=a.offset then return undefined
  if nodeRef.transform!=a.sourceTransform then (append auditLog #("APPLY_BLOCKED_STALE_SCENE",proposalId,expectedId); return undefined)
  for existing in transactions where existing.transactionId==transactionId do return undefined
  local tx=AT_CoordinationTransaction transactionId:transactionId proposalId:proposalId elementId:expectedId nodeRef:nodeRef beforeTransform:nodeRef.transform state:"PREPARED"
  append transactions tx
  try (
   undo ("Asker Tools Coordination Apply "+proposalId) on (
    move nodeRef offset
   )
   tx.afterTransform=nodeRef.transform
   tx.state="APPLIED"
   append auditLog #("APPLIED",proposalId,expectedId,transactionId)
   tx
  ) catch (
   try (nodeRef.transform=tx.beforeTransform) catch()
   tx.state="FAILED_ROLLED_BACK"
   append auditLog #("APPLY_FAILED",proposalId,expectedId,getCurrentException())
   tx
  )
 ),
 fn rollback transactionId reason = (
  local tx=undefined
  for t in transactions where t.transactionId==transactionId do tx=t
  if tx==undefined or tx.state!="APPLIED" or reason=="" or not isValidNode tx.nodeRef then return false
  if tx.nodeRef.transform!=tx.afterTransform then (tx.state="ROLLBACK_BLOCKED_SCENE_CHANGED"; append auditLog #("ROLLBACK_BLOCKED_SCENE_CHANGED",transactionId); return false)
  try (
   undo ("Asker Tools Coordination Rollback "+transactionId) on (tx.nodeRef.transform=tx.beforeTransform)
   tx.state="ROLLED_BACK"; tx.rollbackReason=reason
   append auditLog #("ROLLED_BACK",transactionId,reason)
   true
  ) catch (append auditLog #("ROLLBACK_FAILED",transactionId,getCurrentException()); false)
 ),
 fn clearAudit = (auditLog=#(); true)
)
AT_CoordinationGovernance=AT_CoordinationGovernanceStruct()
