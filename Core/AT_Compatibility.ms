/* Version capability checks. 2027 is intentionally marked unverified. */
global AT_Compatibility
struct AT_CompatibilityStruct (
    versionCode = 0,
    maxYear = 0,
    status = #unknown,
    fn check = (
        try (
            local versionParts = maxVersion()
            versionCode = versionParts[1]
            maxYear = 1998 + ((versionCode / 1000) as integer)
            if maxYear >= 2022 and maxYear <= 2026 then status = #supported
            else if maxYear == 2027 then status = #pendingValidation
            else status = #outsideTarget
        ) catch (status = #detectionFailed)
        case status of (
            #supported: AT_Logger.info ("3ds Max " + (maxYear as string) + " detected")
            #pendingValidation: AT_Logger.warn "3ds Max 2027 detected: compatibility pending validation"
            #outsideTarget: AT_Logger.warn ("3ds Max year outside validated target: " + (maxYear as string))
            default: AT_Logger.error "Could not detect 3ds Max version"
        )
        status
    )
)
AT_Compatibility = AT_CompatibilityStruct()
