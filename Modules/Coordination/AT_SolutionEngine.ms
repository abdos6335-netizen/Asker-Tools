/* Asker Tools - AT Coordination Solution Engine
   Deterministic, advisory ranking for pre-validated coordination proposals.
   This module does not move scene objects or approve engineering changes.
*/
global AT_SolutionEngine
struct AT_CoordinationProposal (
    id = "",
    description = "",
    resolvedClashes = 0,
    newClashes = 0,
    criticalViolations = 0,
    missingRules = 0,
    risk = 0.0,
    affectedElements = 0,
    requiresEngineeringApproval = true
)
struct AT_CoordinationProposalResult (
    proposalId = "",
    description = "",
    eligible = false,
    score = -1.0e9,
    rank = 0,
    requiresApproval = true,
    reasons = #()
)
struct AT_SolutionEngineStruct (
    version = "0.1.0",
    weights = #(#resolvedClashes, 100.0, #newClashes, 200.0, #risk, 20.0, #affectedElements, 2.0),
    lastResults = #(),

    fn validNonNegative value = (
        (classOf value == Integer or classOf value == Float) and value >= 0
    ),

    fn validateProposal proposal = (
        local issues = #()
        if classOf proposal != AT_CoordinationProposal do append issues "INVALID_PROPOSAL_TYPE"
        if classOf proposal == AT_CoordinationProposal do (
            if proposal.id == "" do append issues "MISSING_PROPOSAL_ID"
            if not validNonNegative proposal.resolvedClashes do append issues "INVALID_RESOLVED_CLASH_COUNT"
            if not validNonNegative proposal.newClashes do append issues "INVALID_NEW_CLASH_COUNT"
            if not validNonNegative proposal.criticalViolations do append issues "INVALID_CRITICAL_VIOLATION_COUNT"
            if not validNonNegative proposal.missingRules do append issues "INVALID_MISSING_RULE_COUNT"
            if not validNonNegative proposal.risk do append issues "INVALID_RISK_VALUE"
            if not validNonNegative proposal.affectedElements do append issues "INVALID_AFFECTED_ELEMENT_COUNT"
        )
        issues
    ),

    fn scoreProposal proposal = (
        local score = (proposal.resolvedClashes * weights[2]) -
                      (proposal.newClashes * weights[4]) -
                      (proposal.risk * weights[6]) -
                      (proposal.affectedElements * weights[8])
        score
    ),

    fn evaluateProposal proposal = (
        local result = AT_CoordinationProposalResult()
        local issues = validateProposal proposal
        if issues.count > 0 then (
            result.eligible = false
            result.reasons = issues
        ) else (
            result.proposalId = proposal.id
            result.description = proposal.description
            result.requiresApproval = proposal.requiresEngineeringApproval
            if proposal.criticalViolations > 0 do append result.reasons "CRITICAL_RULE_VIOLATION"
            if proposal.missingRules > 0 do append result.reasons "REQUIRED_RULE_MISSING"
            if proposal.newClashes > 0 do append result.reasons "INTRODUCES_NEW_CLASHES"
            result.eligible = (proposal.criticalViolations == 0 and proposal.missingRules == 0 and proposal.newClashes == 0)
            result.score = scoreProposal proposal
            if result.requiresApproval do append result.reasons "ENGINEERING_APPROVAL_REQUIRED"
            if not result.eligible do result.score = -1.0e9
        )
        result
    ),

    fn ranksBefore a b = (
        if a.eligible != b.eligible then a.eligible
        else if a.score != b.score then a.score > b.score
        else a.proposalId < b.proposalId
    ),

    fn evaluate proposals = (
        local results = #()
        for proposal in proposals do append results (evaluateProposal proposal)
        for i = 1 to results.count do (
            local rankValue = 1
            for j = 1 to results.count where j != i do (
                if ranksBefore results[j] results[i] do rankValue += 1
            )
            results[i].rank = rankValue
        )
        lastResults = results
        results
    ),

    fn setWeights resolvedWeight newClashWeight riskWeight affectedWeight = (
        if not validNonNegative resolvedWeight or not validNonNegative newClashWeight or
           not validNonNegative riskWeight or not validNonNegative affectedWeight then return false
        weights = #(#resolvedClashes, resolvedWeight, #newClashes, newClashWeight,
                    #risk, riskWeight, #affectedElements, affectedWeight)
        true
    ),

    fn clearResults = (
        lastResults = #()
        true
    )
)
AT_SolutionEngine = AT_SolutionEngineStruct()
