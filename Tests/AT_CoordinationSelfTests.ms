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
  lastErrors=#()
  try (
   local overlapA=box length:10 width:10 height:10 pos:[0,0,0]
   append testNodes overlapA; overlapA.name=uniqueName "AT_QA_Overlap_A_"; convertToMesh overlapA
   local overlapB=box length:10 width:10 height:10 pos:[5,0,0]
   append testNodes overlapB; overlapB.name=uniqueName "AT_QA_Overlap_B_"; convertToMesh overlapB
   local records=AT_ExactGeometryEngine.inspect #(overlapA,overlapB)
   local found=AT_ExactGeometryEngine.detectClashes records:records
   addResult results "OVERLAPPING_BOXES" (found.count==1 and found[1].status=="EXACT_MESH_INTERFERENCE") (if found.count>0 then found[1].status else "NO_CLASH") "EXACT_MESH_INTERFERENCE"
   local rotationCandidates=AT_CoordinationSolutionGenerator.generateRotations records found
   addResult results "ROTATION_CANDIDATE_COUNT" (rotationCandidates.count==24) rotationCandidates.count 24
   local rotationProposals=AT_CoordinationSolutionGenerator.toProposalCandidates()
   addResult results "ROTATION_CANDIDATE_METADATA" (rotationProposals.count==24 and rotationProposals[1].actionType=="ROTATE") (if rotationProposals.count>0 then rotationProposals[1].actionType else "NONE") "ROTATE"

   local rotationNode=box length:10 width:10 height:10 pos:[0,70,0]
   append testNodes rotationNode; rotationNode.name=uniqueName "AT_QA_Rotation_Snapshot_"; convertToMesh rotationNode
   local rotationRecords=AT_ExactGeometryEngine.inspect #(rotationNode)
   local originalTransform=rotationNode.transform
   local rotatedSnapshot=AT_CoordinationSimulation.cloneRotatedMesh rotationRecords[1] [0,0,1] 45.0 rotationRecords[1].sourceTransform.row4
   local originalWidth=rotationRecords[1].maximum.x-rotationRecords[1].minimum.x
   local rotatedWidth=rotatedSnapshot.maximum.x-rotatedSnapshot.minimum.x
   addResult results "ROTATION_SNAPSHOT_NON_DESTRUCTIVE" (rotatedWidth>originalWidth*1.3 and rotationNode.transform==originalTransform) rotatedWidth originalWidth
   local gapA=box length:10 width:10 height:10 pos:[0,30,0]
   append testNodes gapA; gapA.name=uniqueName "AT_QA_Clearance_A_"; convertToMesh gapA
   local gapB=box length:10 width:10 height:10 pos:[12,30,0]
   append testNodes gapB; gapB.name=uniqueName "AT_QA_Clearance_B_"; convertToMesh gapB
   records=AT_ExactGeometryEngine.inspect #(gapA,gapB)
   found=AT_ExactGeometryEngine.detectClashes records:records requiredClearance:3.0
   addResult results "CLEARANCE_VIOLATION" (found.count==1 and found[1].status=="CLEARANCE_VIOLATION" and found[1].minimumDistanceKnown) (if found.count>0 then found[1].status else "NO_CLASH") "CLEARANCE_VIOLATION"

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
