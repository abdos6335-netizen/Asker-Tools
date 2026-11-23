from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
required = [
    'AskerTools.ms', 'Core/AT_Core.ms', 'Core/AT_Logger.ms',
    'Core/AT_Settings.ms', 'Core/AT_Compatibility.ms',
    'Modules/Diagnostics/AT_Diagnostics.ms',
    'Modules/SceneAudit/AT_SceneAudit.ms',
    'Modules/SceneManager/AT_SceneManager.ms',
    'Modules/Assets/AT_AssetManager.ms',
    'Modules/Cleanup/AT_Cleanup.ms',
    'Modules/Materials/AT_MaterialManager.ms',
    'Modules/Coordination/AT_SolutionEngine.ms',
    'Modules/Coordination/AT_CoordinationGeometryAdapter.ms',
    'Modules/Coordination/AT_ExactGeometryEngine.ms',
    'Modules/Coordination/AT_DisciplineAdapter.ms',
    'Modules/Coordination/AT_RuleEngine.ms',
    'Modules/Coordination/AT_CoordinationSimulation.ms',
    'Modules/Coordination/AT_CoordinationSolutionGenerator.ms',
    'Modules/Coordination/AT_ClashManager.ms',
    'Modules/Coordination/AT_CoordinationGovernance.ms',
    'Modules/Coordination/AT_CoordinationIntegrations.ms',
    'Modules/Coordination/AT_CoordinationReports.ms',
    'Documentation/Modules/MATERIAL_MANAGER.md',
    'Documentation/Modules/SCENE_MANAGER.md',
    'Documentation/Modules/ASSET_MANAGER.md',
    'Documentation/Modules/COORDINATION_SOLUTION_ENGINE.md',
    'Documentation/Modules/COORDINATION_DISCIPLINES_AND_RULES.md',
    'Documentation/Modules/COORDINATION_SOLUTIONS_AND_SIMULATION.md',
    'Documentation/Modules/COORDINATION_REVIEW_AND_GOVERNANCE.md',
    'Documentation/Modules/COORDINATION_INTEGRATIONS_AND_REPORTS.md',
    'Tests/COORDINATION_ENGINE_QA.md',
]
for rel in required:
    path = ROOT / rel
    assert path.is_file(), f'Missing required file: {rel}'
    assert path.stat().st_size > 80, f'File unexpectedly small: {rel}'

for path in ROOT.rglob('*.ms'):
    source = path.read_text(encoding='utf-8')
    assert '\x00' not in source, f'NUL byte in {path}'
    assert source.count('(') == source.count(')'), f'Unbalanced parentheses in {path}'
    assert source.count('[') == source.count(']'), f'Unbalanced brackets in {path}'

checks = {
    'Modules/SceneAudit/AT_SceneAudit.ms': ['DUPLICATE_NAME', 'MISSING_BITMAP', 'ZERO_SCALE', 'fn scan', 'fn selectFinding'],
    'Modules/SceneManager/AT_SceneManager.ms': ['fn inventory', 'fn selectByClass', 'fn selectByLayer', 'fn isolateNodes'],
    'Modules/Assets/AT_AssetManager.ms': ['fn scan', 'doesFileExist', 'fn missing'],
    'Modules/Cleanup/AT_Cleanup.ms': ['UNASSIGNED_MATERIAL_CANDIDATE', 'HIDDEN_NODE', 'fn scan'],
    'Core/AT_Core.ms': ['version = "0.6.0"'],
    'Modules/Materials/AT_MaterialManager.ms': ['#filePostMerge', '#postImport', 'SHA256', 'AutoCollect', 'REV(?:ISION)?', 'centralizeBitmap', 'changeMapsFolder'],
    'Modules/Coordination/AT_SolutionEngine.ms': ['fn validateCandidate', 'fn buildProposal', 'fn generateProposals', 'fn generateAndRank', 'fn validateProposal', 'fn evaluateProposal', 'fn evaluate', 'fn setWeights', 'SIMULATION_NOT_VALIDATED', 'CRITICAL_RULE_VIOLATION', 'REQUIRED_RULE_MISSING', 'INTRODUCES_NEW_CLASHES'],
    'Modules/Coordination/AT_CoordinationGeometryAdapter.ms': ['fn inspect', 'fn detectClashes', 'fn generateMoveCandidates', 'fn simulateAABBMove', 'AABB_CLEAR_ONLY_REQUIRES_EXACT_VALIDATION', 'simulationValidated = false'],
    'Modules/Coordination/AT_ExactGeometryEngine.ms': ['fn trianglesIntersect', 'fn triangleDistanceSquared', 'fn inspectPair', 'EXACT_MESH_INTERFERENCE', 'CLEARANCE_VIOLATION', 'fn detectClashes'],
    'Modules/Coordination/AT_DisciplineAdapter.ms': ['ARCHITECTURE', 'STRUCTURE', 'ELECTRICAL', 'HVAC', 'FIRE_FIGHTING', 'PLUMBING', 'LOW_CURRENT', 'INTERIOR_ELEMENTS', 'DISCIPLINE_MAPPING_MISSING', 'fn registerMapping'],
    'Modules/Coordination/AT_RuleEngine.ms': ['MANDATORY_CODE', 'AUTHORITY_APPROVAL', 'MANUFACTURER_SPEC', 'PROJECT_SPEC', 'ASKER_DEFAULT', 'HIGHEST_PRIORITY_RULE_NOT_APPROVED', 'CONFLICTING_SAME_PRIORITY_RULES', 'fn evaluateBatch'],
    'Modules/Coordination/AT_CoordinationSimulation.ms': ['fn cloneTranslatedMesh', 'fn simulateTranslation', 'sourceTransform', 'INVALID_OFFSET_VECTOR', 'EXACT_GEOMETRY_SIMULATION_PASSED', 'NEW_CLASHES_INTRODUCED', 'TARGET_CLASH_ID_REQUIRED', 'TARGET_CLASH_REMAINS', 'BLOCKED_RULE_MISSING', 'BLOCKED_RULE_CHECKS_NOT_SUPPLIED'],
    'Modules/Coordination/AT_CoordinationSolutionGenerator.ms': ['fn generateTranslations', 'separationOffset', 'requiresEngineeringApproval=true'],
    'Modules/Coordination/AT_ClashManager.ms': ['fn load', 'fn counts', 'fn selectClash', 'fn setTracking', 'fn scan', 'fn show', 'Detect Exact Mesh Clashes'],
    'Modules/Coordination/AT_CoordinationGovernance.ms': ['fn approve', 'fn applyTranslation', 'fn rollback', 'FAILED_ROLLED_BACK', 'APPLY_BLOCKED_STALE_SCENE', 'ROLLBACK_BLOCKED_SCENE_CHANGED'],
    'Modules/Coordination/AT_CoordinationIntegrations.ms': ['fn register', 'fn exchange', 'SOURCE_REVISION_REQUIRED', 'CAPABILITY_NOT_SUPPORTED'],
    'Modules/Coordination/AT_CoordinationReports.ms': ['fn buildClashRows', 'fn buildProposalRows', 'fn exportCSV', 'csvEscape'],
}
for rel, tokens in checks.items():
    source = (ROOT / rel).read_text(encoding='utf-8')
    for token in tokens:
        assert token in source, f'Missing expected marker {token!r} in {rel}'

print(f'PASS: {len(required)} required files; {len(list(ROOT.rglob("*.ms")))} MAXScript files validated.')
