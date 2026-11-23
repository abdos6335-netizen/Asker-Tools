# AT Coordination Solution Engine (foundation 0.2.0)

## Purpose
Builds structured resolution proposals from action candidates supplied by discipline-specific coordination adapters, then deterministically evaluates and ranks them. It is advisory and read-only: it does not move scene geometry, waive requirements, or approve engineering changes.

## Candidate input contract
Each `AT_CoordinationActionCandidate` includes:
- Stable action ID and description.
- Target clash IDs and the clash IDs the action is predicted to resolve.
- Predicted newly introduced clash IDs.
- Critical rule violation IDs and missing required rule IDs.
- Affected element IDs and a normalized non-negative risk score.
- Engineering approval flag.
- `simulationValidated`: true only after a geometry/rules simulation has completed successfully.

Resolved clash IDs must be a subset of target clash IDs. Candidate IDs must be unique. Duplicate or malformed candidates are retained in `lastRejectedCandidates` with reason codes; they are not silently accepted.

## Proposal generation
- `generateProposals candidates` converts candidate records into proposals and derives unique counts from their ID arrays.
- `generateAndRank candidates` generates proposals and immediately evaluates/ranks them.
- Unvalidated candidates remain visible as proposals but are ineligible with `SIMULATION_NOT_VALIDATED`.
- Candidate generation does not invent offsets, clearances, code requirements, or geometry changes. A discipline-specific adapter must produce candidate actions and supply measured simulation results.

## Eligibility gates
A proposal is ineligible when:
- Its input schema is invalid.
- Its simulation has not been validated.
- It introduces one or more new clashes.
- It violates a critical rule.
- A required rule is missing.

Ineligible proposals remain visible with reason codes. Engineering approval is explicitly surfaced and is never treated as automatic authorization.

## Deterministic ranking
Eligible proposals receive:

`score = resolvedClashes × resolvedWeight - newClashes × newClashWeight - risk × riskWeight - affectedElements × affectedWeight`

Default weights are 100, 200, 20, and 2. These are prioritization weights, not engineering limits or code values. Projects may replace them using `setWeights`. Equal scores are ordered by stable proposal ID.

## API
- `AT_SolutionEngine.validateCandidate candidate`
- `AT_SolutionEngine.buildProposal candidate`
- `AT_SolutionEngine.generateProposals candidates`
- `AT_SolutionEngine.validateProposal proposal`
- `AT_SolutionEngine.evaluateProposal proposal`
- `AT_SolutionEngine.evaluate proposals`
- `AT_SolutionEngine.generateAndRank candidates`
- `AT_SolutionEngine.setWeights resolvedWeight newClashWeight riskWeight affectedWeight`
- `AT_SolutionEngine.clearResults()`

Results expose eligibility, score, rank, approval requirement, and reason codes. `lastRejectedCandidates` stores rejected input records and their validation reasons.

## Safety and integration boundary
- The evaluator is read-only; it never applies proposals.
- It does not bypass mandatory codes or approved source hierarchy.
- Missing rule data blocks eligibility; no guessed value is substituted.
- Critical violations and newly introduced clashes block eligibility.
- Engineering approval remains mandatory where flagged.
- A future Resolution Workspace must require explicit approval and use the Sync Engine transaction/rollback mechanism before applying a chosen proposal.
- This milestone does not yet include 3D clash calculation, discipline-specific geometry simulation, automatic movement generation, visual preview, or model edit/rollback integration. Those require adapters connected to the actual 3ds Max scene and validated rule library.

## Validation
Static checks verify required files, API markers, and balanced delimiters. MAXScript runtime behavior remains unverified until executed in supported 3ds Max installations.


## Read-only 3ds Max geometry adapter (0.1.0)

`Modules/Coordination/AT_CoordinationGeometryAdapter.ms` adds a first scene-connected milestone:

- `inspect` reads world-space node bounding boxes using the node transform. It is read-only and does not clone or move scene nodes.
- `detectClashes` reports broad-phase axis-aligned bounding-box (AABB) overlaps with stable IDs derived from 3ds Max node handles.
- `generateMoveCandidates` derives six axis-aligned translation candidates for each side of each detected pair. The requested clearance defaults to zero; callers must supply a project-approved clearance when one is required.
- Each candidate is checked against the other inventoried AABBs. The adapter records target overlaps resolved and new AABB overlaps introduced.
- `toProposalCandidates` maps these candidates into the proposal engine input contract, but always sets `simulationValidated = false`. The existing evaluator therefore keeps them ineligible.

### Important geometric boundary

This is a broad-phase bounding-box engine, not an exact mesh/solid intersection engine. Rotated, concave, hollow, nested, or irregular geometry can produce false positives; a clean AABB result is not proof of physical clearance. The adapter does not calculate discipline-specific service envelopes, code compliance, structural feasibility, access/maintenance clearances, or manufacturer constraints. It never applies a transform. No candidate may be promoted to a validated/approvable proposal until an exact geometry and approved-rules simulation adapter is implemented and tested in 3ds Max.

### API

- `AT_CoordinationGeometryAdapter.inspect nodes:<array> includeHidden:false` (omit nodes to inspect scene objects)
- `AT_CoordinationGeometryAdapter.detectClashes records:<array>`
- `AT_CoordinationGeometryAdapter.generateMoveCandidates records:<array> clashes:<array> clearance:<number>`
- `AT_CoordinationGeometryAdapter.toProposalCandidates()`
- `AT_CoordinationGeometryAdapter.clear()`

`clearance` is a geometric offset input, not a code value. The adapter does not invent one.
