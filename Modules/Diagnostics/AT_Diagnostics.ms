/* Built-in environment diagnostics module. */
global AT_Diagnostics
struct AT_DiagnosticsStruct (
    fn run = (
        local report = #()
        append report #( "3ds Max version", (maxVersion() as string) )
        append report #( "Asker Tools", AT_Core.version )
        append report #( "User scripts", getDir #userScripts )
        append report #( "Current renderer class", (try ((classOf renderers.current) as string) catch ("Unavailable")) )
        append report #( "Loaded modules", (AT_Core.modules as string) )
        for item in report do format "%: %\\n" item[1] item[2]
        report
    )
)
AT_Diagnostics = AT_DiagnosticsStruct()
