/* Asker Tools - Discipline Classification and Element Adapter
   Explicit metadata/registry driven. Unknown elements remain unclassified.
*/
global AT_DisciplineAdapter
struct AT_DisciplineElement (
    elementId="", nodeName="", discipline="UNKNOWN", elementType="UNSPECIFIED",
    source="UNRESOLVED", sourceRevision="", nodeRef=undefined,
    boundsMin=[0,0,0], boundsMax=[0,0,0],
    requiredClearance=undefined, serviceEnvelope=undefined,
    installationEnvelope=undefined, metadata=#(), warnings=#()
)
struct AT_DisciplineEnvelopeOverride (
    elementId="", requiredClearance=undefined, serviceEnvelope=undefined, installationEnvelope=undefined
)
struct AT_DisciplineMapping (
    matchKind="USER_PROPERTY", matchValue="", discipline="UNKNOWN",
    elementType="UNSPECIFIED", sourceLabel="PROJECT_MAPPING", revision=""
)
struct AT_DisciplineAdapterStruct (
    version="0.2.0", mappingRevision=0, metadataRevision=0, supportedDisciplines=#("ARCHITECTURE","STRUCTURE","ELECTRICAL","HVAC","FIRE_FIGHTING","PLUMBING","LOW_CURRENT","INTERIOR_ELEMENTS"),
    mappings=#(), envelopeOverrides=#(), lastInventory=#(), lastUnclassified=#(), lastErrors=#(),
    fn isSupportedNode node = ((superClassOf node)==GeometryClass or (superClassOf node)==Shape),
    fn validDiscipline value = (findItem supportedDisciplines (toUpper value) > 0),
    fn registerMapping matchKind matchValue discipline elementType:"UNSPECIFIED" sourceLabel:"PROJECT_MAPPING" revision:"" = (
        local d=toUpper discipline
        local kind=toUpper matchKind
        if (findItem #("USER_PROPERTY","LAYER","CLASS","NODE_NAME") kind)==0 or not validDiscipline d or matchValue=="" then return false
        local normalizedValue=if kind=="USER_PROPERTY" then toUpper matchValue else matchValue
        local m=AT_DisciplineMapping matchKind:kind matchValue:normalizedValue discipline:d elementType:elementType sourceLabel:sourceLabel revision:revision
        for i=mappings.count to 1 by -1 where mappings[i].matchKind==kind and mappings[i].matchValue==normalizedValue do deleteItem mappings i
        append mappings m
        mappingRevision+=1
        true
    ),
    fn removeMapping index = (
        if index<1 or index>mappings.count then return false
        deleteItem mappings index
        mappingRevision+=1
        true
    ),
    fn clearMappings = (mappings=#(); mappingRevision+=1; true),
    fn findEnvelopeOverride elementId = (for item in envelopeOverrides where item.elementId==elementId do return item; undefined),
    fn applyEnvelopeOverride element = (
        local override=findEnvelopeOverride element.elementId
        if override!=undefined then (
            if override.requiredClearance!=undefined then element.requiredClearance=override.requiredClearance
            if override.serviceEnvelope!=undefined then element.serviceEnvelope=override.serviceEnvelope
            if override.installationEnvelope!=undefined then element.installationEnvelope=override.installationEnvelope
        )
        element
    ),
    fn findMapping node = (
        local userDiscipline=""
        try (userDiscipline=getUserProp node "AT_DISCIPLINE") catch()
        if classOf userDiscipline==String and userDiscipline!="" and validDiscipline userDiscipline do
            for m in mappings where m.matchKind=="USER_PROPERTY" and m.matchValue==toUpper userDiscipline do return m
        local layerName=""
        try (layerName=node.layer.name) catch()
        for m in mappings where m.matchKind=="LAYER" and m.matchValue==layerName do return m
        local className=(classOf node as string)
        for m in mappings where m.matchKind=="CLASS" and m.matchValue==className do return m
        for m in mappings where m.matchKind=="NODE_NAME" and m.matchValue==node.name do return m
        undefined
    ),
    fn inspectNode node = (
        local e=AT_DisciplineElement()
        e.nodeRef=node
        e.nodeName=node.name
        try (e.elementId=(getHandleByAnim node) as string) catch()
        local m=findMapping node
        if m!=undefined then (
            e.discipline=m.discipline; e.elementType=m.elementType
            e.source=m.sourceLabel; e.sourceRevision=m.revision
        ) else append e.warnings "DISCIPLINE_MAPPING_MISSING"
        applyEnvelopeOverride e
        try (
            local b=nodeGetBoundingBox node node.objectTransform
            e.boundsMin=b[1]; e.boundsMax=b[2]
        ) catch (append e.warnings "BOUNDING_BOX_UNAVAILABLE")
        e
    ),
    fn inspect nodes:undefined includeHidden:false = (
        local sourceNodes=if nodes==undefined then objects as array else nodes
        local found=#(); local unknown=#(); lastErrors=#()
        for n in sourceNodes where isValidNode n do if isSupportedNode n and (includeHidden or not n.isHidden) do (
            try (
                local e=inspectNode n
                append found e
                if e.discipline=="UNKNOWN" do append unknown e
            ) catch (append lastErrors #((try ((getHandleByAnim n) as string) catch("")),"ELEMENT_ADAPTER_FAILED"))
        )
        lastInventory=found; lastUnclassified=unknown
        found
    ),
    fn setEnvelope elementId requiredClearance:undefined serviceEnvelope:undefined installationEnvelope:undefined = (
        local target=undefined
        for e in lastInventory where e.elementId==elementId do target=e
        if target==undefined then return false
        if requiredClearance==undefined and serviceEnvelope==undefined and installationEnvelope==undefined then return false
        if requiredClearance!=undefined and ((classOf requiredClearance!=Integer and classOf requiredClearance!=Float) or requiredClearance<0) then return false
        local override=findEnvelopeOverride elementId
        if override==undefined then (override=AT_DisciplineEnvelopeOverride elementId:elementId; append envelopeOverrides override)
        if requiredClearance!=undefined then (
            target.requiredClearance=requiredClearance; override.requiredClearance=requiredClearance
        )
        if serviceEnvelope!=undefined then (target.serviceEnvelope=serviceEnvelope; override.serviceEnvelope=serviceEnvelope)
        if installationEnvelope!=undefined then (target.installationEnvelope=installationEnvelope; override.installationEnvelope=installationEnvelope)
        metadataRevision+=1
        true
    ),
    fn clear = (lastInventory=#(); lastUnclassified=#(); lastErrors=#(); true)
)
AT_DisciplineAdapter=AT_DisciplineAdapterStruct()
