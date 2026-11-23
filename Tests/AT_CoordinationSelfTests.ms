/* Asker Tools - Coordination Engine In-Host Self Tests
   Creates temporary test geometry, runs source-level engines, and deletes only its own nodes.
   Run manually inside 3ds Max after all Coordination modules have loaded.
*/
global AT_CoordinationSelfTests
struct AT_CoordinationSelfTestsStruct (
 version="0.1.0", lastResults=#(), lastErrors=#(),
 fn addResult results testName passed actual expected = (
  append results #(testName,passed,actual,expected)
 ),
 fn run = (
  local results=#()
  local testNodes=#()
  local savedSelection=selection as array
  local savedMeshes=AT_ExactGeometryEngine.lastMeshes
  local savedGeometryResults=AT_ExactGeometryEngine.lastResults
  local savedGeometryErrors=AT_ExactGeometryEngine.lastErrors
  local savedRules=AT_RuleEngine.rules
  local savedRuleRevision=AT_RuleEngine.registryRevision
  local savedRequiredCheckTypes=AT_RuleEngine.requiredCheckTypes
  local savedRuleEvaluations=AT_RuleEngine.lastEvaluations
  local savedRuleErrors=AT_RuleEngine.lastErrors
  local savedMoveCandidates=AT_CoordinationSolutionGenerator.lastCandidates
  local savedRotationCandidates=AT_CoordinationSolutionGenerator.lastRotationCandidates
  local savedGeneratorErrors=AT_CoordinationSolutionGenerator.lastErrors
  local savedSolutionResults=AT_SolutionEngine.lastResults
  local savedSolutionProposals=AT_SolutionEngine.lastProposals
  local savedRejectedCandidates=AT_SolutionEngine.lastRejectedCandidates
  local savedSolutionWeights=AT_SolutionEngine.weights
  local savedDisciplineInventory=AT_DisciplineAdapter.lastInventory
  local savedDisciplineUnclassified=AT_DisciplineAdapter.lastUnclassified
  local savedDisciplineErrors=AT_DisciplineAdapter.lastErrors
  local savedEnvelopeOverrides=AT_DisciplineAdapter.envelopeOverrides
  local savedDisciplineMetadataRevision=AT_DisciplineAdapter.metadataRevision
  local savedIntegrationRegistry=AT_CoordinationIntegrations.registry
  local savedIntegrationHistory=AT_CoordinationIntegrations.syncHistory
  local savedIntegrationErrors=AT_CoordinationIntegrations.lastErrors
  local savedPendingIntegrationTokens=AT_CoordinationProjectStore.pendingIntegrationTokens
  lastErrors=#()
  try (
   local overlapA=box length:10 width:10 height:10 pos:[0,0,0]
   append testNodes overlapA; overlapA.name=uniqueName "AT_QA_Overlap_A_"; convertToMesh overlapA
   local overlapB=box length:10 width:10 height:10 pos:[5,0,0]
   append testNodes overlapB; overlapB.name=uniqueName "AT_QA_Overlap_B_"; convertToMesh overlapB
   local records=AT_ExactGeometryEngine.inspect #(overlapA,overlapB)
   local found=AT_ExactGeometryEngine.detectClashes records:records
   addResult results "OVERLAPPING_BOXES" (found.count==1 and found[1].status=="EXACT_MESH_INTERFERENCE") (if found.count>0 then found[1].status else "NO_CLASH") "EXACT_MESH_INTERFERENCE"
   local restoreSnapshotTx=AT_CoordinationTransaction nodeRef:overlapA beforeTransform:overlapA.transform beforeObjectTransform:overlapA.objectTransform beforePivot:overlapA.pivot
   move overlapA [17,3,0]
   local snapshotRestored=AT_CoordinationGovernance.restoreTransactionSnapshot restoreSnapshotTx
   addResult results "GOVERNANCE_RESTORES_FAILED_ACTION_SNAPSHOT" (snapshotRestored and overlapA.transform==restoreSnapshotTx.beforeTransform and overlapA.objectTransform==restoreSnapshotTx.beforeObjectTransform and overlapA.pivot==restoreSnapshotTx.beforePivot) snapshotRestored true
   local translationCandidates=AT_CoordinationSolutionGenerator.generateTranslations records found
   addResult results "TRANSLATION_CANDIDATE_COUNT" (translationCandidates.count==12) translationCandidates.count 12
   local rotationCandidates=AT_CoordinationSolutionGenerator.generateRotations records found
   addResult results "ROTATION_CANDIDATE_COUNT" (rotationCandidates.count==24) rotationCandidates.count 24
   local rotationProposals=AT_CoordinationSolutionGenerator.toProposalCandidates()
   addResult results "ROTATION_CANDIDATE_METADATA" (rotationProposals.count==24 and rotationProposals[1].actionType=="ROTATE") (if rotationProposals.count>0 then rotationProposals[1].actionType else "NONE") "ROTATE"

   local rotationNode=box length:10 width:10 height:10 pos:[0,70,0]
   append testNodes rotationNode; rotationNode.name=uniqueName "AT_QA_Rotation_Snapshot_"; convertToMesh rotationNode
   local rotationRecords=AT_ExactGeometryEngine.inspect #(rotationNode)
   local originalTransform=rotationNode.transform
   local rotatedSnapshot=AT_CoordinationSimulation.cloneRotatedMesh rotationRecords[1] [0,0,1] 45.0 rotationRecords[1].sourcePivot
   local originalWidth=rotationRecords[1].maximum.x-rotationRecords[1].minimum.x
   local rotatedWidth=rotatedSnapshot.maximum.x-rotatedSnapshot.minimum.x
   addResult results "ROTATION_SNAPSHOT_NON_DESTRUCTIVE" (rotatedWidth>originalWidth*1.3 and rotationNode.transform==originalTransform) rotatedWidth originalWidth
   local beforeMoveRecords=AT_ExactGeometryEngine.inspect #(rotationNode)
   in coordsys world move rotationNode [5,0,0]
   local afterMoveRecords=AT_ExactGeometryEngine.inspect #(rotationNode)
   local staleDetected=not AT_ClashManager.meshInventoryMatches beforeMoveRecords afterMoveRecords
   addResult results "STALE_GEOMETRY_SNAPSHOT_DETECTED" staleDetected staleDetected true
   rotationNode.transform=originalTransform
   local gapA=box length:10 width:10 height:10 pos:[0,30,0]
   append testNodes gapA; gapA.name=uniqueName "AT_QA_Clearance_A_"; convertToMesh gapA
   local gapB=box length:10 width:10 height:10 pos:[12,30,0]
   append testNodes gapB; gapB.name=uniqueName "AT_QA_Clearance_B_"; convertToMesh gapB
   records=AT_ExactGeometryEngine.inspect #(gapA,gapB)
   found=AT_ExactGeometryEngine.detectClashes records:records requiredClearance:3.0
   addResult results "CLEARANCE_VIOLATION" (found.count==1 and found[1].status=="CLEARANCE_VIOLATION" and found[1].minimumDistanceKnown) (if found.count>0 then found[1].status else "NO_CLASH") "CLEARANCE_VIOLATION"
   records[1].serviceClearance=3.0
   found=AT_ExactGeometryEngine.detectClashesWithClearances records defaultClearance:0.0
   addResult results "SERVICE_CLEARANCE_ENFORCED" (found.count==1 and found[1].status=="CLEARANCE_VIOLATION" and found[1].requiredClearance==3.0) (if found.count>0 then found[1].requiredClearance else -1) 3.0
   records[1].serviceClearance=undefined
   records[2].installationClearance=3.0
   found=AT_ExactGeometryEngine.detectClashesWithClearances records defaultClearance:0.0
   addResult results "INSTALLATION_CLEARANCE_ENFORCED" (found.count==1 and found[1].status=="CLEARANCE_VIOLATION" and found[1].requiredClearance==3.0) (if found.count>0 then found[1].requiredClearance else -1) 3.0
   records[2].installationClearance=undefined
   local criticalOverride=AT_ExactPairClearanceRecord elementA:records[1].elementId elementB:records[2].elementId requiredClearance:3.0 severity:"CRITICAL" ruleIds:#("QA_CRITICAL_CLEARANCE")
   found=AT_ExactGeometryEngine.detectClashesWithClearances records defaultClearance:0.0 pairOverrides:#(criticalOverride)
   addResult results "PAIR_RULE_SEVERITY_PROPAGATION" (found.count==1 and found[1].ruleSeverity=="CRITICAL" and (AT_ClashManager.severityFor found[1])=="CRITICAL") (if found.count>0 then found[1].ruleSeverity else "NO_CLASH") "CRITICAL"

   local outer=box length:20 width:20 height:20 pos:[50,0,0]
   append testNodes outer; outer.name=uniqueName "AT_QA_Containment_Outer_"; convertToMesh outer
   local inner=box length:2 width:2 height:2 pos:[50,0,0]
   append testNodes inner; inner.name=uniqueName "AT_QA_Containment_Inner_"; convertToMesh inner
   records=AT_ExactGeometryEngine.inspect #(outer,inner)
   found=AT_ExactGeometryEngine.detectClashes records:records
   addResult results "CLOSED_SOLID_CONTAINMENT" (found.count==1 and found[1].status=="SOLID_CONTAINMENT_INTERFERENCE") (if found.count>0 then found[1].status else "NO_CLASH") "SOLID_CONTAINMENT_INTERFERENCE"

   local openOuter=box length:20 width:20 height:20 pos:[80,0,0]
   append testNodes openOuter; openOuter.name=uniqueName "AT_QA_Open_Outer_"; convertToMesh openOuter
   local openInner=plane length:2 width:2 pos:[80,0,0]
   append testNodes openInner; openInner.name=uniqueName "AT_QA_Open_Inner_"; convertToMesh openInner
   records=AT_ExactGeometryEngine.inspect #(openOuter,openInner)
   found=AT_ExactGeometryEngine.detectClashes records:records
   addResult results "OPEN_MESH_CONTAINMENT_UNVERIFIED" (found.count==1 and found[1].status=="CONTAINMENT_UNVERIFIED") (if found.count>0 then found[1].status else "NO_CLASH") "CONTAINMENT_UNVERIFIED"

   local farA=box length:10 width:10 height:10 pos:[110,0,0]
   append testNodes farA; farA.name=uniqueName "AT_QA_Separated_A_"; convertToMesh farA
   local farB=box length:10 width:10 height:10 pos:[130,0,0]
   append testNodes farB; farB.name=uniqueName "AT_QA_Separated_B_"; convertToMesh farB
   records=AT_ExactGeometryEngine.inspect #(farA,farB)
   found=AT_ExactGeometryEngine.detectClashes records:records
   addResult results "SEPARATED_BOXES" (found.count==0) found.count 0
   local invalidToleranceResults=AT_ExactGeometryEngine.detectClashes records:records epsilon:-1.0
   addResult results "NEGATIVE_GEOMETRY_TOLERANCE_REJECTED" (invalidToleranceResults.count==0 and AT_ExactGeometryEngine.lastErrors.count>0 and AT_ExactGeometryEngine.lastErrors[1][2]=="INVALID_GEOMETRY_TOLERANCE") AT_ExactGeometryEngine.lastErrors "INVALID_GEOMETRY_TOLERANCE"
   local connectedFaceEdges=#(#("e12",2,1,2,#(1,2)),#("e23",2,2,3,#(2,3)),#("e31",2,3,1,#(3,1)))
   local disconnectedFaceEdges=#(#("e12",2,1,2,#(1,2)),#("e34",2,3,4,#(3,4)))
   addResult results "CLOSED_SHELL_FACE_CONNECTIVITY" (AT_ExactGeometryEngine.faceConnectivity connectedFaceEdges 3) true true
   addResult results "DISCONNECTED_SHELLS_NOT_SINGLE_SOLID" (not AT_ExactGeometryEngine.faceConnectivity disconnectedFaceEdges 4) false false
   local sharedEdgeTriA=AT_ExactGeometryEngine.makeTriangle [0,0,0] [1,0,0] [1,1,0] 1
   local sharedEdgeTriB=AT_ExactGeometryEngine.makeTriangle [0,0,0] [1,1,0] [0,1,0] 2
   local sharedEdgeHitA=AT_ExactGeometryEngine.rayHitDistance [0.5,0.5,-1] [0,0,1] sharedEdgeTriA
   local sharedEdgeHitB=AT_ExactGeometryEngine.rayHitDistance [0.5,0.5,-1] [0,0,1] sharedEdgeTriB
   addResult results "SHARED_EDGE_RAY_HIT_INCLUSIVE" (sharedEdgeHitA!=undefined and sharedEdgeHitB!=undefined and abs(sharedEdgeHitA-sharedEdgeHitB)<=1.0e-8) #(sharedEdgeHitA,sharedEdgeHitB) "same positive hit distance"
   local vertexHitTriA=AT_ExactGeometryEngine.makeTriangle [0,0,0] [1,0,0] [1,1,0] 3
   local vertexHitTriB=AT_ExactGeometryEngine.makeTriangle [0,0,0] [1,1,0] [0,1,0] 4
   local sharedVertexHitA=AT_ExactGeometryEngine.rayHitDistance [0,0,-1] [0,0,1] vertexHitTriA
   local sharedVertexHitB=AT_ExactGeometryEngine.rayHitDistance [0,0,-1] [0,0,1] vertexHitTriB
   addResult results "SHARED_VERTEX_RAY_HIT_INCLUSIVE" (sharedVertexHitA!=undefined and sharedVertexHitB!=undefined and abs(sharedVertexHitA-sharedVertexHitB)<=1.0e-8) #(sharedVertexHitA,sharedVertexHitB) "same positive hit distance"
   local satBase=AT_ExactGeometryEngine.makeTriangle [0,0,0] [2,0,0] [0,2,0] 10
   local coplanarOverlap=AT_ExactGeometryEngine.makeTriangle [0.5,0.5,0] [2,0.5,0] [0.5,2,0] 11
   local coplanarGap=AT_ExactGeometryEngine.makeTriangle [3,0,0] [4,0,0] [3,1,0] 12
   local vertexTouch=AT_ExactGeometryEngine.makeTriangle [2,0,0] [3,0,0] [2,-1,0] 13
   local edgeTouch=AT_ExactGeometryEngine.makeTriangle [0,0,0] [2,0,0] [1,-1,0] 14
   addResult results "SAT_COPLANAR_OVERLAP" (AT_ExactGeometryEngine.trianglesIntersect satBase coplanarOverlap) true true
   addResult results "SAT_COPLANAR_SEPARATION" (not AT_ExactGeometryEngine.trianglesIntersect satBase coplanarGap) false false
   addResult results "SAT_VERTEX_TOUCH" (AT_ExactGeometryEngine.trianglesIntersect satBase vertexTouch) true true
   addResult results "SAT_EDGE_TOUCH" (AT_ExactGeometryEngine.trianglesIntersect satBase edgeTouch) true true
   local nearParallel=AT_ExactGeometryEngine.makeTriangle [0,0,0.0001] [2,0,0.0001] [0,2,0.0001001] 15
   addResult results "SAT_NEAR_PARALLEL_SEPARATED" (not AT_ExactGeometryEngine.trianglesIntersect satBase nearParallel epsilon:1.0e-7) false false
   local tinyA=AT_ExactGeometryEngine.makeTriangle [0,0,0] [0.000001,0,0] [0,0.000001,0] 16
   local tinyOverlap=AT_ExactGeometryEngine.makeTriangle [0.0000001,0.0000001,0] [0.0000008,0.0000001,0] [0.0000001,0.0000008,0] 17
   addResult results "SAT_TINY_TRIANGLE_OVERLAP" (AT_ExactGeometryEngine.trianglesIntersect tinyA tinyOverlap epsilon:1.0e-12) true true
   local longThinA=AT_ExactGeometryEngine.makeTriangle [0,0,0] [1000000,0,0] [0,0.001,0] 18
   local longThinB=AT_ExactGeometryEngine.makeTriangle [100,0.0002,0] [200,0.0002,0] [100,0.0008,0] 19
   addResult results "SAT_HIGH_ASPECT_RATIO_OVERLAP" (AT_ExactGeometryEngine.trianglesIntersect longThinA longThinB epsilon:1.0e-9) true true
   local distanceBase=AT_ExactGeometryEngine.makeTriangle [0,0,0] [1,0,0] [0,1,0] 20
   local distanceParallel=AT_ExactGeometryEngine.makeTriangle [0,0,2] [1,0,2] [0,1,2] 21
   local distanceCoplanarGap=AT_ExactGeometryEngine.makeTriangle [2,0,0] [3,0,0] [2,1,0] 22
   local parallelTriangleDistance=AT_ExactGeometryEngine.triangleDistanceSquared distanceBase distanceParallel
   local coplanarTriangleDistance=AT_ExactGeometryEngine.triangleDistanceSquared distanceBase distanceCoplanarGap
   addResult results "TRIANGLE_DISTANCE_PARALLEL_SURFACES" (abs(parallelTriangleDistance-4.0)<=1.0e-8) parallelTriangleDistance 4.0
   addResult results "TRIANGLE_DISTANCE_COPLANAR_GAP" (abs(coplanarTriangleDistance-1.0)<=1.0e-8) coplanarTriangleDistance 1.0
   local parallelOverlap=AT_ExactGeometryEngine.segmentDistanceSquared [0,0,0] [10,0,0] [5,0,0] [15,0,0]
   local parallelGap=AT_ExactGeometryEngine.segmentDistanceSquared [0,0,0] [10,0,0] [5,2,0] [15,2,0]
   addResult results "PARALLEL_OVERLAPPING_SEGMENTS_ZERO_DISTANCE" (parallelOverlap<=1.0e-8) parallelOverlap 0.0
   addResult results "PARALLEL_SEPARATED_SEGMENTS_DISTANCE" (abs(parallelGap-4.0)<=1.0e-8) parallelGap 4.0
   local pointOnSegment=AT_ExactGeometryEngine.pointSegmentDistanceSquared [1,1,0] [0,0,0] [2,0,0]
   local pointOnDegenerate=AT_ExactGeometryEngine.pointSegmentDistanceSquared [1,0,0] [0,0,0] [0,0,0]
   local skewDistance=AT_ExactGeometryEngine.segmentDistanceSquared [0,0,0] [1,0,0] [0.5,-1,1] [0.5,1,1]
   addResult results "POINT_TO_SEGMENT_PERPENDICULAR_DISTANCE" (abs(pointOnSegment-1.0)<=1.0e-8) pointOnSegment 1.0
   addResult results "POINT_TO_DEGENERATE_SEGMENT_DISTANCE" (abs(pointOnDegenerate-1.0)<=1.0e-8) pointOnDegenerate 1.0
   addResult results "SKEW_SEGMENT_INTERIOR_DISTANCE" (abs(skewDistance-1.0)<=1.0e-8) skewDistance 1.0
   local tinyPointDistance=AT_ExactGeometryEngine.pointSegmentDistanceSquared [0.000001,0.000001,0] [0,0,0] [0.000002,0,0]
   local tinyParallelOverlap=AT_ExactGeometryEngine.segmentDistanceSquared [0,0,0] [0.000002,0,0] [0.000001,0,0] [0.000003,0,0]
   addResult results "TINY_SEGMENT_POINT_DISTANCE_SCALE" (abs(tinyPointDistance-1.0e-12)<=1.0e-18) tinyPointDistance 1.0e-12
   addResult results "TINY_PARALLEL_SEGMENT_OVERLAP_ZERO" (tinyParallelOverlap<=1.0e-24) tinyParallelOverlap 0.0

   AT_CoordinationIntegrations.registry=#()
   AT_CoordinationIntegrations.syncHistory=#()
   local integrationV1=AT_CoordinationIntegrations.register "QA_REVISION_PROVIDER" "r1" "QA_PROVIDER" capabilities:#(#"read")
   local integrationRecord=AT_CoordinationIntegrations.get "AT_INT_QA_REVISION_PROVIDER"
   if integrationRecord!=undefined do integrationRecord.lastSyncToken="token-r1"
   local integrationV2=AT_CoordinationIntegrations.register "QA_REVISION_PROVIDER" "r2" "QA_PROVIDER" capabilities:#(#"read")
   local revisedIntegration=AT_CoordinationIntegrations.get "AT_INT_QA_REVISION_PROVIDER"
   addResult results "INTEGRATION_REVISION_INVALIDATES_OLD_TOKEN" (integrationV1 and integrationV2 and revisedIntegration!=undefined and revisedIntegration.lastSyncToken=="") (if revisedIntegration==undefined then "MISSING" else revisedIntegration.lastSyncToken) ""
   AT_CoordinationIntegrations.registry=savedIntegrationRegistry
   AT_CoordinationIntegrations.syncHistory=savedIntegrationHistory
   AT_CoordinationIntegrations.lastErrors=savedIntegrationErrors
   AT_CoordinationProjectStore.pendingIntegrationTokens=savedPendingIntegrationTokens

   local qaEnvelopeA=AT_DisciplineElement elementId:"QA_ENVELOPE_A" discipline:"HVAC"
   local qaEnvelopeB=AT_DisciplineElement elementId:"QA_ENVELOPE_B" discipline:"STRUCTURE"
   AT_DisciplineAdapter.lastInventory=#(qaEnvelopeA,qaEnvelopeB)
   AT_DisciplineAdapter.envelopeOverrides=#()
   local envelopeSet=AT_DisciplineAdapter.setEnvelope "QA_ENVELOPE_A" serviceClearance:4.5 installationClearance:6.0
   addResult results "SERVICE_INSTALLATION_CLEARANCE_STORED" (envelopeSet and qaEnvelopeA.serviceClearance==4.5 and qaEnvelopeA.installationClearance==6.0 and AT_DisciplineAdapter.envelopeOverrides[1].serviceClearance==4.5 and AT_DisciplineAdapter.envelopeOverrides[1].installationClearance==6.0) #(qaEnvelopeA.serviceClearance,qaEnvelopeA.installationClearance) #(4.5,6.0)
   local qaMeshA=AT_ExactMeshRecord elementId:"QA_ENVELOPE_A" minimum:[0,0,0] maximum:[1,1,1] serviceClearance:4.5 installationClearance:6.0
   local qaMeshB=AT_ExactMeshRecord elementId:"QA_ENVELOPE_B" minimum:[0,0,0] maximum:[1,1,1]
   local envelopePairClearance=AT_ExactGeometryEngine.pairClearance qaMeshA qaMeshB AT_DisciplineAdapter.lastInventory 0.0
   addResult results "SERVICE_INSTALLATION_CLEARANCE_PAIR_MAX" (envelopePairClearance==6.0) envelopePairClearance 6.0
   local envelopeCleared=AT_DisciplineAdapter.clearEnvelope "QA_ENVELOPE_A"
   addResult results "SERVICE_INSTALLATION_CLEARANCE_CLEAR" (envelopeCleared and qaEnvelopeA.serviceClearance==undefined and qaEnvelopeA.installationClearance==undefined) #(qaEnvelopeA.serviceClearance,qaEnvelopeA.installationClearance) #(undefined,undefined)

   local unitResult=AT_UnitConversionEngine.toSystemUnits 100.0 "mm"
   addResult results "MILLIMETER_TO_MASTER_UNIT_CONVERSION" (unitResult.valid and abs(unitResult.systemValue-3.937007874)<0.001) unitResult.systemValue 3.937007874

   AT_RuleEngine.clearAll()
   local projectRule=AT_CoordinationRule ruleId:"QA_PROJECT_RULE" disciplineA:"*" disciplineB:"*" checkType:"CLEARANCE" value:10.0 unit:"mm" sourceType:"PROJECT_SPEC" sourceName:"QA Project" approved:true
   local codeRule=AT_CoordinationRule ruleId:"QA_CODE_RULE" disciplineA:"*" disciplineB:"*" checkType:"CLEARANCE" value:15.0 unit:"mm" sourceType:"MANDATORY_CODE" sourceName:"QA Code" approved:false
   AT_RuleEngine.registerRule projectRule; AT_RuleEngine.registerRule codeRule
   local evaluation=AT_RuleEngine.evaluate "HVAC" "STRUCTURE" "CLEARANCE"
   addResult results "UNAPPROVED_HIGHER_PRIORITY_BLOCKS_FALLBACK" (evaluation.reason=="HIGHEST_PRIORITY_RULE_NOT_APPROVED") evaluation.reason "HIGHEST_PRIORITY_RULE_NOT_APPROVED"

   AT_RuleEngine.clearAll()
   local scopedCode=AT_CoordinationRule ruleId:"QA_SCOPED_CODE" disciplineA:"*" disciplineB:"*" checkType:"CLEARANCE" value:20.0 unit:"mm" sourceType:"MANDATORY_CODE" sourceName:"QA Jurisdiction Code" jurisdiction:"EGYPT" approved:true
   local globalProject=AT_CoordinationRule ruleId:"QA_GLOBAL_PROJECT" disciplineA:"*" disciplineB:"*" checkType:"CLEARANCE" value:10.0 unit:"mm" sourceType:"PROJECT_SPEC" sourceName:"QA Global Project" approved:true
   AT_RuleEngine.registerRule scopedCode; AT_RuleEngine.registerRule globalProject
   evaluation=AT_RuleEngine.evaluate "HVAC" "STRUCTURE" "CLEARANCE"
   addResult results "JURISDICTION_REQUIRED_BEFORE_FALLBACK" (evaluation.reason=="JURISDICTION_REQUIRED") evaluation.reason "JURISDICTION_REQUIRED"

   AT_RuleEngine.clearAll()
   local conflictA=AT_CoordinationRule ruleId:"QA_CONFLICT_A" disciplineA:"HVAC" disciplineB:"STRUCTURE" checkType:"CLEARANCE" value:10.0 unit:"mm" sourceType:"AUTHORITY_APPROVAL" sourceName:"Authority A" approved:true
   local conflictB=AT_CoordinationRule ruleId:"QA_CONFLICT_B" disciplineA:"HVAC" disciplineB:"STRUCTURE" checkType:"CLEARANCE" value:20.0 unit:"mm" sourceType:"AUTHORITY_APPROVAL" sourceName:"Authority B" approved:true
   AT_RuleEngine.registerRule conflictA; AT_RuleEngine.registerRule conflictB
   evaluation=AT_RuleEngine.evaluate "HVAC" "STRUCTURE" "CLEARANCE"
   addResult results "SAME_PRIORITY_RULE_CONFLICT" (evaluation.reason=="CONFLICTING_SAME_PRIORITY_RULES") evaluation.reason "CONFLICTING_SAME_PRIORITY_RULES"

   local identitySimulation=AT_CoordinationSimulationResult simulationId:"QA_IDENTITY_SIM" movingElementId:"QA_NODE" actionType:"TRANSLATE" offset:[1,0,0] baselineClashIds:#("QA_CLASH_A","QA_CLASH_B") validated:true status:"EXACT_GEOMETRY_SIMULATION_PASSED" resolvedClashIds:#("QA_CLASH_A","QA_CLASH_B") affectedElementIds:#("QA_NODE")
   local identityCandidate=AT_CoordinationActionCandidate actionId:"QA_IDENTITY_SIM" actionType:"TRANSLATE" offset:[1,0,0] targetClashIds:#("QA_CLASH_B","QA_CLASH_A") resolvedClashIds:#("QA_CLASH_B","QA_CLASH_A") affectedElementIds:#("QA_NODE") simulationValidated:true
   local identityMatches=AT_CoordinationGovernance.candidateMatchesSimulation identityCandidate identitySimulation
   addResult results "APPROVAL_SIMULATION_IDENTITY_MATCH" identityMatches identityMatches true
   identityCandidate.resolvedClashIds=#("QA_TAMPERED_CLASH")
   local tamperRejected=not AT_CoordinationGovernance.candidateMatchesSimulation identityCandidate identitySimulation
   addResult results "APPROVAL_REJECTS_TAMPERED_RESOLUTION_SET" tamperRejected tamperRejected true
   identityCandidate.resolvedClashIds=#("QA_CLASH_B","QA_CLASH_A")
   identityCandidate.targetClashIds=#("QA_CLASH_A","QA_CLASH_B")
   identityCandidate.introducedClashIds=#("QA_NEW_CLASH")
   local introducedTamperRejected=not AT_CoordinationGovernance.candidateMatchesSimulation identityCandidate identitySimulation
   addResult results "APPROVAL_REJECTS_TAMPERED_NEW_CLASH_SET" introducedTamperRejected introducedTamperRejected true

   local riskCandidate=AT_CoordinationActionCandidate actionId:"QA_RISK_UNKNOWN" targetClashIds:#("QA_CLASH") resolvedClashIds:#("QA_CLASH") affectedElementIds:#("QA_NODE") simulationValidated:true risk:50.0 riskAssessed:false
   local riskProposal=AT_SolutionEngine.buildProposal riskCandidate
   local scoreWithoutRisk=AT_SolutionEngine.scoreProposal riskProposal
   AT_SolutionEngine.setWeights 100.0 200.0 0.0 2.0
   local scoreRiskWeightZero=AT_SolutionEngine.scoreProposal riskProposal
   AT_SolutionEngine.setWeights 100.0 200.0 999.0 2.0
   local scoreRiskWeightHigh=AT_SolutionEngine.scoreProposal riskProposal
   local riskEvaluation=AT_SolutionEngine.evaluateProposal riskProposal
   addResult results "RISK_NOT_ASSESSED_EXCLUDED_FROM_SCORE" (scoreRiskWeightZero==scoreRiskWeightHigh and riskEvaluation.riskAssessment=="NOT_ASSESSED" and (findItem riskEvaluation.reasons "RISK_NOT_ASSESSED")>0) #(scoreRiskWeightZero,scoreRiskWeightHigh,riskEvaluation.riskAssessment) "equal scores and NOT_ASSESSED"
   local duplicateIdCandidate=AT_CoordinationActionCandidate actionId:"QA_DUPLICATE_IDS" targetClashIds:#("QA_CLASH","QA_CLASH") affectedElementIds:#("QA_NODE")
   local duplicateIdIssues=AT_SolutionEngine.validateCandidate duplicateIdCandidate
   addResult results "CANDIDATE_DUPLICATE_TARGET_IDS_REJECTED" ((findItem duplicateIdIssues "INVALID_TARGET_CLASH_ID_SET")>0) duplicateIdIssues "INVALID_TARGET_CLASH_ID_SET"
   local mismatchProposal=AT_SolutionEngine.buildProposal riskCandidate
   mismatchProposal.resolvedClashes+=1
   local mismatchEvaluation=AT_SolutionEngine.evaluateProposal mismatchProposal
   addResult results "PROPOSAL_COUNT_ID_MISMATCH_REJECTED" (not mismatchEvaluation.eligible and (findItem mismatchEvaluation.reasons "RESOLVED_CLASH_COUNT_MISMATCH")>0) mismatchEvaluation.reasons "RESOLVED_CLASH_COUNT_MISMATCH"

   AT_RuleEngine.clearAll()
   local accessRule=AT_CoordinationRule ruleId:"QA_ACCESS_RULE" disciplineA:"HVAC" disciplineB:"STRUCTURE" checkType:"ACCESS" value:1.0 unit:"system" sourceType:"PROJECT_SPEC" sourceName:"QA Project" approved:true
   AT_RuleEngine.registerRule accessRule
   evaluation=AT_RuleEngine.evaluate "HVAC" "STRUCTURE" "ACCESS"
   addResult results "UNIMPLEMENTED_RULE_CHECK_BLOCKED" (evaluation.reason=="CHECK_TYPE_VALIDATOR_NOT_IMPLEMENTED") evaluation.reason "CHECK_TYPE_VALIDATOR_NOT_IMPLEMENTED"
  ) catch (
   append lastErrors (getCurrentException())
   addResult results "HARNESS_EXCEPTION" false (getCurrentException()) "NO_EXCEPTION"
  )
  for n in testNodes where isValidNode n do try (delete n) catch()
  select #()
  for n in savedSelection where isValidNode n do selectMore n
  AT_ExactGeometryEngine.lastMeshes=savedMeshes
  AT_ExactGeometryEngine.lastResults=savedGeometryResults
  AT_ExactGeometryEngine.lastErrors=savedGeometryErrors
  AT_RuleEngine.rules=savedRules
  AT_RuleEngine.registryRevision=savedRuleRevision
  AT_RuleEngine.requiredCheckTypes=savedRequiredCheckTypes
  AT_RuleEngine.lastEvaluations=savedRuleEvaluations
  AT_RuleEngine.lastErrors=savedRuleErrors
  AT_CoordinationSolutionGenerator.lastCandidates=savedMoveCandidates
  AT_CoordinationSolutionGenerator.lastRotationCandidates=savedRotationCandidates
  AT_CoordinationSolutionGenerator.lastErrors=savedGeneratorErrors
  AT_SolutionEngine.lastResults=savedSolutionResults
  AT_SolutionEngine.lastProposals=savedSolutionProposals
  AT_SolutionEngine.lastRejectedCandidates=savedRejectedCandidates
  AT_SolutionEngine.weights=savedSolutionWeights
  AT_DisciplineAdapter.lastInventory=savedDisciplineInventory
  AT_DisciplineAdapter.lastUnclassified=savedDisciplineUnclassified
  AT_DisciplineAdapter.lastErrors=savedDisciplineErrors
  AT_DisciplineAdapter.envelopeOverrides=savedEnvelopeOverrides
  AT_DisciplineAdapter.metadataRevision=savedDisciplineMetadataRevision
  AT_CoordinationIntegrations.registry=savedIntegrationRegistry
  AT_CoordinationIntegrations.syncHistory=savedIntegrationHistory
  AT_CoordinationIntegrations.lastErrors=savedIntegrationErrors
  AT_CoordinationProjectStore.pendingIntegrationTokens=savedPendingIntegrationTokens
  lastResults=results
  results
 ),
 fn summary = (
  local passed=0; local failed=0
  for r in lastResults do if r[2] then passed+=1 else failed+=1
  "Coordination Self Tests: "+(passed as string)+" passed, "+(failed as string)+" failed"
 )
)
AT_CoordinationSelfTests=AT_CoordinationSelfTestsStruct()
