# Remonta db/schema.rb a partir do schema da main (upstream), trocando só as tabelas crm_*,
# as FKs crm_* e a versão pelo que o Rails acabou de gerar. Uso: merge_schema.py <base> <dumped> <saida>
import re
import sys

base_path, dumped_path, out_path = sys.argv[1:4]
base = open(base_path).read().split('\n')
dumped = open(dumped_path).read().split('\n')


def blocks(lines):
    found, i = {}, 0
    while i < len(lines):
        m = re.match(r'  create_table "([^"]+)"', lines[i])
        if m:
            j = i
            while lines[j] != '  end':
                j += 1
            found[m.group(1)] = (i, j)
            i = j
        i += 1
    return found


dumped_blocks = blocks(dumped)
crm_tables = {k: dumped[i:j + 1] for k, (i, j) in dumped_blocks.items() if k.startswith('crm_')}
crm_fks = sorted(l for l in dumped if l.startswith('  add_foreign_key "crm_'))
version = re.search(r'version: (\S+)\)', next(l for l in dumped if 'define(version' in l)).group(1)

# Remove tabelas/FKs crm_ antigas da base para reinserir as atuais.
skip = set()
for name, (i, j) in blocks(base).items():
    if name.startswith('crm_'):
        skip.update(range(i, j + 2))  # inclui a linha em branco depois do bloco
clean = [l for n, l in enumerate(base) if n not in skip and not l.startswith('  add_foreign_key "crm_')]

result, pending = [], sorted(crm_tables)
for line in clean:
    m = re.match(r'  create_table "([^"]+)"', line)
    while m and pending and pending[0] < m.group(1):
        result += crm_tables[pending.pop(0)] + ['']
    if 'define(version' in line:
        line = re.sub(r'version: \S+\)', f'version: {version})', line)
    result.append(line)
assert not pending, pending

final, fks = [], list(crm_fks)
for line in result:
    if line.startswith('  add_foreign_key "'):
        while fks and fks[0] < line:
            final.append(fks.pop(0))
    final.append(line)
assert not fks, fks
open(out_path, 'w').write('\n'.join(final))
print('tabelas crm:', sorted(crm_tables), '| fks crm:', len(crm_fks), '| versão:', version)
