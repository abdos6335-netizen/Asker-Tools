/* Persistent INI settings with safe defaults. */
global AT_Settings
struct AT_SettingsStruct (
    iniFile = "",
    language = "en",
    autoLoadModules = true,
    showStartupReport = true,
    fn init = (
        local folder = getDir #userScripts + "\\AskerTools\\Config"
        if not doesFileExist folder do makeDir folder
        iniFile = folder + "\\settings.ini"
    ),
    fn load = (
        if iniFile == "" do init()
        if doesFileExist iniFile then (
            language = getIniSetting iniFile "General" "Language"
            if language == "" do language = "en"
            local autoValue = getIniSetting iniFile "General" "AutoLoadModules"
            autoLoadModules = (toLower autoValue == "true" or autoValue == "")
            local reportValue = getIniSetting iniFile "General" "ShowStartupReport"
            showStartupReport = (toLower reportValue != "false")
        ) else save()
        true
    ),
    fn save = (
        if iniFile == "" do init()
        setIniSetting iniFile "General" "Language" language
        setIniSetting iniFile "General" "AutoLoadModules" (autoLoadModules as string)
        setIniSetting iniFile "General" "ShowStartupReport" (showStartupReport as string)
        true
    )
)
AT_Settings = AT_SettingsStruct()
