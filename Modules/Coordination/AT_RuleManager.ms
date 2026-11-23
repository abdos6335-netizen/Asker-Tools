/* Asker Tools - Coordination Rule Manager UI
   Project-authorized rule entry and explicit required-check configuration.
*/
global AT_RuleManager
struct AT_RuleManagerStruct (
 version="0.1.0",
 fn ruleLabel rule = (
  local valueText=if rule.value==undefined then "n/a" else (rule.value as string)+" "+rule.unit
  rule.ruleId+" | "+rule.sourceType+" | "+rule.disciplineA+"/"+rule.disciplineB+" | "+rule.checkType+" | "+valueText+" | "+(if rule.approved then "APPROVED" else "UNAPPROVED")
 ),
 fn refreshList listControl = (
  listControl.items=for rule in AT_RuleEngine.rules collect (ruleLabel rule)
  true
 ),
 fn addRule ruleId disciplineA disciplineB checkType value unit severity sourceType sourceName revision jurisdiction approved mandatory effectiveDate notes = (
  if ruleId=="" or checkType=="" or sourceName=="" or (value!=undefined and unit=="") then return false
  local rule=AT_CoordinationRule ruleId:ruleId disciplineA:disciplineA disciplineB:disciplineB checkType:checkType value:value unit:unit severity:severity sourceType:sourceType sourceName:sourceName revision:revision jurisdiction:jurisdiction approved:approved mandatory:mandatory effectiveDate:effectiveDate notes:notes
  AT_RuleEngine.registerRule rule
 ),
 fn removeRule index = (
  if index<1 or index>AT_RuleEngine.rules.count then return false
  AT_RuleEngine.removeRule AT_RuleEngine.rules[index].ruleId
 ),
 fn show = (
  try (destroyDialog AT_CoordinationRuleManagerRollout) catch()
  rollout AT_CoordinationRuleManagerRollout "Asker Tools | Coordination Rule Manager" width:720 height:680 (
   group "Rule identity and applicability" (
    editText edtRuleId "Rule ID" text:"" width:300
    dropdownList ddlDisciplineA "Discipline A" items:#("*","ARCHITECTURE","STRUCTURE","ELECTRICAL","HVAC","FIRE_FIGHTING","PLUMBING","LOW_CURRENT","INTERIOR_ELEMENTS") width:300
    dropdownList ddlDisciplineB "Discipline B" items:#("*","ARCHITECTURE","STRUCTURE","ELECTRICAL","HVAC","FIRE_FIGHTING","PLUMBING","LOW_CURRENT","INTERIOR_ELEMENTS") width:300
    editText edtCheckType "Check type" text:"" width:300
    editText edtValue "Numeric value (optional)" text:"" width:300
    editText edtUnit "Unit" text:"" width:150
    dropdownList ddlSeverity "Severity" items:#("CRITICAL","HIGH","MEDIUM","LOW","INFORMATION") width:300
   )
   group "Authority and approval" (
    dropdownList ddlSource "Source hierarchy" items:#("MANDATORY_CODE","AUTHORITY_APPROVAL","MANUFACTURER_SPEC","PROJECT_SPEC","ASKER_DEFAULT") width:300
    editText edtSourceName "Source / authority name" text:"" width:300
    editText edtRevision "Source revision" text:"" width:300
    editText edtJurisdiction "Jurisdiction (exact project key)" text:"" width:300
    editText edtEffectiveDate "Effective date" text:"" width:300
    checkbox chkApproved "Approved / verified source" checked:false
    checkbox chkMandatory "Mandatory requirement" checked:false
    editText edtNotes "Evidence / reference / notes" text:"" width:650
    button btnRegister "Register / Update Rule" width:190 height:28
    button btnRemove "Remove Selected Rule" width:190 height:28
   )
   group "Required project checks" (
    editText edtRequired "Required check types (; separated)" text:"" width:650
    button btnSetRequired "Save Required Check Types" width:220 height:28
   )
   listbox lbRules "Registered rules" items:#() width:680 height:12
   label lblStatus "Rules are project data; values must come from approved sources." align:#left
   on AT_CoordinationRuleManagerRollout open do (
    AT_RuleManager.refreshList lbRules
    local requiredText=""
    for checkType in AT_RuleEngine.requiredCheckTypes do (
     if requiredText!="" then requiredText+=";"
     requiredText+=checkType
    )
    edtRequired.text=requiredText
   )
   on btnRegister pressed do (
    local value=undefined
    local valueValid=true
    if edtValue.text!="" do try (value=edtValue.text as float) catch (valueValid=false)
    if not valueValid then lblStatus.text="Numeric rule value is invalid"
    else (
    local dA=ddlDisciplineA.items[amax 1 ddlDisciplineA.selection]
    local dB=ddlDisciplineB.items[amax 1 ddlDisciplineB.selection]
    local source=ddlSource.items[amax 1 ddlSource.selection]
    local severity=ddlSeverity.items[amax 1 ddlSeverity.selection]
    local ok=AT_RuleManager.addRule edtRuleId.text dA dB edtCheckType.text value edtUnit.text severity source edtSourceName.text edtRevision.text edtJurisdiction.text chkApproved.checked chkMandatory.checked edtEffectiveDate.text edtNotes.text
    AT_RuleManager.refreshList lbRules
    lblStatus.text=if ok then "Rule registered" else "Rule rejected; check ID, type, source and value"
    )
   )
   on btnRemove pressed do (
    local ok=AT_RuleManager.removeRule lbRules.selection
    AT_RuleManager.refreshList lbRules
    lblStatus.text=if ok then "Rule removed" else "Select a rule to remove"
   )
   on btnSetRequired pressed do (
    local checks=filterString edtRequired.text ";"
    local ok=AT_RuleEngine.setRequiredCheckTypes checks
    lblStatus.text=if ok then "Required check types saved" else "Invalid check-type list"
   )
  )
  createDialog AT_CoordinationRuleManagerRollout style:#(#style_titlebar,#style_sysmenu,#style_resizing)
 )
)
AT_RuleManager=AT_RuleManagerStruct()
