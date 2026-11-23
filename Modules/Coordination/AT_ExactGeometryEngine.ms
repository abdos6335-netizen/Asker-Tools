/* Asker Tools - Exact Triangle Mesh Geometry Engine
   Read-only narrow-phase intersection and minimum surface distance.
*/
global AT_ExactGeometryEngine
struct AT_ExactTriangle (a=[0,0,0], b=[0,0,0], c=[0,0,0], minimum=[0,0,0], maximum=[0,0,0], faceIndex=0)
struct AT_ExactMeshRecord (nodeRef, sourceTransform=undefined, elementId="", nodeName="", triangles=#(), minimum=[0,0,0], maximum=[0,0,0], faceCount=0)
struct AT_ExactClashRecord (clashId="", elementA="", elementB="", status="SEPARATED", minimumDistance=1.0e9, requiredClearance=0.0, clearanceShortfall=0.0, intersectingFaceA=0, intersectingFaceB=0, testedTrianglePairs=0)
struct AT_ExactGeometryEngineStruct (
 version="0.1.0", lastMeshes=#(), lastResults=#(), lastErrors=#(),
 fn idForNode n = (try ((getHandleByAnim n) as string) catch ("")),
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
 fn separatedOnAxis axis a b c d e f epsilon = (
  local axisLength=length axis
  if axisLength <= 1.0e-8 then return false
  local p1=dot a axis; local p2=dot b axis; local p3=dot c axis
  local q1=dot d axis; local q2=dot e axis; local q3=dot f axis
  local minP=amin p1 (amin p2 p3); local maxP=amax p1 (amax p2 p3)
  local minQ=amin q1 (amin q2 q3); local maxQ=amax q1 (amax q2 q3)
  (maxP < minQ-epsilon*axisLength) or (maxQ < minP-epsilon*axisLength)
 ),
 fn trianglesIntersect ta tb epsilon:1.0e-6 = (
  local a=#(ta.a,ta.b,ta.c); local b=#(tb.a,tb.b,tb.c)
  local ea=#(ta.b-ta.a,ta.c-ta.b,ta.a-ta.c)
  local eb=#(tb.b-tb.a,tb.c-tb.b,tb.a-tb.c)
  local na=cross ea[1] ea[2]; local nb=cross eb[1] eb[2]
  if separatedOnAxis na a[1] a[2] a[3] b[1] b[2] b[3] epsilon then return false
  if separatedOnAxis nb a[1] a[2] a[3] b[1] b[2] b[3] epsilon then return false
  for va in ea do for vb in eb do
   if separatedOnAxis (cross va vb) a[1] a[2] a[3] b[1] b[2] b[3] epsilon then return false
  for edge in ea do
   if separatedOnAxis (cross na edge) a[1] a[2] a[3] b[1] b[2] b[3] epsilon then return false
  for edge in eb do
   if separatedOnAxis (cross nb edge) a[1] a[2] a[3] b[1] b[2] b[3] epsilon then return false
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
 fn segmentDistanceSquared p1 q1 p2 q2 = (
  local d1=q1-p1; local d2=q2-p2; local r=p1-p2
  local aa=dot d1 d1; local ee=dot d2 d2; local ff=dot d2 r
  local s=0.0; local t=0.0
  if aa<=1.0e-12 and ee<=1.0e-12 then return (dot r r)
  if aa<=1.0e-12 then t=amax 0.0 (amin 1.0 (ff/ee))
  else (
   local cc=dot d1 r
   if ee<=1.0e-12 then s=amax 0.0 (amin 1.0 (-cc/aa))
   else (
    local bb=dot d1 d2; local denom=aa*ee-bb*bb
    if denom!=0 then s=amax 0.0 (amin 1.0 ((bb*ff-cc*ee)/denom))
    t=(bb*s+ff)/ee
    if t<0 then (t=0; s=amax 0.0 (amin 1.0 (-cc/aa)))
    if t>1 then (t=1; s=amax 0.0 (amin 1.0 ((bb-cc)/aa)))
   )
  )
  local delta=(p1+d1*s)-(p2+d2*t); (dot delta delta)
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
  record.nodeRef=node; record.sourceTransform=node.transform; record.elementId=idForNode node; record.nodeName=node.name
  local meshValue=snapshotAsMesh node
  if meshValue==undefined then throw "MESH_SNAPSHOT_FAILED"
  local faceTotal=getNumFaces meshValue; record.faceCount=faceTotal
  if faceTotal<=0 then throw "NO_TRIANGLE_FACES"
  local bounds=nodeGetBoundingBox node node.transform
  record.minimum=bounds[1]; record.maximum=bounds[2]
  for faceIndex=1 to faceTotal do (
   local face=getFace meshValue faceIndex
   local p1=getVert meshValue face.x
   local p2=getVert meshValue face.y
   local p3=getVert meshValue face.z
   append record.triangles (makeTriangle p1 p2 p3 faceIndex)
  )
  record
 ),
 fn inspect nodes:undefined includeHidden:false = (
  local sourceNodes=if nodes==undefined then objects as array else nodes
  local records=#(); lastErrors=#()
  for node in sourceNodes where isValidNode node do if includeHidden or not node.isHidden do (
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
  if intersected then (result.status="EXACT_MESH_INTERFERENCE"; result.minimumDistance=0.0)
  else (
   result.minimumDistance=if best==1.0e30 then 1.0e9 else sqrt best
   result.clearanceShortfall=amax 0.0 (requiredClearance-result.minimumDistance)
   if result.clearanceShortfall>epsilon then result.status="CLEARANCE_VIOLATION"
  )
  result
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
