/* Asker Tools launcher. Install the AskerTools folder under #userScripts. */
local installRoot = getDir #userScripts + "\\AskerTools"
local coreEntry = installRoot + "\\Core\\AT_Core.ms"
if doesFileExist coreEntry then (
    fileIn coreEntry
    AT_Core.start()
) else (
    messageBox ("Asker Tools core was not found. Expected:\\n" + coreEntry) title:"Asker Tools - Install Error"
)
