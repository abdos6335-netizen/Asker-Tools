/* Asker Tools - Coordination Review, Approval and Apply Transactions
   Applies only explicitly approved, successfully simulated transforms.
*/
global AT_CoordinationGovernance
struct AT_CoordinationApproval (
 proposalId="", approved=false, consumed=false, approver="", approvalDate="", reason="",
 simulationId="", elementId="", ruleRevision=0, actionType="TRANSLATE", sourceTransform=undefined, sourcePivot=[0,0,0],
 offset=[0,0,0], rotationAxis=[0,0,1], angleDegrees=0.0, pivot=[0,0,0], candidate=undefined
)
struct AT_CoordinationTransaction (
 transactionId="", proposalId="", elementId="", actionType="TRANSLATE", nodeRef=undefined,
 beforeTransform=undefined, afterTransform=undefined, beforeObjectTransform=undefined, afterObjectTransform=undefined, beforePivot=[0,0,0], afterPivot=[0,0,0], state="PREPARED",
 appliedAt="", rollbackReason=""
)
struct AT_CoordinationGovernanceStruct (
 version="0.2.0", approvals=#(), transactions=#(), auditLog=#(),
 fn findApproval proposalId = (for a in approvals where a.proposalId==proposalId do return a; undefined),
 fn restoreTransactionSnapshot tx = (
  if tx==undefined or not isValidNode tx.nodeRef then return false
  try (
   tx.nodeRef.transform=tx.beforeTransform
   tx.nodeRef.pivot=tx.beforePivot
   (tx.nodeRef.transform==tx.beforeTransform and tx.nodeRef.objectTransform==tx.beforeObjectTransform and tx.nodeRef.pivot==tx.beforePivot)
  ) catch (false)
 ),
 fn sameStringSet a b = (
  if classOf a!=Array or classOf b!=Array or a.count!=b.count then return false
  local uniqueA=#(); local uniqueB=#()
  for value in a do appendIfUnique uniqueA value
  for value in b do appendIfUnique uniqueB value
  if uniqueA.count!=a.count or uniqueB.count!=b.count then return false
  for value in a where (findItem b value)==0 do return false
  true
 ),
 fn candidateMatchesSimulation candidate simulation = (
  if classOf candidate!=AT_CoordinationActionCandidate or classOf simulation!=AT_CoordinationSimulationResult then return false
  if not candidate.simulationValidated or not simulation.validated or simulation.status!="EXACT_GEOMETRY_SIMULATION_PASSED" then return false
  if candidate.actionId!=simulation.simulationId or candidate.actionType!=simulation.actionType then return false
  if candidate.offset!=simulation.offset or candidate.rotationAxis!=simulation.rotationAxis or candidate.angleDegrees!=simulation.angleDegrees or candidate.pivot!=simulation.pivot then return false
  if not sameStringSet candidate.targetClashIds simulation.baselineClashIds then return false
  if not sameStringSet candidate.resolvedClashIds simulation.resolvedClashIds then return false
  if not sameStringSet candidate.introducedClashIds simulation.introducedClashIds then return false
  if not sameStringSet candidate.criticalViolationIds simulation.criticalViolationIds then return false
  if not sameStringSet candidate.missingRuleIds simulation.ruleMissingIds then return false
  if not sameStringSet candidate.affectedElementIds simulation.affectedElementIds then return false
  true
 ),
 fn approve candidate simulation approver reason approvalDate = (
  if candidate==undefined or simulation==undefined or approver=="" or reason=="" or approvalDate=="" then return false
  if not candidate.requiresEngineeringApproval or not candidate.simulationValidated or not simulation.validated or simulation.status!="EXACT_GEOMETRY_SIMULATION_PASSED" then return false
  if not AT_ClashManager.validateCurrentScene jurisdiction:AT_ClashManager.lastScanJurisdiction then return false
  local proposal=AT_SolutionEngine.buildProposal candidate
  if proposal==undefined then return false
  local evaluation=AT_SolutionEngine.evaluateProposal proposal
  if not evaluation.eligible then return false
  if simulation.ruleRevision!=AT_RuleEngine.registryRevision then return false
  if not candidateMatchesSimulation candidate simulation then (append auditLog #("APPROVAL_BLOCKED_SIMULATION_IDENTITY_MISMATCH",candidate.actionId,simulation.simulationId); return false)
  if candidate.affectedElementIds.count!=1 or candidate.affectedElementIds[1]!=simulation.movingElementId then return false
  local approvedNode=getNodeByHandle (simulation.movingElementId as integer)
  if not isValidNode approvedNode or approvedNode.objectTransform!=simulation.sourceTransform or approvedNode.pivot!=simulation.sourcePivot then return false
  if candidate.offset!=simulation.offset or candidate.rotationAxis!=simulation.rotationAxis or candidate.angleDegrees!=simulation.angleDegrees or candidate.pivot!=simulation.pivot then return false
  if simulation.introducedClashIds.count>0 or simulation.ruleMissingIds.count>0 or simulation.criticalViolationIds.count>0 or simulation.sourceTransform==undefined then return false
  if simulation.actionType=="ROTATE" and simulation.pivot!=simulation.sourcePivot then return false
  local a=AT_CoordinationApproval proposalId:candidate.actionId approved:true approver:approver approvalDate:approvalDate reason:reason simulationId:simulation.simulationId elementId:simulation.movingElementId ruleRevision:simulation.ruleRevision actionType:simulation.actionType sourceTransform:simulation.sourceTransform sourcePivot:simulation.sourcePivot offset:simulation.offset rotationAxis:simulation.rotationAxis angleDegrees:simulation.angleDegrees pivot:simulation.pivot candidate:candidate
  local old=findApproval candidate.actionId
  if old!=undefined then (local idx=findItem approvals old; deleteItem approvals idx)
  append approvals a
  append auditLog #("APPROVED",candidate.actionId,approver,approvalDate,reason,simulation.actionType)
  true
 ),
 fn applyAction proposalId nodeRef transactionId = (
  local a=findApproval proposalId
  if a==undefined or not a.approved or a.consumed or not isValidNode nodeRef or transactionId=="" then return undefined
  if not AT_ClashManager.validateCurrentScene jurisdiction:AT_ClashManager.lastScanJurisdiction then (append auditLog #("APPLY_BLOCKED_STALE_SCENE",proposalId); return undefined)
  local expectedId=try ((getHandleByAnim nodeRef) as string) catch ("")
  if expectedId!=a.elementId then return undefined
  if a.ruleRevision!=AT_RuleEngine.registryRevision then (append auditLog #("APPLY_BLOCKED_RULES_CHANGED",proposalId); return undefined)
  if nodeRef.objectTransform!=a.sourceTransform or nodeRef.pivot!=a.sourcePivot then (append auditLog #("APPLY_BLOCKED_STALE_SCENE",proposalId,expectedId); return undefined)
  for existing in transactions where existing.transactionId==transactionId do return undefined
  a.consumed=true
  append auditLog #("APPROVAL_CONSUMED",proposalId,transactionId)
  local tx=AT_CoordinationTransaction transactionId:transactionId proposalId:proposalId elementId:expectedId actionType:a.actionType nodeRef:nodeRef beforeTransform:nodeRef.transform beforeObjectTransform:nodeRef.objectTransform beforePivot:nodeRef.pivot state:"PREPARED"
  append transactions tx
  try (
   undo ("Asker Tools Coordination Apply "+proposalId) on (
    if a.actionType=="TRANSLATE" then (in coordsys world (move nodeRef a.offset))
    else if a.actionType=="ROTATE" then (in coordsys world (rotate nodeRef (angleAxis a.angleDegrees a.rotationAxis)))
    else throw "UNSUPPORTED_APPROVED_ACTION"
   )
   tx.afterTransform=nodeRef.transform; tx.afterObjectTransform=nodeRef.objectTransform; tx.afterPivot=nodeRef.pivot
   tx.state="APPLIED"
   append auditLog #("APPLIED",proposalId,expectedId,transactionId,a.actionType)
   tx
  ) catch (
   local failure=getCurrentException()
   local restored=restoreTransactionSnapshot tx
   tx.state=if restored then "FAILED_ROLLED_BACK" else "APPLY_FAILED_RESTORE_FAILED"
   append auditLog #("APPLY_FAILED",proposalId,expectedId,failure,tx.state)
   tx
  )
 ),
 fn applyTranslation proposalId nodeRef offset transactionId = (
  local a=findApproval proposalId
  if a==undefined or a.actionType!="TRANSLATE" or a.offset!=offset then return undefined
  applyAction proposalId nodeRef transactionId
 ),
 fn applyRotation proposalId nodeRef axis angleDegrees pivot transactionId = (
  local a=findApproval proposalId
  if a==undefined or a.actionType!="ROTATE" or a.rotationAxis!=axis or a.angleDegrees!=angleDegrees or a.pivot!=pivot then return undefined
  applyAction proposalId nodeRef transactionId
 ),
 fn rollback transactionId reason = (
  local tx=undefined
  for t in transactions where t.transactionId==transactionId do tx=t
  if tx==undefined or tx.state!="APPLIED" or reason=="" or not isValidNode tx.nodeRef then return false
  if tx.nodeRef.transform!=tx.afterTransform or tx.nodeRef.objectTransform!=tx.afterObjectTransform or tx.nodeRef.pivot!=tx.afterPivot then (tx.state="ROLLBACK_BLOCKED_SCENE_CHANGED"; append auditLog #("ROLLBACK_BLOCKED_SCENE_CHANGED",transactionId); return false)
  try (
   undo ("Asker Tools Coordination Rollback "+transactionId) on (tx.nodeRef.transform=tx.beforeTransform; tx.nodeRef.pivot=tx.beforePivot)
   tx.state="ROLLED_BACK"; tx.rollbackReason=reason
   append auditLog #("ROLLED_BACK",transactionId,reason)
   true
  ) catch (
   tx.state="ROLLBACK_FAILED"
   append auditLog #("ROLLBACK_FAILED",transactionId,reason,getCurrentException())
   false
  )
 ),
 fn clearAudit = (auditLog=#(); true)
)
AT_CoordinationGovernance=AT_CoordinationGovernanceStruct()
