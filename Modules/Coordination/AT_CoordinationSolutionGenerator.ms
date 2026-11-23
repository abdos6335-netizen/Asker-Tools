/* Asker Tools - Coordination Candidate Generator
   Creates deterministic translation alternatives from detected exact mesh clashes.
*/
global AT_CoordinationSolutionGenerator
struct AT_CoordinationSolutionGeneratorStruct (
 version="0.1.0", lastCandidates=#(), lastErrors=#(),
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
  if classOf clearance!=Integer and classOf clearance!=Float or clearance<0 then (append lastErrors #("","INVALID_CLEARANCE"); return result)
  for clash in clashes do (
   local a=findRecord records clash.elementA
   local b=findRecord records clash.elementB
   if a==undefined or b==undefined then append lastErrors #(clash.clashId,"CLASH_ELEMENT_NOT_FOUND")
   else for moving in #(a,b) do (
    local fixed=if moving.elementId==a.elementId then b else a
    for axis=1 to 3 do for sign in #(-1,1) do (
     local offset=separationOffset moving fixed axis sign clearance
     local c=AT_CoordinationActionCandidate()
     c.actionId="TX_"+moving.elementId+"_"+clash.clashId+"_"+(axis as string)+"_"+(sign as string)
     c.description="Translate "+moving.nodeName+" along axis "+(axis as string)+" by "+(offset as string)
     c.targetClashIds=#(clash.clashId)
     c.affectedElementIds=#(moving.elementId)
     c.requiresEngineeringApproval=true
     c.simulationValidated=false
     append result c
    )
   )
  )
  lastCandidates=result; result
 ),
 fn clear = (lastCandidates=#(); lastErrors=#(); true)
)
AT_CoordinationSolutionGenerator=AT_CoordinationSolutionGeneratorStruct()
