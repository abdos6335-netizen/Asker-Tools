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
    'Documentation/Modules/MATERIAL_MANAGER.md',
    'Documentation/Modules/SCENE_MANAGER.md',
    'Documentation/Modules/ASSET_MANAGER.md',
    'Documentation/Modules/COORDINATION_SOLUTION_ENGINE.md',
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
    'Core/AT_Core.ms': ['version = "0.5.0"'],
    'Modules/Materials/AT_MaterialManager.ms': ['#filePostMerge', '#postImport', 'SHA256', 'AutoCollect', 'REV(?:ISION)?', 'centralizeBitmap', 'changeMapsFolder'],
    'Modules/Coordination/AT_SolutionEngine.ms': ['fn validateCandidate', 'fn buildProposal', 'fn generateProposals', 'fn generateAndRank', 'fn validateProposal', 'fn evaluateProposal', 'fn evaluate', 'fn setWeights', 'SIMULATION_NOT_VALIDATED', 'CRITICAL_RULE_VIOLATION', 'REQUIRED_RULE_MISSING', 'INTRODUCES_NEW_CLASHES'],
}
for rel, tokens in checks.items():
    source = (ROOT / rel).read_text(encoding='utf-8')
    for token in tokens:
        assert token in source, f'Missing expected marker {token!r} in {rel}'

print(f'PASS: {len(required)} required files; {len(list(ROOT.rglob("*.ms")))} MAXScript files validated.')
