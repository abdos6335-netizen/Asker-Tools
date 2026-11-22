/* Asker Tools Core - MAXScript */
global AT_Core
struct AT_CoreStruct (
    version = "0.2.0",
    root = "",
    modules = #(),
    fn initRoot = (
        root = getDir #userScripts + "\\AskerTools"
        if not doesFileExist root do makeDir root
        root
    ),
    fn loadCoreFile relativePath = (
        local p = root + "\\" + relativePath
        if doesFileExist p then (fileIn p; true) else (AT_Logger.error ("Missing core file: " + p); false)
    ),
    fn start = (
        initRoot()
        local coreDir = root + "\\Core"
        if not doesFileExist coreDir do makeDir coreDir
        local loggerPath = coreDir + "\\AT_Logger.ms"
        local settingsPath = coreDir + "\\AT_Settings.ms"
        if doesFileExist loggerPath then fileIn loggerPath
        if doesFileExist settingsPath then fileIn settingsPath
        AT_Logger.info ("Starting Asker Tools " + version)
        AT_Settings.load()
        local compatPath = coreDir + "\\AT_Compatibility.ms"
        if doesFileExist compatPath then fileIn compatPath
        AT_Compatibility.check()
        if AT_Settings.autoLoadModules then loadModules() else AT_Logger.info "Automatic module loading is disabled in settings"
        AT_Logger.info "Startup completed"
        true
    ),
    fn loadModules = (
        local moduleRoot = root + "\\Modules"
        if not doesFileExist moduleRoot do makeDir moduleRoot
        local moduleFiles = getFiles (moduleRoot + "\\*\\*.ms")
        for f in moduleFiles do (
            try (
                fileIn f
                appendIfUnique modules (getFilenameFile f)
                AT_Logger.info ("Loaded module: " + f)
            ) catch (AT_Logger.error ("Module load failed: " + f + " | " + getCurrentException()))
        )
        modules
    )
)
AT_Core = AT_CoreStruct()
