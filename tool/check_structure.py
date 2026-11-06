from pathlib import Path
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
layers = {'domain', 'application', 'data', 'presentation'}
for layer in layers:
    assert (root / 'lib' / layer).is_dir(), f'Missing {layer}'
for path in (root / 'lib').rglob('*.dart'):
    relative = path.relative_to(root / 'lib')
    if len(relative.parts) < 2:
        continue  # composition root
    layer = relative.parts[0]
    source = path.read_text()
    for target in re.findall(r"import\s+['\"]([^'\"]+)['\"]", source):
        if target.startswith('package:'):
            if layer == 'domain':
                raise AssertionError(f'Domain has a package dependency: {path}: {target}')
            if layer == 'application':
                assert target == 'package:flutter/foundation.dart', (path, target)
            continue
        dest = (path.parent / target).resolve()
        target_layer = dest.relative_to(root / 'lib').parts[0]
        permitted = {'domain': {'domain'}, 'application': {'application', 'domain'},
                     'data': {'data', 'domain'}, 'presentation': {'presentation', 'application', 'domain'}}
        assert target_layer in permitted[layer], (path, target)
spec = (root/'lib/domain/screens.dart').read_text()
ids = re.findall(r"ScreenSpec\('([A-Z]\d{2})'", spec)
assert len(ids) == len(set(ids)) == 92
implementation = (root/'lib/presentation/shell.dart').read_text()
defined = set(re.findall(r"'([A-Z]\d{2})'", implementation.split('class AppShell')[0]))
assert defined == set(ids)
for path in (root/'android/app/src/main').rglob('*.xml'):
    ET.parse(path)
for path in (root/'assets').rglob('*.svg'):
    ET.parse(path)
print('Four layers, 92 routes, assets and Android XML: passed')
