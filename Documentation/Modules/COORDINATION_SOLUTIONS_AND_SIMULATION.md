# Coordination solution generation and simulation

## Candidate generator (0.1.0)
Generates six axis-aligned translation alternatives per moving side of each exact-mesh clash. Candidate generation is deterministic and does not move scene nodes. It now also generates bounded rotation alternatives around the three world axes at explicitly supplied angle values (default candidate set: ±15° and ±30°). It does not yet generate reroutes, system redistribution, or fixed-element alternatives. Rotation candidates remain unvalidated until exact simulation and engineering approval. All candidates require simulation and engineering approval.

## Non-destructive simulation (0.1.0)
The simulation engine creates translated in-memory triangle-mesh snapshots for the selected element, recalculates exact mesh interference and explicit clearance against the supplied inventory, and compares before/after clash IDs. It reports resolved, remaining, and newly introduced clashes. The source transform associated with the mesh snapshot is retained for stale-scene protection during approval and application. Missing/unapproved rule checks, an empty rule-evaluation set, and critical violations block simulation before geometry evaluation.

Only a completed exact-geometry simulation with no newly introduced clashes is marked validated. The simulation does not prove structural feasibility, code compliance beyond supplied rule results, installation sequence, access, maintainability, or manufacturer requirements not represented in inputs. It does not modify scene nodes or apply transforms.

APIs:
- `AT_CoordinationSolutionGenerator.generateTranslations records clashes clearance:<number>`
- `AT_CoordinationSimulation.simulateTranslation records movingElementId offset targetClashId:<string> ruleChecks:<array> simulationId:<string>` and `simulateRotation records movingElementId axis angleDegrees pivot targetClashId:<string> ruleChecks:<array> simulationId:<string>`. Both action types are evaluated against transformed in-memory triangle meshes; neither edits the source scene. The simulation entry point independently revalidates the scan snapshot and blocks if the scene, discipline metadata, rule revision or jurisdiction changed.
- `AT_CoordinationSimulation.toProposalCandidate simulation description:<string> risk:<number>`

## Validation boundary
MAXScript execution and numeric correctness must be verified in supported 3ds Max installations. Runtime testing has not been performed in this environment.


Risk is explicitly marked `NOT_ASSESSED` until a dedicated engineering risk model is implemented. Unassessed risk is omitted from the ranking penalty rather than being represented as zero risk; the result remains visible for engineering review and requires named approval. Only clearance check types currently have an implemented geometric validator. Other check types return `CHECK_TYPE_VALIDATOR_NOT_IMPLEMENTED` and block simulation until a validator is supplied.
