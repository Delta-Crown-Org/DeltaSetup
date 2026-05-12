# Excel Workbook Generation

## Rule

Do **not** hand-roll `.xlsx` files by writing raw workbook XML unless there is no other option. Excel is stricter than a simple ZIP integrity check, and a package that unzips cleanly can still be corrupt.

Use `openpyxl` for generated workbooks.

## Dependency

This repo does not currently vendor Python dependencies. Use `uv` for an ephemeral dependency environment:

```bash
uv run --with openpyxl python tools/generate_owner_decision_workbook.py
```

If the project later adds a committed Python dependency file, pin:

```text
openpyxl>=3.1,<4
```

## Validation

A generated workbook is not valid just because `unzip -t` passes.

Validate by loading it with `openpyxl`:

```bash
uv run --with openpyxl python - <<'PY'
from openpyxl import load_workbook
path = 'generated/delta-crown-owner-decision-workbook.xlsx'
wb = load_workbook(path)
required = {
    'Dashboard', 'Decision Matrix', 'Action Tracker', 'Evidence', 'Glossary',
    'OD-001', 'OD-002', 'OD-003', 'OD-004', 'OD-005', 'OD-006',
}
missing = required - set(wb.sheetnames)
if missing:
    raise SystemExit(f'Missing sheets: {sorted(missing)}')
print('Workbook loads and contains expected sheets')
PY
```

## Current generated workbook

```text
generated/delta-crown-owner-decision-workbook.xlsx
```

Regenerate with:

```bash
uv run --with openpyxl python tools/generate_owner_decision_workbook.py
```
