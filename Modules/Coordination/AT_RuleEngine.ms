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
    status="RULE_MISSING", ruleId="", value=undefined, unit="",
    severity="INFORMATION", sourceType="", sourceName="",
    reason="NO_APPROVED_RULE", blocking=true
)
struct AT_RuleEngineStruct (
    version="0.1.0", rules=#(), lastEvaluations=#(), lastErrors=#(),
    sourcePriority=#("MANDATORY_CODE","AUTHORITY_APPROVAL","MANUFACTURER_SPEC","PROJECT_SPEC","ASKER_DEFAULT"),
    fn validSource source = (findItem sourcePriority (toUpper source)>0),
    fn priority source = (findItem sourcePriority (toUpper source)),
    fn registerRule rule = (
        if classOf rule!=AT_CoordinationRule then return false
        if rule.ruleId=="" or rule.checkType=="" or not validSource rule.sourceType then return false
        if classOf rule.value!=Integer and classOf rule.value!=Float and rule.value!=undefined then return false
        if rule.value!=undefined and rule.value<0 then return false
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
            local missing=AT_RuleEvaluation reason:"NO_RULE_REGISTERED"
            append lastEvaluations missing
            return missing
        )
        local highestPriority=999
        for r in candidates do highestPriority=amin highestPriority (priority r.sourceType)
        local highestSourceRules=#()
        for r in candidates where priority r.sourceType==highestPriority do append highestSourceRules r
        local approvedHighest=#()
        for r in highestSourceRules where r.approved do append approvedHighest r
        if approvedHighest.count==0 then (
            local missing=AT_RuleEvaluation()
            missing.reason="HIGHEST_PRIORITY_RULE_NOT_APPROVED"
            missing.sourceType=highestSourceRules[1].sourceType
            missing.sourceName=highestSourceRules[1].sourceName
            append lastEvaluations missing
            return missing
        )
        local bestSpecificity=-1
        for r in approvedHighest do bestSpecificity=amax bestSpecificity (specificity r jurisdiction)
        local bestRules=#()
        for r in approvedHighest where specificity r jurisdiction==bestSpecificity do append bestRules r
        if bestRules.count>1 then (
            local first=bestRules[1]
            local conflict=false
            for r in bestRules where r.value!=first.value or r.unit!=first.unit or r.severity!=first.severity or r.mandatory!=first.mandatory do conflict=true
            if conflict then (
                local ambiguous=AT_RuleEvaluation()
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
        local result=AT_RuleEvaluation status:"RULE_FOUND" ruleId:selected.ruleId value:selected.value unit:selected.unit severity:selected.severity sourceType:selected.sourceType sourceName:selected.sourceName reason:"APPROVED_RULE_SELECTED" blocking:false
        append lastEvaluations result
        result
    ),
    fn evaluateClash clash checkTypes jurisdiction:"" = (
        if clash.disciplineA=="UNKNOWN" or clash.disciplineB=="UNKNOWN" then (
            local missing=AT_RuleEvaluation reason:"DISCIPLINE_CLASSIFICATION_REQUIRED"
            append lastEvaluations missing
            return #(missing)
        )
        local results=#()
        for checkType in checkTypes do append results (evaluate clash.disciplineA clash.disciplineB checkType jurisdiction:jurisdiction)
        results
    ),
    fn evaluateBatch checks = (
        local results=#()
        for c in checks do append results (evaluate c[1] c[2] c[3] jurisdiction:(if c.count>=4 then c[4] else ""))
        results
    ),
    fn clearEvaluations = (lastEvaluations=#(); lastErrors=#(); true),
    fn clearAll = (rules=#(); clearEvaluations(); true)
)
AT_RuleEngine=AT_RuleEngineStruct()
