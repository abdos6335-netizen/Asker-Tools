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


## Part 1 — triangle-mesh interference and clearance engine (0.1.0)

AT_ExactGeometryEngine adds a read-only narrow-phase mesh check after a world-AABB broad-phase filter.

- inspect snapshots valid scene nodes to triangle meshes and stores transformed world-space triangles, face indices, and bounds.
- detectClashes checks candidate node pairs and then triangle pairs. Triangle intersection uses a separating-axis test, including coplanar in-plane axes.
- For non-intersecting triangle pairs within the requested distance, minimum surface distance is computed from point-to-triangle and edge-to-edge distances.
- Results distinguish EXACT_MESH_INTERFERENCE, CLEARANCE_VIOLATION, and SEPARATED, and include minimum distance, shortfall, face indices, and tested triangle-pair count.
- Clearance is an explicit numeric input. The engine does not invent project, code, manufacturer, or discipline values.
- The engine is read-only and never marks a proposed move as simulation-validated.

### API
- AT_ExactGeometryEngine.inspect nodes:<array> includeHidden:false
- AT_ExactGeometryEngine.detectClashes records:<array> requiredClearance:<number> epsilon:<number>
- AT_ExactGeometryEngine.clear()

### Known limits / validation gate
This is triangle-surface intersection for the mesh snapshot supplied by 3ds Max, not a BIM solid-kernel or semantic-object engine. Tessellation quality, open/non-manifold surfaces, hidden internal faces, object semantics, intentional contacts, and project-specific tolerance policies still require review. A distance result is geometric only, not code compliance or proof of installation/service access. Dense meshes may be expensive because the current implementation is pairwise after AABB filtering. MAXScript runtime behavior, snapshot coordinate conventions, and numeric edge cases have not been verified in 3ds Max in this session.


## Closed-mesh containment extension (0.2.0)
The geometry snapshot now records undirected edge incidence to distinguish closed two-manifold meshes from open or non-manifold surfaces. When two mesh AABBs are nested and their triangle surfaces do not intersect, a three-direction ray-parity check tests whether a representative inner-mesh vertex lies inside the outer closed mesh. Confirmed containment is reported as `SOLID_CONTAINMENT_INTERFERENCE`; nested AABBs involving open/non-manifold meshes are reported as `CONTAINMENT_UNVERIFIED`. The simulation blocks when an unverified-containment condition is present before or after a proposed move. This remains a triangle-mesh method, not a certified B-rep solid kernel; nested shells, self-intersections, inconsistent topology, and pathological tessellation still require in-host test scenes.


Degenerate zero-area triangles are excluded from distance/intersection calculations and counted. A mesh with no valid triangles is rejected from the geometry inventory; any mesh with skipped faces is not considered closed/manifold for containment validation.


Minimum surface distance is only populated when the triangle-level broad phase evaluated at least one pair within the requested clearance tolerance. Otherwise `minimumDistanceKnown=false` and the value remains undefined rather than reporting an invented large distance. A separated pair can therefore be known to exceed the requested clearance without claiming its exact minimum distance.


Scene inventory is limited to supported geometry and shape superclasses; cameras, lights and helper nodes are not treated as clash solids. Non-renderable/empty shapes are reported as geometry inspection errors rather than silently accepted as clear.
