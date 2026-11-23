/* Asker Tools - Exact Triangle Mesh Geometry Engine
   Read-only narrow-phase intersection and minimum surface distance.
*/
global AT_ExactGeometryEngine
struct AT_ExactTriangle (a=[0,0,0], b=[0,0,0], c=[0,0,0], minimum=[0,0,0], maximum=[0,0,0], faceIndex=0)
struct AT_ExactMeshRecord (nodeRef, sourceTransform=undefined, sourcePivot=[0,0,0], elementId="", nodeName="", triangles=#(), minimum=[0,0,0], maximum=[0,0,0], faceCount=0, validFaceCount=0, invalidFaceCount=0, requiredClearance=undefined, serviceClearance=undefined, installationClearance=undefined, isClosed=false, isManifold=false, topologyChecked=false)
struct AT_ExactPairClearanceRecord (elementA="", elementB="", requiredClearance=0.0, severity="INFORMATION", ruleIds=#())

struct AT_ExactClashRecord (clashId="", elementA="", elementB="", nameA="", nameB="", disciplineA="UNKNOWN", disciplineB="UNKNOWN", ruleSeverity="INFORMATION", ruleIds=#(), status="SEPARATED", minimumDistance=undefined, minimumDistanceKnown=false, requiredClearance=0.0, clearanceShortfall=0.0, intersectingFaceA=0, intersectingFaceB=0, testedTrianglePairs=0)
struct AT_ExactGeometryEngineStruct (
 version="0.2.0", lastMeshes=#(), lastResults=#(), lastErrors=#(),
 fn idForNode n = (try ((getHandleByAnim n) as string) catch ("")),
 fn addEdgeCount edgeCounts indexA indexB faceIndex = (
  local low=amin indexA indexB; local high=amax indexA indexB
  local key=(low as string)+"_"+(high as string)
  local found=0
  for i=1 to edgeCounts.count where edgeCounts[i][1]==key do found=i
  if found==0 then append edgeCounts #(key,1,low,high,#(faceIndex))
  else (edgeCounts[found][2]+=1; appendIfUnique edgeCounts[found][5] faceIndex)
  true
 ),
 fn vertexLinksManifold edgeCounts = (
  local vertices=#()
  for edge in edgeCounts do (appendIfUnique vertices edge[3]; appendIfUnique vertices edge[4])
  for vertex in vertices do (
   local incidentFaces=#(); local adjacency=#()
   for edge in edgeCounts where edge[3]==vertex or edge[4]==vertex do (
    for faceIndex in edge[5] do appendIfUnique incidentFaces faceIndex
    if edge[2]==2 and edge[5].count==2 do append adjacency #(edge[5][1],edge[5][2])
   )
   if incidentFaces.count<3 then return false
   for faceIndex in incidentFaces do (
    local degree=0
    for link in adjacency where link[1]==faceIndex or link[2]==faceIndex do degree+=1
    if degree!=2 then return false
   )
   local visited=#(incidentFaces[1]); local changed=true
   while changed do (
    changed=false
    for link in adjacency do (
     if (findItem visited link[1])>0 and (findItem visited link[2])==0 then (append visited link[2]; changed=true)
     if (findItem visited link[2])>0 and (findItem visited link[1])==0 then (append visited link[1]; changed=true)
    )
   )
   if visited.count!=incidentFaces.count then return false
  )
  true
 ),
 fn rayHitDistance origin direction tri epsilon:1.0e-7 = (
  /* Inclusive barycentric boundaries are intentional: adjacent triangles may
     both report a shared-edge/vertex hit. pointInsideClosedMesh deduplicates
     equal ray parameters so the surface crossing is counted exactly once. */
  local edge1=tri.b-tri.a; local edge2=tri.c-tri.a
  local directionLength=length direction
  local edgeScale=(length edge1)*(length edge2)*directionLength
  if edgeScale<=1.0e-20 then return undefined
  local h=cross direction edge2; local determinant=dot edge1 h
  if abs determinant<=epsilon*edgeScale then return undefined
  local inverse=1.0/determinant
  local offset=origin-tri.a
  local u=inverse*(dot offset h)
  if u < -epsilon or u > 1.0+epsilon then return undefined
  local q=cross offset edge1
  local v=inverse*(dot direction q)
  if v < -epsilon or (u+v)>1.0+epsilon then return undefined
  local distance=inverse*(dot edge2 q)
  if distance>epsilon then distance else undefined
 ),
 fn rayHitsTriangle origin direction tri epsilon:1.0e-7 = (
  (rayHitDistance origin direction tri epsilon:epsilon)!=undefined
 ),
 fn pointInsideClosedMesh point meshRecord = (
  if not meshRecord.isClosed or not meshRecord.isManifold then return false
  if point.x<meshRecord.minimum.x or point.x>meshRecord.maximum.x or point.y<meshRecord.minimum.y or point.y>meshRecord.maximum.y or point.z<meshRecord.minimum.z or point.z>meshRecord.maximum.z then return false
  local directions=#([1.0,0.371390676,0.529103],[0.217,1.0,0.413],[0.619,0.283,1.0])
  local insideVotes=0
  for rawDirection in directions do (
   local direction=normalize rawDirection
   local hitDistances=#()
   for tri in meshRecord.triangles do (
    local hitDistance=rayHitDistance point direction tri
    if hitDistance!=undefined do (
     local duplicate=false
     local meshDiagonal=length (meshRecord.maximum-meshRecord.minimum)
     local hitTolerance=1.0e-9*(amax meshDiagonal (amax 1.0 (abs hitDistance)))
     for previous in hitDistances where abs(previous-hitDistance)<=hitTolerance do duplicate=true
     if not duplicate do append hitDistances hitDistance
    )
   )
   if (mod hitDistances.count 2)==1 do insideVotes+=1
  )
  insideVotes>=2
 ),
 fn makeTriangle a b c faceIndex = (
  AT_ExactTriangle a:a b:b c:c
   minimum:[(amin a.x (amin b.x c.x)),(amin a.y (amin b.y c.y)),(amin a.z (amin b.z c.z))]
   maximum:[(amax a.x (amax b.x c.x)),(amax a.y (amax b.y c.y)),(amax a.z (amax b.z c.z))]
   faceIndex:faceIndex
 ),
 fn boxesOverlap aminV amaxV bminV bmaxV tolerance:0.0 = (
  (aminV.x <= bmaxV.x+tolerance and amaxV.x+tolerance >= bminV.x) and
  (aminV.y <= bmaxV.y+tolerance and amaxV.y+tolerance >= bminV.y) and
  (aminV.z <= bmaxV.z+tolerance and amaxV.z+tolerance >= bminV.z)
 ),
 fn separatedOnAxis axis a b c d e f epsilon axisThreshold:1.0e-12 = (
  local axisLength=length axis
  if axisLength<=axisThreshold then return false
  /* Normalize every usable SAT axis so epsilon is a world-space distance,
     independent of whether the axis came from a face normal or edge cross. */
  local unitAxis=axis/axisLength
  local p1=dot a unitAxis; local p2=dot b unitAxis; local p3=dot c unitAxis
  local q1=dot d unitAxis; local q2=dot e unitAxis; local q3=dot f unitAxis
  local minP=amin p1 (amin p2 p3); local maxP=amax p1 (amax p2 p3)
  local minQ=amin q1 (amin q2 q3); local maxQ=amax q1 (amax q2 q3)
  (maxP < minQ-epsilon) or (maxQ < minP-epsilon)
 ),
 fn trianglesIntersect ta tb epsilon:1.0e-6 = (
  local a=#(ta.a,ta.b,ta.c); local b=#(tb.a,tb.b,tb.c)
  local ea=#(ta.b-ta.a,ta.c-ta.b,ta.a-ta.c)
  local eb=#(tb.b-tb.a,tb.c-tb.b,tb.a-tb.c)
  local na=cross ea[1] ea[2]; local nb=cross eb[1] eb[2]
  local naThreshold=1.0e-12*(length ea[1])*(length ea[2])
  local nbThreshold=1.0e-12*(length eb[1])*(length eb[2])
  if separatedOnAxis na a[1] a[2] a[3] b[1] b[2] b[3] epsilon axisThreshold:naThreshold then return false
  if separatedOnAxis nb a[1] a[2] a[3] b[1] b[2] b[3] epsilon axisThreshold:nbThreshold then return false
  for va in ea do for vb in eb do (
   local threshold=1.0e-12*(length va)*(length vb)
   if separatedOnAxis (cross va vb) a[1] a[2] a[3] b[1] b[2] b[3] epsilon axisThreshold:threshold then return false
  )
  for edge in ea do (
   local threshold=1.0e-12*(length na)*(length edge)
   if separatedOnAxis (cross na edge) a[1] a[2] a[3] b[1] b[2] b[3] epsilon axisThreshold:threshold then return false
  )
  for edge in eb do (
   local threshold=1.0e-12*(length nb)*(length edge)
   if separatedOnAxis (cross nb edge) a[1] a[2] a[3] b[1] b[2] b[3] epsilon axisThreshold:threshold then return false
  )
  true
 ),
 fn pointTriangleDistanceSquared p a b c = (
  local ab=b-a; local ac=c-a; local ap=p-a
  local d1=dot ab ap; local d2=dot ac ap
  if d1<=0 and d2<=0 then return (dot ap ap)
  local bp=p-b; local d3=dot ab bp; local d4=dot ac bp
  if d3>=0 and d4<=d3 then return (dot bp bp)
  local vc=d1*d4-d3*d2
  if vc<=0 and d1>=0 and d3<=0 then (
   local v=d1/(d1-d3); local delta=p-(a+ab*v); return (dot delta delta)
  )
  local cp=p-c; local d5=dot ab cp; local d6=dot ac cp
  if d6>=0 and d5<=d6 then return (dot cp cp)
  local vb=d5*d2-d1*d6
  if vb<=0 and d2>=0 and d6<=0 then (
   local w=d2/(d2-d6); local delta=p-(a+ac*w); return (dot delta delta)
  )
  local va=d3*d6-d5*d4
  if va<=0 and (d4-d3)>=0 and (d5-d6)>=0 then (
   local w=(d4-d3)/((d4-d3)+(d5-d6)); local delta=p-(b+(c-b)*w); return (dot delta delta)
  )
  local denom=1.0/(va+vb+vc); local v=vb*denom; local w=vc*denom
  local delta=p-(a+ab*v+ac*w); (dot delta delta)
 ),
 fn pointSegmentDistanceSquared point startPoint endPoint = (
  local direction=endPoint-startPoint
  local lengthSquared=dot direction direction
  if lengthSquared<=1.0e-12 then (
   local delta=point-startPoint; return (dot delta delta)
  )
  local parameter=amax 0.0 (amin 1.0 ((dot (point-startPoint) direction)/lengthSquared))
  local delta=point-(startPoint+direction*parameter)
  (dot delta delta)
 ),
 fn segmentDistanceSquared p1 q1 p2 q2 = (
  local d1=q1-p1; local d2=q2-p2; local r=p1-p2
  local aa=dot d1 d1; local ee=dot d2 d2
  if aa<=1.0e-12 then return (pointSegmentDistanceSquared p1 p2 q2)
  if ee<=1.0e-12 then return (pointSegmentDistanceSquared p2 p1 q1)
  local bb=dot d1 d2; local cc=dot d1 r; local ff=dot d2 r
  local denom=aa*ee-bb*bb
  if abs denom<=1.0e-12*aa*ee then (
   local best=pointSegmentDistanceSquared p1 p2 q2
   best=amin best (pointSegmentDistanceSquared q1 p2 q2)
   best=amin best (pointSegmentDistanceSquared p2 p1 q1)
   best=amin best (pointSegmentDistanceSquared q2 p1 q1)
   return best
  )
  local s=amax 0.0 (amin 1.0 ((bb*ff-cc*ee)/denom))
  local t=(bb*s+ff)/ee
  if t<0.0 then (t=0.0; s=amax 0.0 (amin 1.0 (-cc/aa)))
  if t>1.0 then (t=1.0; s=amax 0.0 (amin 1.0 ((bb-cc)/aa)))
  local delta=(p1+d1*s)-(p2+d2*t)
  (dot delta delta)
 ),
 fn triangleDistanceSquared ta tb = (
  local best=1.0e30; local va=#(ta.a,ta.b,ta.c); local vb=#(tb.a,tb.b,tb.c)
  for p in va do best=amin best (pointTriangleDistanceSquared p tb.a tb.b tb.c)
  for p in vb do best=amin best (pointTriangleDistanceSquared p ta.a ta.b ta.c)
  local ea=#(#(ta.a,ta.b),#(ta.b,ta.c),#(ta.c,ta.a))
  local eb=#(#(tb.a,tb.b),#(tb.b,tb.c),#(tb.c,tb.a))
  for x in ea do for y in eb do best=amin best (segmentDistanceSquared x[1] x[2] y[1] y[2])
  best
 ),
 fn buildMeshRecord node = (
  local record=AT_ExactMeshRecord()
  record.nodeRef=node; record.sourceTransform=node.objectTransform; record.sourcePivot=node.pivot; record.elementId=idForNode node; record.nodeName=node.name
  local meshValue=snapshotAsMesh node
  if meshValue==undefined then throw "MESH_SNAPSHOT_FAILED"
  local faceTotal=getNumFaces meshValue; record.faceCount=faceTotal
  if faceTotal<=0 then throw "NO_TRIANGLE_FACES"
  local bounds=nodeGetBoundingBox node node.objectTransform
  record.minimum=bounds[1]; record.maximum=bounds[2]
  local edgeCounts=#()
  for faceIndex=1 to faceTotal do (
   local face=getFace meshValue faceIndex
   local p1=getVert meshValue face.x
   local p2=getVert meshValue face.y
   local p3=getVert meshValue face.z
   local faceArea2=length (cross (p2-p1) (p3-p1))
   if faceArea2<=1.0e-10 then record.invalidFaceCount+=1
   else (
    append record.triangles (makeTriangle p1 p2 p3 faceIndex)
    record.validFaceCount+=1
    addEdgeCount edgeCounts face.x face.y faceIndex
    addEdgeCount edgeCounts face.y face.z faceIndex
    addEdgeCount edgeCounts face.z face.x faceIndex
   )
  )
  if record.validFaceCount==0 then throw "NO_VALID_TRIANGLE_FACES"
  record.topologyChecked=true
  if record.invalidFaceCount>0 then (record.isClosed=false; record.isManifold=false)
  if record.invalidFaceCount==0 then (record.isClosed=true; record.isManifold=true)
  for edge in edgeCounts do (
   if edge[2]!=2 do record.isClosed=false
   if edge[2]>2 do record.isManifold=false
  )
  if record.isClosed and record.isManifold and not vertexLinksManifold edgeCounts then record.isManifold=false
  record
 ),
 fn inspect nodes:undefined includeHidden:false = (
  local sourceNodes=if nodes==undefined then objects as array else nodes
  local records=#(); lastErrors=#()
  for node in sourceNodes where isValidNode node do if isSupportedNode node and (includeHidden or not node.isHidden) do (
   try (append records (buildMeshRecord node))
   catch (append lastErrors #((idForNode node),"MESH_INSPECTION_FAILED"))
  )
  lastMeshes=records; records
 ),
 fn clashId idA idB = (if idA<idB then ("MESH_"+idA+"_"+idB) else ("MESH_"+idB+"_"+idA)),
 fn inspectPair recordA recordB requiredClearance:0.0 epsilon:1.0e-6 = (
  local result=AT_ExactClashRecord()
  result.clashId=clashId recordA.elementId recordB.elementId
  result.elementA=recordA.elementId; result.elementB=recordB.elementId
  result.requiredClearance=requiredClearance
  local best=1.0e30; local intersected=false
  for ta in recordA.triangles do for tb in recordB.triangles where boxesOverlap ta.minimum ta.maximum tb.minimum tb.maximum tolerance:requiredClearance do (
   result.testedTrianglePairs+=1
   if trianglesIntersect ta tb epsilon:epsilon then (
    intersected=true; result.intersectingFaceA=ta.faceIndex; result.intersectingFaceB=tb.faceIndex
   ) else if not intersected do best=amin best (triangleDistanceSquared ta tb)
  )
  if intersected then (result.status="EXACT_MESH_INTERFERENCE"; result.minimumDistance=0.0; result.minimumDistanceKnown=true)
  else (
   if best==1.0e30 then (result.minimumDistance=undefined; result.minimumDistanceKnown=false)
   else (result.minimumDistance=sqrt best; result.minimumDistanceKnown=true)
   local aContainsB=(recordB.minimum.x>=recordA.minimum.x and recordB.maximum.x<=recordA.maximum.x and recordB.minimum.y>=recordA.minimum.y and recordB.maximum.y<=recordA.maximum.y and recordB.minimum.z>=recordA.minimum.z and recordB.maximum.z<=recordA.maximum.z)
   local bContainsA=(recordA.minimum.x>=recordB.minimum.x and recordA.maximum.x<=recordB.maximum.x and recordA.minimum.y>=recordB.minimum.y and recordA.maximum.y<=recordB.maximum.y and recordA.minimum.z>=recordB.minimum.z and recordA.maximum.z<=recordB.maximum.z)
   if aContainsB or bContainsA then (
    if not recordA.isClosed or not recordB.isClosed or not recordA.isManifold or not recordB.isManifold then result.status="CONTAINMENT_UNVERIFIED"
    else (
     local inner=if aContainsB then recordB else recordA
     local outer=if aContainsB then recordA else recordB
     if inner.triangles.count>0 and pointInsideClosedMesh inner.triangles[1].a outer then result.status="SOLID_CONTAINMENT_INTERFERENCE"
    )
   )
   if result.minimumDistanceKnown then result.clearanceShortfall=amax 0.0 (requiredClearance-result.minimumDistance)
   else result.clearanceShortfall=0.0
   if result.status=="SEPARATED" and result.minimumDistanceKnown and result.clearanceShortfall>epsilon then result.status="CLEARANCE_VIOLATION"
  )
  result
 ),
 fn findDisciplineRecord inventory elementId = (for item in inventory where item.elementId==elementId do return item; undefined),
 fn pairRuleMetadata recordA recordB pairOverrides:#() = (
  local severity="INFORMATION"; local ruleIds=#()
  local priority=0
  for item in pairOverrides where ((item.elementA==recordA.elementId and item.elementB==recordB.elementId) or (item.elementA==recordB.elementId and item.elementB==recordA.elementId)) do (
   local current=findItem #("INFORMATION","LOW","MEDIUM","HIGH","CRITICAL") item.severity
   if current>priority then (priority=current; severity=item.severity)
   for id in item.ruleIds do appendIfUnique ruleIds id
  )
  #(severity,ruleIds)
 ),
 fn pairClearance recordA recordB inventory defaultClearance pairOverrides:#() = (
  local a=findDisciplineRecord inventory recordA.elementId
  local b=findDisciplineRecord inventory recordB.elementId
  local value=defaultClearance
  if recordA.requiredClearance!=undefined do value=amax value recordA.requiredClearance
  if recordB.requiredClearance!=undefined do value=amax value recordB.requiredClearance
  if a!=undefined and a.requiredClearance!=undefined do value=amax value a.requiredClearance
  if b!=undefined and b.requiredClearance!=undefined do value=amax value b.requiredClearance
  for item in pairOverrides where ((item.elementA==recordA.elementId and item.elementB==recordB.elementId) or (item.elementA==recordB.elementId and item.elementB==recordA.elementId)) do value=amax value item.requiredClearance
  value
 ),
 fn detectClashesWithClearances inventory defaultClearance:0.0 pairOverrides:#() epsilon:1.0e-6 = (
  local source=lastMeshes
  local results=#(); lastErrors=#()
  if (classOf defaultClearance!=Integer and classOf defaultClearance!=Float) or defaultClearance<0 then (
   append lastErrors #("","INVALID_DEFAULT_CLEARANCE"); return results
  )
  for i=1 to source.count do for j=i+1 to source.count do (
   local a=source[i]; local b=source[j]
   local clearance=pairClearance a b inventory defaultClearance pairOverrides:pairOverrides
   if boxesOverlap a.minimum a.maximum b.minimum b.maximum tolerance:clearance do (
    local result=inspectPair a b requiredClearance:clearance epsilon:epsilon
    local metadata=pairRuleMetadata a b pairOverrides:pairOverrides
    result.ruleSeverity=metadata[1]; result.ruleIds=metadata[2]
    if result.status!="SEPARATED" do append results result
   )
  )
  lastResults=results; results
 ),
 fn detectClashes records:undefined requiredClearance:0.0 epsilon:1.0e-6 = (
  local source=if records==undefined then lastMeshes else records
  local results=#(); lastErrors=#()
  if (classOf requiredClearance!=Integer and classOf requiredClearance!=Float) or requiredClearance<0 then (
   append lastErrors #("","INVALID_CLEARANCE_VALUE"); return results
  )
  for i=1 to source.count do for j=i+1 to source.count where j<=source.count do (
   local a=source[i]; local b=source[j]
   if boxesOverlap a.minimum a.maximum b.minimum b.maximum tolerance:requiredClearance do (
    local result=inspectPair a b requiredClearance:requiredClearance epsilon:epsilon
    if result.status!="SEPARATED" do append results result
   )
  )
  lastResults=results; results
 ),
 fn clear = (lastMeshes=#(); lastResults=#(); lastErrors=#(); true)
)
AT_ExactGeometryEngine=AT_ExactGeometryEngineStruct()
