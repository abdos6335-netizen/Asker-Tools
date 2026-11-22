from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
required = [
    'AskerTools.ms', 'Core/AT_Core.ms', 'Core/AT_Logger.ms',
    'Core/AT_Settings.ms', 'Core/AT_Compatibility.ms',
    'Modules/Diagnostics/AT_Diagnostics.ms',
    'Modules/SceneAudit/AT_SceneAudit.ms',
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

scene_audit = (ROOT / 'Modules/SceneAudit/AT_SceneAudit.ms').read_text(encoding='utf-8')
for token in ['DUPLICATE_NAME', 'MISSING_BITMAP', 'ZERO_SCALE', 'fn scan', 'fn selectFinding']:
    assert token in scene_audit, f'Scene audit check missing: {token}'
print(f'PASS: {len(required)} required files; {len(list(ROOT.rglob("*.ms")))} MAXScript files validated.')
