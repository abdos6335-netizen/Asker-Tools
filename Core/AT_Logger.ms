/* Lightweight file logger. */
global AT_Logger
struct AT_LoggerStruct (
    logFile = "",
    fn init = (
        local folder = getDir #userScripts + "\\AskerTools\\Logs"
        if not doesFileExist folder do makeDir folder
        logFile = folder + "\\AskerTools.log"
        logFile
    ),
    fn write level message = (
        if logFile == "" do init()
        local stamp = (localTime as string)
        local line = "[" + stamp + "][" + level + "] " + message + "\\n"
        try (local stream = openFile logFile mode:"a"; format "%" line to:stream; close stream) catch()
        line
    ),
    fn info message = (write "INFO" message),
    fn warn message = (write "WARN" message),
    fn error message = (write "ERROR" message)
)
AT_Logger = AT_LoggerStruct()
AT_Logger.init()
