#!/usr/bin/env bash
# Opt-in data contract gate. Copy to scripts/gate.d/data-contract.sh to enable.
set -uo pipefail
: "${DATA_CONTRACT_DIR=contracts}" "${DATA_CONTRACT_SCAN_ROWS=100000}"
contracts=("$DATA_CONTRACT_DIR"/*.json)
if [[ ! -f "${contracts[0]}" ]]; then
  echo 'data-contract: no contracts; skipping'; exit 0
fi
primary=$(git worktree list --porcelain | awk 'NR == 1 {sub(/^worktree /, ""); print; exit}')
prefix=$(git rev-parse --show-prefix) || exit 1
root=${NB_DATA_ROOT:-$primary/$prefix}
root=$(cd -P "$root" 2>/dev/null && pwd) || { echo "data-contract: no $root in the primary checkout" >&2; exit 1; }
python3 -I - "$root" "$DATA_CONTRACT_SCAN_ROWS" "${contracts[@]}" <<'PY'
import csv
import json
import os
import sys

root, scan, *contracts = sys.argv[1:]
failed = False

def error(message):
    global failed
    failed = True
    print('data-contract: ' + message, file=sys.stderr)

try:
    scan = int(scan)
    if scan < 0:
        raise ValueError()
except ValueError:
    error('invalid DATA_CONTRACT_SCAN_ROWS')
    sys.exit(1)

for filename in contracts:
    try:
        with open(filename, encoding='utf-8') as f:
            contract = json.load(f)
        path = contract['path']
        columns = contract['columns']
        rows = contract['rows']
        extra = contract.get('extra_columns', 'forbid')
        if (not isinstance(path, str) or not path or os.path.isabs(path)
                or not isinstance(columns, dict) or not columns
                or any(not isinstance(k, str) or v not in ('int', 'float', 'str', 'bool', 'any') for k, v in columns.items())
                or not isinstance(rows, list) or len(rows) != 2
                or type(rows[0]) is not int or rows[0] < 0
                or (rows[1] is not None and (type(rows[1]) is not int or rows[1] < rows[0]))
                or extra not in ('allow', 'forbid')):
            raise ValueError('invalid fields')
    except (OSError, ValueError, KeyError, TypeError) as exc:
        error(f'bad contract {filename}: {exc}')
        continue
    path = os.path.abspath(os.path.join(root, path))
    if not os.path.exists(path):
        error(f'{filename}: missing data file {path} (data lives in the primary checkout)')
        continue
    extension = os.path.splitext(path)[1].lower()
    if not os.path.isfile(path) or extension not in ('.csv', '.parquet'):
        error(f'{filename}: unsupported format {path}')
        continue
    try:
        if extension == '.csv':
            with open(path, newline='', encoding='utf-8-sig') as f:
                reader = csv.reader(f)
                names = next(reader, [])
                count = 0
                mismatches = set()
                for row in reader:
                    count += 1
                    if count > scan:
                        continue
                    for i, name in enumerate(names):
                        dtype = columns.get(name, 'any')
                        value = row[i] if i < len(row) else ''
                        if not value or name in mismatches:
                            continue
                        try:
                            if dtype == 'int':
                                int(value)
                            elif dtype == 'float':
                                float(value)
                            elif dtype == 'bool' and value.lower() not in ('true', 'false', '0', '1'):
                                raise ValueError()
                        except ValueError:
                            error(f'{filename}: column {name} expected {dtype}, got {value!r}')
                            mismatches.add(name)
        else:
            try:
                import pyarrow.parquet as pq
            except ImportError:
                error(f'{filename}: parquet needs pyarrow')
                continue
            parquet = pq.ParquetFile(path)
            schema = parquet.schema_arrow
            names = schema.names
            count = parquet.metadata.num_rows
            for field in schema:
                dtype = columns.get(field.name, 'any')
                actual = str(field.type)
                mapped = ('int' if actual.startswith(('int', 'uint')) else
                          'float' if actual.startswith(('float', 'double', 'decimal')) else
                          'str' if actual in ('string', 'large_string') else
                          'bool' if actual == 'bool' else None)
                if dtype != 'any' and dtype != mapped:
                    error(f'{filename}: column {field.name} expected {dtype}, got {actual}')
        for name in columns.keys() - set(names):
            error(f'{filename}: missing column {name}')
        if extra == 'forbid':
            for name in set(names) - columns.keys():
                error(f'{filename}: extra column {name}')
        if count < rows[0] or (rows[1] is not None and count > rows[1]):
            error(f'{filename}: row count {count} outside {rows}')
    except (OSError, UnicodeError, csv.Error, ValueError) as exc:
        error(f'{filename}: {exc}')

sys.exit(1 if failed else 0)
PY
