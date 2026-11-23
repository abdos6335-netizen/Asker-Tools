/* Asker Tools - Discipline Mapping and Envelope Manager UI */
global AT_DisciplineManager
struct AT_DisciplineManagerStruct (
 version="0.1.0",
 fn mappingLabel mapping = (
  mapping.matchKind+" | "+mapping.matchValue+" => "+mapping.discipline+" / "+mapping.elementType+" | "+mapping.sourceLabel+" | "+mapping.revision
 ),
 fn refreshMappings listControl = (listControl.items=for m in AT_DisciplineAdapter.mappings collect (mappingLabel m); true),
 fn refreshInventory listControl = (
  AT_DisciplineAdapter.inspect()
  listControl.items=for e in AT_DisciplineAdapter.lastInventory collect (e.elementId+" | "+e.discipline+" | "+e.nodeName+" | "+e.elementType)
  true
 ),
 fn removeMapping index = (
  if index<1 or index>AT_DisciplineAdapter.mappings.count then return false
  AT_DisciplineAdapter.removeMapping index
 ),
 fn show = (
  try (destroyDialog AT_DisciplineManagerRollout) catch()
  rollout AT_DisciplineManagerRollout "Asker Tools | Discipline Manager" width:720 height:720 (
   group "Explicit element classification mapping" (
    dropdownList ddlMatchKind "Match source" items:#("USER_PROPERTY","LAYER","CLASS","NODE_NAME") width:300
    editText edtMatchValue "Exact match value" text:"" width:300
    dropdownList ddlDiscipline "Discipline" items:#("ARCHITECTURE","STRUCTURE","ELECTRICAL","HVAC","FIRE_FIGHTING","PLUMBING","LOW_CURRENT","INTERIOR_ELEMENTS") width:300
    editText edtElementType "Element type" text:"UNSPECIFIED" width:300
    editText edtSourceLabel "Mapping source" text:"PROJECT_MAPPING" width:300
    editText edtRevision "Mapping revision" text:"" width:300
    button btnRegister "Register / Update Mapping" width:210 height:28
    button btnRemove "Remove Selected Mapping" width:210 height:28
    listbox lbMappings "Registered mappings" items:#() width:680 height:8
   )
   group "Per-element engineering envelopes" (
    button btnRefresh "Refresh Scene Inventory" width:200 height:28
    listbox lbInventory "Scene elements" items:#() width:680 height:12
    editText edtClearance "Required clearance (optional)" text:"" width:300
    dropdownList ddlUnit "Clearance unit" items:#("mm","cm","m","in","ft","system") width:300
    editText edtService "Service envelope reference (optional)" text:"" width:650
    editText edtInstallation "Installation envelope reference (optional)" text:"" width:650
    button btnApplyEnvelope "Apply Envelope to Selected Element" width:260 height:28
   )
   label lblStatus "Unknown elements remain unclassified; no discipline is inferred." align:#left
   on AT_DisciplineManagerRollout open do AT_DisciplineManager.refreshMappings lbMappings
   on btnRegister pressed do (
    local kind=ddlMatchKind.items[amax 1 ddlMatchKind.selection]
    local discipline=ddlDiscipline.items[amax 1 ddlDiscipline.selection]
    local ok=AT_DisciplineAdapter.registerMapping kind edtMatchValue.text discipline elementType:edtElementType.text sourceLabel:edtSourceLabel.text revision:edtRevision.text
    AT_DisciplineManager.refreshMappings lbMappings
    lblStatus.text=if ok then "Discipline mapping registered" else "Mapping rejected; check match type, value and discipline"
   )
   on btnRemove pressed do (
    local ok=AT_DisciplineManager.removeMapping lbMappings.selection
    AT_DisciplineManager.refreshMappings lbMappings
    lblStatus.text=if ok then "Mapping removed" else "Select a mapping"
   )
   on btnRefresh pressed do (
    AT_DisciplineManager.refreshInventory lbInventory
    lblStatus.text=AT_DisciplineAdapter.lastUnclassified.count as string+" elements remain UNKNOWN"
   )
   on btnApplyEnvelope pressed do (
    if lbInventory.selection<1 or lbInventory.selection>AT_DisciplineAdapter.lastInventory.count then lblStatus.text="Select an element first"
    else (
     local required=undefined
     local valid=true
     if edtClearance.text!="" do (
      local raw=undefined
      try (raw=edtClearance.text as float) catch (valid=false)
      if valid then (
       local unit=ddlUnit.items[amax 1 ddlUnit.selection]
       local converted=AT_UnitConversionEngine.toSystemUnits raw unit
       if converted.valid then required=converted.systemValue else valid=false
      )
     )
     if not valid then lblStatus.text="Clearance value/unit is invalid"
     else (
      local elementId=AT_DisciplineAdapter.lastInventory[lbInventory.selection].elementId
      local service=if edtService.text=="" then undefined else edtService.text
      local install=if edtInstallation.text=="" then undefined else edtInstallation.text
      local ok=AT_DisciplineAdapter.setEnvelope elementId requiredClearance:required serviceEnvelope:service installationEnvelope:install
      lblStatus.text=if ok then "Element envelope saved; rescan clashes before simulation" else "Envelope update failed"
     )
    )
   )
  )
  createDialog AT_DisciplineManagerRollout style:#(#style_titlebar,#style_sysmenu,#style_resizing)
 )
)
AT_DisciplineManager=AT_DisciplineManagerStruct()
