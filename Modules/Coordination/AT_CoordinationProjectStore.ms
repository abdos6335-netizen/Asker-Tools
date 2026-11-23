/* Asker Tools - Coordination Project Store
   XML persistence for project rules, required checks, clash tracking, sync history and audit events.
   Approval objects are intentionally not restored as active approvals after reopening a project.
*/
global AT_CoordinationProjectStore
struct AT_CoordinationProjectStoreStruct (
 version="0.1.0", lastPath="", lastErrors=#(),
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
   local trackingNode=addChild xml root "ClashTracking"
   for record in AT_ClashManager.tracking do writeTracking xml trackingNode record
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
  local oldChecks=AT_RuleEngine.requiredCheckTypes
  local oldTracking=AT_ClashManager.tracking
  local xml=undefined
  try (
   xml=dotNetObject "System.Xml.XmlDocument"
   xml.Load path
   if (xml.DocumentElement.Name as string)!="AskerToolsCoordinationProject" then throw "INVALID_PROJECT_STORE_ROOT"
   local loadedRules=#()
   local ruleNodes=xml.SelectNodes "/AskerToolsCoordinationProject/Rules/Rule"
   for node in ruleNodes do (
    local valueText=getAttribute node "value"
    local value=if valueText=="" then undefined else (valueText as float)
    local rule=AT_CoordinationRule ruleId:(getAttribute node "ruleId") disciplineA:(getAttribute node "disciplineA") disciplineB:(getAttribute node "disciplineB") checkType:(getAttribute node "checkType") value:value unit:(getAttribute node "unit") severity:(getAttribute node "severity") sourceType:(getAttribute node "sourceType") sourceName:(getAttribute node "sourceName") revision:(getAttribute node "revision") jurisdiction:(getAttribute node "jurisdiction") approved:((toLower (getAttribute node "approved"))=="true") mandatory:((toLower (getAttribute node "mandatory"))=="true") effectiveDate:(getAttribute node "effectiveDate") notes:(getAttribute node "notes")
    append loadedRules rule
   )
   local loadedChecks=#()
   local checkNodes=xml.SelectNodes "/AskerToolsCoordinationProject/RequiredCheckTypes/Check"
   for node in checkNodes do append loadedChecks (getAttribute node "type")
   local loadedTracking=#()
   local trackingNodes=xml.SelectNodes "/AskerToolsCoordinationProject/ClashTracking/Clash"
   for node in trackingNodes do append loadedTracking (AT_ClashTrackingRecord clashId:(getAttribute node "clashId") owner:(getAttribute node "owner") status:(getAttribute node "status") dueDate:(getAttribute node "dueDate") note:(getAttribute node "note") severity:(getAttribute node "severity"))
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
   AT_CoordinationIntegrations.syncHistory=loadedSyncHistory
   AT_CoordinationGovernance.auditLog=loadedAudit
   AT_CoordinationGovernance.approvals=#()
   AT_CoordinationGovernance.transactions=#()
   AT_ClashManager.clashes=#()
   AT_ClashManager.lastSimulations=#()
   AT_ClashManager.lastSimulationCandidates=#()
   AT_ClashManager.lastSimulationResults=#()
   AT_CoordinationSolutionGenerator.clear()
   AT_SolutionEngine.clearResults()
   AT_CoordinationSimulation.clear()
   lastPath=path; lastErrors=#()
   true
  ) catch (
   AT_RuleEngine.rules=oldRules
   AT_RuleEngine.requiredCheckTypes=oldChecks
   AT_ClashManager.tracking=oldTracking
   append lastErrors #(path,getCurrentException())
   false
  )
 ),
 fn clearErrors = (lastErrors=#(); true)
)
AT_CoordinationProjectStore=AT_CoordinationProjectStoreStruct()
