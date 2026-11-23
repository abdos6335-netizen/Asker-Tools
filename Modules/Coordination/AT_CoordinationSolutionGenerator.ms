/* Asker Tools - Coordination Candidate Generator
   Creates deterministic translation and rotation alternatives from exact mesh clashes.
   Candidate generation never edits scene nodes; all actions require exact simulation.
*/
global AT_CoordinationSolutionGenerator
struct AT_CoordinationSolutionGeneratorStruct (
 version="0.2.0", lastCandidates=#(), lastRotationCandidates=#(), lastErrors=#(),
 fn findRecord records elementId = (for r in records where r.elementId==elementId do return r; undefined),
 fn separationOffset moving fixed axis sign clearance = (
  local delta=[0,0,0]
  if axis==1 then delta.x=if sign>0 then fixed.maximum.x-moving.minimum.x+clearance else fixed.minimum.x-moving.maximum.x-clearance
  if axis==2 then delta.y=if sign>0 then fixed.maximum.y-moving.minimum.y+clearance else fixed.minimum.y-moving.maximum.y-clearance
  if axis==3 then delta.z=if sign>0 then fixed.maximum.z-moving.minimum.z+clearance else fixed.minimum.z-moving.maximum.z-clearance
  delta
 ),
 fn generateTranslations records clashes clearance:0.0 = (
  local result=#(); lastErrors=#()
  if (classOf clearance!=Integer and classOf clearance!=Float) or clearance<0 then (append lastErrors #("","INVALID_CLEARANCE"); return result)
  for clash in clashes do (
   local a=findRecord records clash.elementA
   local b=findRecord records clash.elementB
   if a==undefined or b==undefined then append lastErrors #(clash.clashId,"CLASH_ELEMENT_NOT_FOUND")
   else for moving in #(a,b) do (
    for axis=1 to 3 do for sign in #(-1,1) do (
     local offset=separationOffset moving (if moving.elementId==a.elementId then b else a) axis sign clearance
     local c=AT_CoordinationActionCandidate()
     c.actionId="TX_"+moving.elementId+"_"+clash.clashId+"_"+(axis as string)+"_"+(sign as string)
     c.description="Translate "+moving.nodeName+" along axis "+(axis as string)+" by "+(offset as string)
     c.actionType="TRANSLATE"; c.offset=offset
     c.targetClashIds=#(clash.clashId)
     c.affectedElementIds=#(moving.elementId)
     c.requiresEngineeringApproval=true; c.simulationValidated=false
     append result c
    )
   )
  )
  lastCandidates=result
  result
 ),
 fn generateRotations records clashes angles:#(15.0,-15.0,30.0,-30.0) = (
  local result=#()
  for angle in angles where (classOf angle!=Integer and classOf angle!=Float) or angle==0 do append lastErrors #("", "INVALID_ROTATION_ANGLE")
  for clash in clashes do (
   local a=findRecord records clash.elementA
   local b=findRecord records clash.elementB
   if a==undefined or b==undefined then append lastErrors #(clash.clashId,"CLASH_ELEMENT_NOT_FOUND")
   else for moving in #(a,b) do for axisIndex=1 to 3 do for angle in angles where (classOf angle==Integer or classOf angle==Float) and angle!=0 do (
    local axis=if axisIndex==1 then [1,0,0] else if axisIndex==2 then [0,1,0] else [0,0,1]
    local pivot=moving.nodeRef.transform.row4
    local c=AT_CoordinationActionCandidate()
    c.actionId="ROT_"+moving.elementId+"_"+clash.clashId+"_"+(axisIndex as string)+"_"+(angle as string)
    c.description="Rotate "+moving.nodeName+" by "+(angle as string)+" degrees around world axis "+(axisIndex as string)
    c.actionType="ROTATE"; c.rotationAxis=axis; c.angleDegrees=angle; c.pivot=pivot
    c.targetClashIds=#(clash.clashId)
    c.affectedElementIds=#(moving.elementId)
    c.requiresEngineeringApproval=true; c.simulationValidated=false
    append result c
   )
  )
  lastRotationCandidates=result
  result
 ),
 fn generateAllAlternatives records clashes clearance:0.0 angles:#(15.0,-15.0,30.0,-30.0) = (
  local translations=generateTranslations records clashes clearance:clearance
  local translationErrors=lastErrors
  local rotations=generateRotations records clashes angles:angles
  lastErrors=translationErrors+lastErrors
  translations+rotations
 ),
 fn toProposalCandidates = (
  local result=#()
  for action in (lastCandidates+lastRotationCandidates) do (
   local candidate=AT_CoordinationActionCandidate()
   candidate.actionId=action.actionId; candidate.description=action.description
   candidate.actionType=action.actionType; candidate.offset=action.offset
   candidate.rotationAxis=action.rotationAxis; candidate.angleDegrees=action.angleDegrees; candidate.pivot=action.pivot
   candidate.targetClashIds=action.targetClashIds
   candidate.resolvedClashIds=action.resolvedClashIds
   candidate.introducedClashIds=action.introducedClashIds
   candidate.affectedElementIds=action.affectedElementIds
   candidate.risk=0.0; candidate.requiresEngineeringApproval=true; candidate.simulationValidated=false
   append result candidate
  )
  result
 ),
 fn clear = (lastCandidates=#(); lastRotationCandidates=#(); lastErrors=#(); true)
)
AT_CoordinationSolutionGenerator=AT_CoordinationSolutionGeneratorStruct()
