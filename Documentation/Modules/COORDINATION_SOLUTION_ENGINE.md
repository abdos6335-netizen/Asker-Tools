# AT Coordination Solution Engine (foundation 0.1.0)

## Purpose
The engine evaluates and ranks proposed resolutions supplied by the Coordination & Clash Detection Engine. It is deterministic and advisory: it does not modify scene geometry, move elements, waive code requirements, or approve engineering changes.

## Proposal contract
Each proposal contains:
- Stable proposal ID and human-readable description.
- Number of clashes it resolves.
- Number of new clashes it introduces.
- Count of critical rule violations.
- Count of required rules that are missing.
- A normalized risk value (0 or greater).
- Number of affected elements.
- Whether engineering approval is required.

The geometry/clash engine is responsible for calculating these facts from validated project data. The solution evaluator must not infer dimensions, clearances, code requirements, or physical feasibility.

## Eligibility gates
A proposal is ineligible when:
- Its input schema is invalid.
- It introduces one or more new clashes.
- It violates a critical rule.
- A required rule is missing.

An ineligible proposal remains visible in results with reasons; it is not silently discarded. Engineering approval is explicitly surfaced as a reason and never treated as automatic authorization.

## Deterministic ranking
Eligible proposals receive a score:

score = resolvedClashes × resolvedWeight - newClashes × newClashWeight - risk × riskWeight - affectedElements × affectedWeight

Default weights are 100, 200, 20, and 2 respectively. These are prioritization weights, not engineering limits or code values. Projects may replace them using setWeights. Equal scores are ordered by stable proposal ID, so identical inputs produce identical ordering.

## API
- AT_SolutionEngine.validateProposal proposal
- AT_SolutionEngine.evaluateProposal proposal
- AT_SolutionEngine.evaluate proposals
- AT_SolutionEngine.setWeights resolvedWeight newClashWeight riskWeight affectedWeight
- AT_SolutionEngine.clearResults()

evaluate returns result structs with proposal ID, description, eligibility, score, rank, and reason codes.

## Safety and integration boundary
- The evaluator is read-only.
- It does not apply any proposal.
- It does not bypass the approved source hierarchy or mandatory codes.
- Missing rule data blocks eligibility rather than substituting guessed values.
- Critical violations block eligibility.
- A future Resolution Workspace must require explicit user approval and use the Sync Engine's transaction/rollback mechanism before applying a chosen proposal.
- Proposal generation, 3D clash calculation, geometry preview, and automatic model edits are not part of this foundation milestone.

## Validation
Static validation checks required API markers and balanced delimiters. MAXScript execution and 3ds Max UI/runtime behavior remain unverified until tested inside supported 3ds Max installations.
