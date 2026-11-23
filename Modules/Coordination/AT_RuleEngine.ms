/* Asker Tools - Engineering Coordination Rule Engine
   Source hierarchy is explicit. Missing approved rules never receive guessed values.
*/
global AT_RuleEngine
struct AT_CoordinationRule (
    ruleId="", disciplineA="*", disciplineB="*", checkType="",
    value=undefined, unit="", severity="INFORMATION",
    sourceType="", sourceName="", revision="", jurisdiction="",
    approved=false, mandatory=false, effectiveDate="", notes=""
)
struct AT_RuleEvaluation (
    status="RULE_MISSING", ruleId="", checkType="", value=undefined, unit="", valueInSystemUnits=undefined, unitConversionValid=false,
    severity="INFORMATION", sourceType="", sourceName="",
    reason="NO_APPROVED_RULE", blocking=true
)
struct AT_RuleEngineStruct (
    version="0.2.0", rules=#(), requiredCheckTypes=#(), lastEvaluations=#(), lastErrors=#(),
    sourcePriority=#("MANDATORY_CODE","AUTHORITY_APPROVAL","MANUFACTURER_SPEC","PROJECT_SPEC","ASKER_DEFAULT"),
    supportedDisciplines=#("ARCHITECTURE","STRUCTURE","ELECTRICAL","HVAC","FIRE_FIGHTING","PLUMBING","LOW_CURRENT","INTERIOR_ELEMENTS"),
    validSeverities=#("CRITICAL","HIGH","MEDIUM","LOW","INFORMATION"),
    fn validDiscipline value = (value=="*" or findItem supportedDisciplines (toUpper value)>0),
    fn validSeverity value = (findItem validSeverities (toUpper value)>0),
    fn validSource source = (findItem sourcePriority (toUpper source)>0),
    fn priority source = (findItem sourcePriority (toUpper source)),
    fn registerRule rule = (
        if classOf rule!=AT_CoordinationRule then return false
        if rule.ruleId=="" or rule.checkType=="" or rule.sourceName=="" or not validSource rule.sourceType then return false
        if not validDiscipline rule.disciplineA or not validDiscipline rule.disciplineB or not validSeverity rule.severity then return false
        if classOf rule.value!=Integer and classOf rule.value!=Float and rule.value!=undefined then return false
        if rule.value!=undefined and (rule.value<0 or rule.unit=="") then return false
        for i=rules.count to 1 by -1 where rules[i].ruleId==rule.ruleId do deleteItem rules i
        append rules rule
        true
    ),
    fn removeRule ruleId = (
        local removed=false
        for i=rules.count to 1 by -1 where rules[i].ruleId==ruleId do (deleteItem rules i; removed=true)
        removed
    ),
    fn specificity rule jurisdiction = ((if rule.disciplineA=="*" then 0 else 1)+(if rule.disciplineB=="*" then 0 else 1))*2+(if rule.jurisdiction!="" and rule.jurisdiction==jurisdiction then 1 else 0),
    fn pairMatches rule dA dB = (
        ((rule.disciplineA=="*" or rule.disciplineA==dA) and (rule.disciplineB=="*" or rule.disciplineB==dB)) or
        ((rule.disciplineA=="*" or rule.disciplineA==dB) and (rule.disciplineB=="*" or rule.disciplineB==dA))
    ),
    fn evaluate dA dB checkType jurisdiction:"" = (
        local candidates=#()
        for r in rules where r.checkType==checkType and pairMatches r dA dB and
            (r.jurisdiction=="" or (jurisdiction!="" and r.jurisdiction==jurisdiction)) do append candidates r
        if candidates.count==0 then (
            local missing=AT_RuleEvaluation checkType:checkType reason:"NO_RULE_REGISTERED"
            append lastEvaluations missing
            return missing
        )
        local highestPriority=999
        for r in candidates do highestPriority=amin highestPriority (priority r.sourceType)
        local highestSourceRules=#()
        for r in candidates where priority r.sourceType==highestPriority do append highestSourceRules r
        local bestSpecificity=-1
        for r in highestSourceRules do bestSpecificity=amax bestSpecificity (specificity r jurisdiction)
        local bestSourceRules=#()
        for r in highestSourceRules where (specificity r jurisdiction)==bestSpecificity do append bestSourceRules r
        local unapprovedBest=#()
        for r in bestSourceRules where not r.approved do append unapprovedBest r
        if unapprovedBest.count>0 then (
            local missing=AT_RuleEvaluation checkType:checkType
            missing.reason="HIGHEST_PRIORITY_RULE_NOT_APPROVED"
            missing.sourceType=unapprovedBest[1].sourceType
            missing.sourceName=unapprovedBest[1].sourceName
            missing.ruleId=unapprovedBest[1].ruleId
            append lastEvaluations missing
            return missing
        )
        local approvedHighest=#()
        for r in bestSourceRules where r.approved do append approvedHighest r
        local bestRules=approvedHighest
        if bestRules.count>1 then (
            local first=bestRules[1]
            local conflict=false
            for r in bestRules where r.value!=first.value or r.unit!=first.unit or r.severity!=first.severity or r.mandatory!=first.mandatory do conflict=true
            if conflict then (
                local ambiguous=AT_RuleEvaluation checkType:checkType
                ambiguous.reason="CONFLICTING_SAME_PRIORITY_RULES"
                ambiguous.sourceType=first.sourceType
                ambiguous.sourceName=first.sourceName
                ambiguous.ruleId=first.ruleId
                append lastEvaluations ambiguous
                return ambiguous
            )
        )
        local selected=bestRules[1]
        for r in bestRules where r.ruleId < selected.ruleId do selected=r
        local result=AT_RuleEvaluation status:"RULE_FOUND" ruleId:selected.ruleId checkType:selected.checkType value:selected.value unit:selected.unit severity:selected.severity sourceType:selected.sourceType sourceName:selected.sourceName reason:"APPROVED_RULE_SELECTED" blocking:false
        if (findItem #("CLEARANCE","MIN_CLEARANCE","SERVICE_CLEARANCE","INSTALLATION_CLEARANCE") (toUpper selected.checkType))>0 then (
            if selected.value==undefined then (
                result.status="RULE_MISSING"; result.reason="CLEARANCE_VALUE_REQUIRED"; result.blocking=true
            ) else (
                local conversion=AT_UnitConversionEngine.toSystemUnits selected.value selected.unit
                if conversion.valid then (result.valueInSystemUnits=conversion.systemValue; result.unitConversionValid=true)
                else (result.status="RULE_MISSING"; result.reason=conversion.reason; result.blocking=true)
            )
        )
        append lastEvaluations result
        result
    ),
    fn setRequiredCheckTypes checkTypes = (
        local validated=#()
        for checkType in checkTypes do (
            if classOf checkType!=String or checkType=="" then return false
            appendIfUnique validated checkType
        )
        requiredCheckTypes=validated
        true
    ),
    fn evaluateClash clash checkTypes:undefined jurisdiction:"" = (
        local requestedChecks=if checkTypes==undefined then requiredCheckTypes else checkTypes
        if requestedChecks.count==0 then (
            local missing=AT_RuleEvaluation reason:"REQUIRED_CHECK_TYPES_NOT_CONFIGURED"
            append lastEvaluations missing
            return #(missing)
        )
        if clash.disciplineA=="UNKNOWN" or clash.disciplineB=="UNKNOWN" then (
            local missing=AT_RuleEvaluation checkType:requestedChecks[1] reason:"DISCIPLINE_CLASSIFICATION_REQUIRED"
            append lastEvaluations missing
            return #(missing)
        )
        local results=#()
        for checkType in requestedChecks do append results (evaluate clash.disciplineA clash.disciplineB checkType jurisdiction:jurisdiction)
        results
    ),
    fn evaluateBatch checks = (
        local results=#()
        for c in checks do append results (evaluate c[1] c[2] c[3] jurisdiction:(if c.count>=4 then c[4] else ""))
        results
    ),
    fn clearEvaluations = (lastEvaluations=#(); lastErrors=#(); true),
    fn clearAll = (rules=#(); requiredCheckTypes=#(); clearEvaluations(); true)
)
AT_RuleEngine=AT_RuleEngineStruct()
