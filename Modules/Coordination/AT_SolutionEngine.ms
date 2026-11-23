/* Asker Tools - Coordination Solution & Proposal Engine
   Deterministic advisory evaluation. No scene geometry is modified.
*/
global AT_SolutionEngine
struct AT_CoordinationProposal (
    id = "", description = "", actionType = "TRANSLATE",
    offset = [0,0,0], rotationAxis = [0,0,1], angleDegrees = 0.0, pivot = [0,0,0],
    resolvedClashes = 0, newClashes = 0,
    criticalViolations = 0, missingRules = 0,
    risk = 0.0, affectedElements = 0,
    requiresEngineeringApproval = true,
    simulationValidated = false,
    resolvedClashIds = #(), introducedClashIds = #(),
    affectedElementIds = #(), criticalViolationIds = #(), missingRuleIds = #()
)
struct AT_CoordinationActionCandidate (
    actionId = "", description = "", actionType = "TRANSLATE",
    offset = [0,0,0], rotationAxis = [0,0,1], angleDegrees = 0.0, pivot = [0,0,0],
    targetClashIds = #(), resolvedClashIds = #(),
    introducedClashIds = #(), criticalViolationIds = #(),
    missingRuleIds = #(), affectedElementIds = #(),
    risk = 0.0, requiresEngineeringApproval = true,
    simulationValidated = false
)
struct AT_CoordinationProposalResult (
    proposalId = "", description = "",
    eligible = false, score = -1.0e9, rank = 0,
    requiresApproval = true, reasons = #()
)
struct AT_SolutionEngineStruct (
    version = "0.2.0",
    weights = #(#resolvedClashes, 100.0, #newClashes, 200.0, #risk, 20.0, #affectedElements, 2.0),
    lastResults = #(), lastProposals = #(), lastRejectedCandidates = #(),

    fn validNonNegative value = (
        (classOf value == Integer or classOf value == Float) and value >= 0
    ),

    fn uniqueCount values = (
        local uniqueValues = #()
        for value in values do appendIfUnique uniqueValues value
        uniqueValues.count
    ),

    fn validateCandidate candidate = (
        local issues = #()
        if classOf candidate != AT_CoordinationActionCandidate then
            append issues "INVALID_CANDIDATE_TYPE"
        else (
            if candidate.actionId == "" do append issues "MISSING_ACTION_ID"
            if candidate.targetClashIds.count == 0 do append issues "NO_TARGET_CLASHES"
            if candidate.actionType!="TRANSLATE" and candidate.actionType!="ROTATE" do append issues "UNSUPPORTED_ACTION_TYPE"
            if candidate.actionType=="TRANSLATE" and classOf candidate.offset!=Point3 do append issues "INVALID_TRANSLATION_VECTOR"
            if candidate.actionType=="ROTATE" and (classOf candidate.rotationAxis!=Point3 or classOf candidate.pivot!=Point3 or (classOf candidate.angleDegrees!=Integer and classOf candidate.angleDegrees!=Float) or length candidate.rotationAxis<=1.0e-8 or candidate.angleDegrees==0) do append issues "INVALID_ROTATION_PARAMETERS"
            for resolvedID in candidate.resolvedClashIds where (findItem candidate.targetClashIds resolvedID) == 0 do
                appendIfUnique issues "RESOLVED_CLASH_NOT_IN_TARGET_SET"
            if not validNonNegative candidate.risk do append issues "INVALID_RISK_VALUE"
        )
        issues
    ),

    fn buildProposal candidate = (
        local proposal = AT_CoordinationProposal()
        local issues = validateCandidate candidate
        if issues.count > 0 then return undefined
        proposal.id = candidate.actionId
        proposal.description = candidate.description
        proposal.actionType = candidate.actionType
        proposal.offset = candidate.offset
        proposal.rotationAxis = candidate.rotationAxis
        proposal.angleDegrees = candidate.angleDegrees
        proposal.pivot = candidate.pivot
        proposal.resolvedClashIds = candidate.resolvedClashIds
        proposal.introducedClashIds = candidate.introducedClashIds
        proposal.affectedElementIds = candidate.affectedElementIds
        proposal.criticalViolationIds = candidate.criticalViolationIds
        proposal.missingRuleIds = candidate.missingRuleIds
        proposal.resolvedClashes = uniqueCount candidate.resolvedClashIds
        proposal.newClashes = uniqueCount candidate.introducedClashIds
        proposal.criticalViolations = uniqueCount candidate.criticalViolationIds
        proposal.missingRules = uniqueCount candidate.missingRuleIds
        proposal.affectedElements = uniqueCount candidate.affectedElementIds
        proposal.risk = candidate.risk
        proposal.requiresEngineeringApproval = candidate.requiresEngineeringApproval
        proposal.simulationValidated = candidate.simulationValidated
        proposal
    ),

    fn generateProposals candidates = (
        local proposals = #()
        local seenIds = #()
        lastRejectedCandidates = #()
        for candidate in candidates do (
            local candidateIssues = validateCandidate candidate
            if candidateIssues.count == 0 then (
                if (findItem seenIds candidate.actionId) == 0 then (
                    local proposal = buildProposal candidate
                    if proposal != undefined then (
                        append proposals proposal
                        append seenIds candidate.actionId
                    )
                ) else append lastRejectedCandidates #(candidate.actionId, #("DUPLICATE_ACTION_ID"))
            ) else append lastRejectedCandidates #(candidate.actionId, candidateIssues)
        )
        lastProposals = proposals
        proposals
    ),

    fn validateProposal proposal = (
        local issues = #()
        if classOf proposal != AT_CoordinationProposal then append issues "INVALID_PROPOSAL_TYPE"
        else (
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
        (proposal.resolvedClashes * weights[2]) -
        (proposal.newClashes * weights[4]) -
        (proposal.risk * weights[6]) -
        (proposal.affectedElements * weights[8])
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
            if not proposal.simulationValidated do append result.reasons "SIMULATION_NOT_VALIDATED"
            if proposal.criticalViolations > 0 do append result.reasons "CRITICAL_RULE_VIOLATION"
            if proposal.missingRules > 0 do append result.reasons "REQUIRED_RULE_MISSING"
            if proposal.newClashes > 0 do append result.reasons "INTRODUCES_NEW_CLASHES"
            result.eligible = (proposal.simulationValidated and proposal.criticalViolations == 0 and proposal.missingRules == 0 and proposal.newClashes == 0)
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
            for j = 1 to results.count where j != i do
                if ranksBefore results[j] results[i] do rankValue += 1
            results[i].rank = rankValue
        )
        lastResults = results
        results
    ),

    fn generateAndRank candidates = (
        local proposals = generateProposals candidates
        evaluate proposals
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
        lastProposals = #()
        lastRejectedCandidates = #()
        true
    )
)
AT_SolutionEngine = AT_SolutionEngineStruct()
