/* Asker Tools - Coordination Integration Contracts
   Explicit registration and revision-aware exchange points for design modules.
*/
global AT_CoordinationIntegrations
struct AT_CoordinationIntegrationRecord (
 integrationId="", moduleName="", revision="", provider=undefined,
 capabilities=#(), enabled=false, lastSyncToken="", lastError=""
)
struct AT_CoordinationIntegrationsStruct (
 version="0.1.0", registry=#(), syncHistory=#(), lastErrors=#(),
 fn register moduleName revision provider capabilities:#() = (
  if moduleName=="" or revision=="" or provider==undefined then return false
  local id="AT_INT_"+moduleName
  local rec=AT_CoordinationIntegrationRecord integrationId:id moduleName:moduleName revision:revision provider:provider capabilities:capabilities enabled:true
  local existing=undefined
  for r in registry where r.integrationId==id do existing=r
  if existing!=undefined then (local idx=findItem registry existing; deleteItem registry idx)
  append registry rec
  append syncHistory #("REGISTERED",id,revision)
  true
 ),
 fn unregister integrationId = (
  for i=registry.count to 1 by -1 where registry[i].integrationId==integrationId do deleteItem registry i
  append syncHistory #("UNREGISTERED",integrationId)
  true
 ),
 fn get integrationId = (for r in registry where r.integrationId==integrationId do return r; undefined),
 fn exchange integrationId operation payload sourceRevision = (
  local rec=get integrationId
  if rec==undefined or not rec.enabled then return #(#"INTEGRATION_UNAVAILABLE",undefined)
  if sourceRevision=="" then return #(#"SOURCE_REVISION_REQUIRED",undefined)
  if (findItem rec.capabilities operation)==0 then return #(#"CAPABILITY_NOT_SUPPORTED",undefined)
  try (
   local response=rec.provider operation payload sourceRevision
   rec.lastSyncToken=sourceRevision; rec.lastError=""
   append syncHistory #("EXCHANGE_OK",integrationId,operation,sourceRevision)
   #(#"OK",response)
  ) catch (
   rec.lastError=getCurrentException()
   append lastErrors #(integrationId,operation,rec.lastError)
   append syncHistory #("EXCHANGE_FAILED",integrationId,operation,sourceRevision)
   #(#"FAILED",rec.lastError)
  )
 ),
 fn list = (registry),
 fn clearHistory = (syncHistory=#(); lastErrors=#(); true)
)
AT_CoordinationIntegrations=AT_CoordinationIntegrationsStruct()
