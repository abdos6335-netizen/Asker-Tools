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
    fn pairMatches rule dA dB = (
        ((rule.disciplineA=="*" or rule.disciplineA==dA) and (rule.disciplineB=="*" or rule.disciplineB==dB)) or
        ((rule.disciplineA=="*" or rule.disciplineA==dB) and (rule.disciplineB=="*" or rule.disciplineB==dA))
    ),
    fn evaluate dA dB checkType jurisdiction:"" = (
        local candidates=#()
        for r in rules where r.checkType==checkType and pairMatches r dA dB and
            (not r.approved or r.jurisdiction=="" or jurisdiction=="" or r.jurisdiction==jurisdiction) do append candidates r
        local approved=#()
        for r in candidates where r.approved do append approved r
        if approved.count==0 then (
            local missing=AT_RuleEvaluation()
            missing.reason=if candidates.count>0 then "ONLY_UNAPPROVED_RULES_AVAILABLE" else "NO_RULE_REGISTERED"
            append lastEvaluations missing
            return missing
        )
        local selected=approved[1]
        for r in approved where priority r.sourceType < priority selected.sourceType do selected=r
        local result=AT_RuleEvaluation status:"RULE_FOUND" ruleId:selected.ruleId value:selected.value unit:selected.unit severity:selected.severity sourceType:selected.sourceType sourceName:selected.sourceName reason:"APPROVED_RULE_SELECTED" blocking:false
        append lastEvaluations result
        result
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
