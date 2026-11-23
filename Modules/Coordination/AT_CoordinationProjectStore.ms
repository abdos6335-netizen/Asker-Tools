/* Asker Tools - Coordination Project Store
   XML persistence for project rules, required checks, clash tracking, sync history and audit events.
   Approval objects are intentionally not restored as active approvals after reopening a project.
*/
global AT_CoordinationProjectStore
struct AT_CoordinationProjectStoreStruct (
 version="0.2.0", lastPath="", lastErrors=#(), pendingIntegrationTokens=#(),
 fn setAttribute xmlNode attributeName value = (xmlNode.SetAttribute attributeName (if value==undefined then "" else value as string); true),
 fn getAttribute xmlNode attributeName = (xmlNode.GetAttribute attributeName as string),
 fn addChild xmlDoc parent name = (
  local child=xmlDoc.CreateElement name
  parent.AppendChild child
  child
 ),
 fn writeRule xmlDoc parent rule = (
  local node=addChild xmlDoc parent "Rule"
  setAttribute node "ruleId" rule.ruleId
  setAttribute node "disciplineA" rule.disciplineA
  setAttribute node "disciplineB" rule.disciplineB
  setAttribute node "checkType" rule.checkType
  setAttribute node "value" rule.value
  setAttribute node "unit" rule.unit
  setAttribute node "severity" rule.severity
  setAttribute node "sourceType" rule.sourceType
  setAttribute node "sourceName" rule.sourceName
  setAttribute node "revision" rule.revision
  setAttribute node "jurisdiction" rule.jurisdiction
  setAttribute node "approved" rule.approved
  setAttribute node "mandatory" rule.mandatory
  setAttribute node "effectiveDate" rule.effectiveDate
  setAttribute node "notes" rule.notes
  true
 ),
 fn writeTracking xmlDoc parent record = (
  local node=addChild xmlDoc parent "Clash"
  setAttribute node "clashId" record.clashId
  setAttribute node "owner" record.owner
  setAttribute node "status" record.status
  setAttribute node "dueDate" record.dueDate
  setAttribute node "note" record.note
  setAttribute node "severity" record.severity
  true
 ),
 fn restoreIntegrationToken integrationId revision = (
  for i=pendingIntegrationTokens.count to 1 by -1 do (
   local token=pendingIntegrationTokens[i]
   if token[1]==integrationId and token[3]==revision then (
    local value=token[4]
    deleteItem pendingIntegrationTokens i
    return value
   )
  )
  undefined
 ),
 fn writeEventRows xmlDoc parent events = (
  for event in events do (
   local node=addChild xmlDoc parent "Event"
   setAttribute node "type" event[1]
   setAttribute node "data" (event as string)
  )
  true
 ),
 fn save path = (
  if path=="" then return false
  local tempPath=path+".tmp"
  local backupPath=path+".bak"
  local xml=undefined
  try (
   local pathClass=dotNetClass "System.IO.Path"
   local directoryClass=dotNetClass "System.IO.Directory"
   local fileClass=dotNetClass "System.IO.File"
   local directory=pathClass.GetDirectoryName path
   if directory!="" and not directoryClass.Exists directory do directoryClass.CreateDirectory directory
   xml=dotNetObject "System.Xml.XmlDocument"
   local declaration=xml.CreateXmlDeclaration "1.0" "utf-8" undefined
   xml.AppendChild declaration
   local root=xml.CreateElement "AskerToolsCoordinationProject"
   root.SetAttribute "schemaVersion" "1"
   xml.AppendChild root
   local rulesNode=addChild xml root "Rules"
   for rule in AT_RuleEngine.rules do writeRule xml rulesNode rule
   local checksNode=addChild xml root "RequiredCheckTypes"
   for checkType in AT_RuleEngine.requiredCheckTypes do (
    local checkNode=addChild xml checksNode "Check"
    setAttribute checkNode "type" checkType
   )
   local mappingsNode=addChild xml root "DisciplineMappings"
   for mapping in AT_DisciplineAdapter.mappings do (
    local node=addChild xml mappingsNode "Mapping"
    setAttribute node "matchKind" mapping.matchKind
    setAttribute node "matchValue" mapping.matchValue
    setAttribute node "discipline" mapping.discipline
    setAttribute node "elementType" mapping.elementType
    setAttribute node "sourceLabel" mapping.sourceLabel
    setAttribute node "revision" mapping.revision
   )
   local overridesNode=addChild xml root "DisciplineEnvelopeOverrides"
   for override in AT_DisciplineAdapter.envelopeOverrides do (
    local node=addChild xml overridesNode "Element"
    setAttribute node "elementId" override.elementId
    setAttribute node "requiredClearance" override.requiredClearance
    setAttribute node "serviceEnvelope" override.serviceEnvelope
    setAttribute node "installationEnvelope" override.installationEnvelope
   )
   local trackingNode=addChild xml root "ClashTracking"
   for record in AT_ClashManager.tracking do writeTracking xml trackingNode record
   local integrationStatesNode=addChild xml root "IntegrationStates"
   local savedIntegrationIds=#()
   for record in AT_CoordinationIntegrations.registry do (
    local node=addChild xml integrationStatesNode "Integration"
    setAttribute node "integrationId" record.integrationId
    setAttribute node "moduleName" record.moduleName
    setAttribute node "revision" record.revision
    setAttribute node "lastSyncToken" record.lastSyncToken
    setAttribute node "enabled" record.enabled
    append savedIntegrationIds record.integrationId
   )
   for token in pendingIntegrationTokens where (findItem savedIntegrationIds token[1])==0 do (
    local node=addChild xml integrationStatesNode "Integration"
    setAttribute node "integrationId" token[1]
    setAttribute node "moduleName" token[2]
    setAttribute node "revision" token[3]
    setAttribute node "lastSyncToken" token[4]
    setAttribute node "enabled" token[5]
   )
   local syncNode=addChild xml root "IntegrationHistory"
   writeEventRows xml syncNode AT_CoordinationIntegrations.syncHistory
   local auditNode=addChild xml root "GovernanceAudit"
   writeEventRows xml auditNode AT_CoordinationGovernance.auditLog
   xml.Save tempPath
   if fileClass.Exists path then (
    if fileClass.Exists backupPath then fileClass.Delete backupPath
    fileClass.Replace tempPath path backupPath
   ) else fileClass.Move tempPath path
   lastPath=path; lastErrors=#()
   true
  ) catch (
   append lastErrors #(path,getCurrentException())
   try (local cleanupFileClass=dotNetClass "System.IO.File"; if cleanupFileClass.Exists tempPath do cleanupFileClass.Delete tempPath) catch()
   false
  )
 ),
 fn load path = (
  if path=="" or not doesFileExist path then return false
  local oldRules=AT_RuleEngine.rules
  local oldRuleRevision=AT_RuleEngine.registryRevision
  local oldChecks=AT_RuleEngine.requiredCheckTypes
  local oldTracking=AT_ClashManager.tracking
  local oldMappings=AT_DisciplineAdapter.mappings
  local oldMappingRevision=AT_DisciplineAdapter.mappingRevision
  local oldOverrides=AT_DisciplineAdapter.envelopeOverrides
  local oldMetadataRevision=AT_DisciplineAdapter.metadataRevision
  local oldPendingIntegrationTokens=pendingIntegrationTokens
  local xml=undefined
  try (
   xml=dotNetObject "System.Xml.XmlDocument"
   xml.Load path
   if (xml.DocumentElement.Name as string)!="AskerToolsCoordinationProject" then throw "INVALID_PROJECT_STORE_ROOT"
   if getAttribute xml.DocumentElement "schemaVersion"!="1" then throw "UNSUPPORTED_PROJECT_STORE_SCHEMA"
   local loadedRules=#()
   local ruleNodes=xml.SelectNodes "/AskerToolsCoordinationProject/Rules/Rule"
   for node in ruleNodes do (
    local valueText=getAttribute node "value"
    local value=if valueText=="" then undefined else (valueText as float)
    local rule=AT_CoordinationRule ruleId:(getAttribute node "ruleId") disciplineA:(getAttribute node "disciplineA") disciplineB:(getAttribute node "disciplineB") checkType:(getAttribute node "checkType") value:value unit:(getAttribute node "unit") severity:(getAttribute node "severity") sourceType:(getAttribute node "sourceType") sourceName:(getAttribute node "sourceName") revision:(getAttribute node "revision") jurisdiction:(getAttribute node "jurisdiction") approved:((toLower (getAttribute node "approved"))=="true") mandatory:((toLower (getAttribute node "mandatory"))=="true") effectiveDate:(getAttribute node "effectiveDate") notes:(getAttribute node "notes")
    for existing in loadedRules where existing.ruleId==rule.ruleId do throw ("DUPLICATE_STORED_RULE_"+rule.ruleId)
    append loadedRules rule
   )
   local loadedChecks=#()
   local checkNodes=xml.SelectNodes "/AskerToolsCoordinationProject/RequiredCheckTypes/Check"
   for node in checkNodes do append loadedChecks (getAttribute node "type")
   local loadedMappings=#()
   local mappingNodes=xml.SelectNodes "/AskerToolsCoordinationProject/DisciplineMappings/Mapping"
   for node in mappingNodes do (
    local mapping=AT_DisciplineMapping matchKind:(getAttribute node "matchKind") matchValue:(getAttribute node "matchValue") discipline:(getAttribute node "discipline") elementType:(getAttribute node "elementType") sourceLabel:(getAttribute node "sourceLabel") revision:(getAttribute node "revision")
    if (findItem #("USER_PROPERTY","LAYER","CLASS","NODE_NAME") mapping.matchKind)==0 or mapping.matchValue=="" or not AT_DisciplineAdapter.validDiscipline mapping.discipline then throw "INVALID_STORED_DISCIPLINE_MAPPING"
    for existing in loadedMappings where existing.matchKind==mapping.matchKind and existing.matchValue==mapping.matchValue do throw "DUPLICATE_STORED_DISCIPLINE_MAPPING"
    append loadedMappings mapping
   )
   local loadedOverrides=#()
   local overrideNodes=xml.SelectNodes "/AskerToolsCoordinationProject/DisciplineEnvelopeOverrides/Element"
   for node in overrideNodes do (
    local clearanceText=getAttribute node "requiredClearance"
    local clearance=if clearanceText=="" then undefined else (clearanceText as float)
    local elementId=getAttribute node "elementId"
    if elementId=="" then throw "INVALID_STORED_DISCIPLINE_OVERRIDE_ID"
    if clearance!=undefined and clearance<0 then throw "INVALID_STORED_DISCIPLINE_CLEARANCE"
    for existing in loadedOverrides where existing.elementId==elementId do throw "DUPLICATE_STORED_DISCIPLINE_OVERRIDE"
    append loadedOverrides (AT_DisciplineEnvelopeOverride elementId:(getAttribute node "elementId") requiredClearance:clearance serviceEnvelope:(getAttribute node "serviceEnvelope") installationEnvelope:(getAttribute node "installationEnvelope"))
   )
   local loadedTracking=#()
   local trackingNodes=xml.SelectNodes "/AskerToolsCoordinationProject/ClashTracking/Clash"
   for node in trackingNodes do (
    local status=getAttribute node "status"
    local clashId=getAttribute node "clashId"
    if clashId=="" or (findItem #("OPEN","IN_PROGRESS","UNDER_REVIEW","RESOLVED","WONT_FIX") status)==0 then throw "INVALID_STORED_CLASH_TRACKING"
    for existing in loadedTracking where existing.clashId==clashId do throw ("DUPLICATE_STORED_CLASH_TRACKING_"+clashId)
    append loadedTracking (AT_ClashTrackingRecord clashId:clashId owner:(getAttribute node "owner") status:status dueDate:(getAttribute node "dueDate") note:(getAttribute node "note") severity:(getAttribute node "severity"))
   )
   local loadedIntegrationTokens=#()
   local integrationNodes=xml.SelectNodes "/AskerToolsCoordinationProject/IntegrationStates/Integration"
   for node in integrationNodes do (
    local id=getAttribute node "integrationId"
    local revision=getAttribute node "revision"
    if id=="" or revision=="" then throw "INVALID_STORED_INTEGRATION_STATE"
    append loadedIntegrationTokens #(id,getAttribute node "moduleName",revision,getAttribute node "lastSyncToken",(toLower (getAttribute node "enabled"))=="true")
   )
   local loadedSyncHistory=#()
   local syncNodes=xml.SelectNodes "/AskerToolsCoordinationProject/IntegrationHistory/Event"
   for node in syncNodes do append loadedSyncHistory #((getAttribute node "type"),(getAttribute node "data"))
   local loadedAudit=#()
   local auditNodes=xml.SelectNodes "/AskerToolsCoordinationProject/GovernanceAudit/Event"
   for node in auditNodes do append loadedAudit #((getAttribute node "type"),(getAttribute node "data"))
   AT_RuleEngine.rules=#()
   for rule in loadedRules do if not AT_RuleEngine.registerRule rule then throw ("INVALID_STORED_RULE_"+rule.ruleId)
   if not AT_RuleEngine.setRequiredCheckTypes loadedChecks then throw "INVALID_STORED_REQUIRED_CHECKS"
   AT_ClashManager.tracking=loadedTracking
   AT_DisciplineAdapter.mappings=loadedMappings
   AT_DisciplineAdapter.envelopeOverrides=loadedOverrides
   AT_DisciplineAdapter.mappingRevision+=1
   AT_DisciplineAdapter.metadataRevision+=1
   AT_CoordinationIntegrations.syncHistory=loadedSyncHistory
   pendingIntegrationTokens=loadedIntegrationTokens
   for record in AT_CoordinationIntegrations.registry do (
    local restored=restoreIntegrationToken record.integrationId record.revision
    if restored!=undefined then record.lastSyncToken=restored
   )
   AT_CoordinationGovernance.auditLog=loadedAudit
   AT_CoordinationGovernance.approvals=#()
   AT_CoordinationGovernance.transactions=#()
   AT_ClashManager.clashes=#()
   AT_ClashManager.lastSimulations=#()
   AT_ClashManager.lastSimulationCandidates=#()
   AT_ClashManager.lastSimulationResults=#()
   AT_ClashManager.lastPairClearances=#()
   AT_ClashManager.lastRuleMissingPairs=#()
   AT_ClashManager.lastScanRuleRevision=-1
   AT_ClashManager.lastScanJurisdiction=""
   AT_ClashManager.lastScanRequiredChecks=#()
   AT_ClashManager.lastDisciplineMappingRevision=-1
   AT_ClashManager.lastDisciplineMetadataRevision=-1
   AT_ClashManager.lastDisciplineInventory=#()
   AT_ClashManager.lastScanMeshes=#()
   AT_DisciplineAdapter.clear()
   AT_CoordinationSolutionGenerator.clear()
   AT_SolutionEngine.clearResults()
   AT_CoordinationSimulation.clear()
   lastPath=path; lastErrors=#()
   true
  ) catch (
   AT_RuleEngine.rules=oldRules
   AT_RuleEngine.registryRevision=oldRuleRevision
   AT_RuleEngine.requiredCheckTypes=oldChecks
   AT_ClashManager.tracking=oldTracking
   AT_DisciplineAdapter.mappings=oldMappings
   AT_DisciplineAdapter.mappingRevision=oldMappingRevision
   AT_DisciplineAdapter.envelopeOverrides=oldOverrides
   AT_DisciplineAdapter.metadataRevision=oldMetadataRevision
   pendingIntegrationTokens=oldPendingIntegrationTokens
   append lastErrors #(path,getCurrentException())
   false
  )
 ),
 fn clearErrors = (lastErrors=#(); true)
)
AT_CoordinationProjectStore=AT_CoordinationProjectStoreStruct()
