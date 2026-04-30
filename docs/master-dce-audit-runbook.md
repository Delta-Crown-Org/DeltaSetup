# Master DCE Audit Runbook

## Purpose

Run a read-only audit of the existing HTT Brands `Master DCE` folder so Delta Crown resources can be mapped from reality instead of memory.

Source:

```text
https://httbrands.sharepoint.com/sites/HTTHQ
Shared Documents / Master DCE
```

Primary PnP script:

```text
phase4-migration/scripts/audit-master-dce.ps1
```

Azure CLI / Graph fallback script:

```text
phase4-migration/scripts/audit_master_dce_graph.py
```

Expected outputs:

```text
.local/reports/master-dce/master-dce-folder-inventory.csv
.local/reports/master-dce/master-dce-permissions.csv
.local/reports/master-dce/master-dce-summary.md
```

## What this audit does

The script inventories folders and folder permissions under `Master DCE`.

It captures:

- folder name;
- server-relative URL;
- site-relative URL;
- direct file count;
- direct child-folder count;
- modified date;
- modified by;
- whether the folder has unique permissions;
- permission principals and roles.

## What this audit does not do

It does not:

- copy files;
- move files;
- delete files;
- rename files or folders;
- change permissions;
- create SharePoint sites;
- create shortcuts;
- migrate content into Delta Crown;
- change tenant settings.

If it writes anything, it writes local report files only. Raw outputs are local-only by default under `.local/reports/master-dce/` and must not be committed unless Tyler explicitly approves the reviewed/redacted artifact.

## Prerequisites

### Local tools

- PowerShell 5.1+ or PowerShell 7+ (`pwsh` recommended).
- PnP.PowerShell installed.
- Git repo checked out on a clean branch/worktree.

Check PowerShell:

```powershell
$PSVersionTable.PSVersion
```

Check PnP.PowerShell:

```powershell
Get-Module PnP.PowerShell -ListAvailable | Select-Object Name, Version, Path
```

Install PnP.PowerShell if needed:

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

### Tenant access

The signed-in account needs read access to:

```text
https://httbrands.sharepoint.com/sites/HTTHQ
Shared Documents / Master DCE
```

Preferred account:

- Tyler or another approved HTT Brands user with access to Master DCE.

If PnP.PowerShell requires an explicit client ID, provide one through:

```powershell
$env:HTT_PNP_CLIENT_ID = "<approved-pnp-client-id>"
```

Optional tenant override:

```powershell
$env:HTT_TENANT_ID = "httbrands.onmicrosoft.com"
```

Do not commit client IDs if they are sensitive in your environment. Do not commit secrets. Ever. Secrets in git are raccoons in the HVAC.

## Pre-flight checklist

Before running the audit:

- [ ] Confirm current branch/worktree is clean.
- [ ] Confirm script path exists.
- [ ] Confirm target site is HTTHQ, not Delta Crown.
- [ ] Confirm root folder is `Master DCE`.
- [ ] Confirm output directory is acceptable.
- [ ] Confirm no migration script is being run.
- [ ] Confirm no admin write operation is planned.
- [ ] Confirm outputs will be reviewed before commit.
- [ ] Confirm raw outputs stay local unless Tyler approves a redacted/safe artifact.
- [ ] Confirm any OAuth/admin consent prompt requests read-only permissions only.
- [ ] Confirm sensitive data handling rules with Tyler.

Commands:

```bash
git status -sb
```

```powershell
Test-Path ./phase4-migration/scripts/audit-master-dce.ps1
```

PowerShell parser check:

```powershell
[System.Management.Automation.Language.Parser]::ParseFile(
  "phase4-migration/scripts/audit-master-dce.ps1",
  [ref]$null,
  [ref]$null
) | Out-Null
```


## OAuth consent safety check

During sign-in, inspect any requested permissions. Continue only if the prompt aligns with read-only audit access. Cancel and stop if the prompt requests write-capable permissions or broad admin consent that was not explicitly approved for the audit window.

Do not approve prompts requesting permissions such as:

- `Sites.ReadWrite.All`
- `Sites.FullControl.All`
- `Directory.ReadWrite.All`
- `Group.ReadWrite.All`
- `User.ReadWrite.All`
- `Application.ReadWrite.All`
- `Policy.ReadWrite.*`

If a prompt looks wrong, stop. A failed audit is cheaper than an accidental permission fiesta.

## Standard PnP audit command

From repo root:

```powershell
pwsh -File ./phase4-migration/scripts/audit-master-dce.ps1
```

If browser interactive auth fails because the tenant/app registration lacks a valid reply URL, retry only with an approved client ID or one of the alternate auth modes below. Do not create or modify app registrations during the audit window.

Device-code login:

```powershell
pwsh -File ./phase4-migration/scripts/audit-master-dce.ps1 -DeviceLogin
```

OS/broker login:

```powershell
pwsh -File ./phase4-migration/scripts/audit-master-dce.ps1 -OSLogin
```

With an approved client ID:

```powershell
$env:HTT_PNP_CLIENT_ID = "<approved-pnp-client-id>"
pwsh -File ./phase4-migration/scripts/audit-master-dce.ps1 -DeviceLogin
```

## Azure CLI / Graph fallback command

If Azure CLI is already authenticated to the HTT tenant, use the Graph fallback to avoid PnP delegated app redirect issues:

```bash
az account show
python3 phase4-migration/scripts/audit_master_dce_graph.py
```

This fallback is read-only and writes to `.local/reports/master-dce/` by default.

Equivalent PnP command with explicit values:

```powershell
pwsh -File ./phase4-migration/scripts/audit-master-dce.ps1 `
  -SiteUrl "https://httbrands.sharepoint.com/sites/HTTHQ" `
  -LibraryName "Shared Documents" `
  -RootFolder "Master DCE" `
  -OutputDirectory ".local/reports/master-dce"
```

With explicit PnP client ID:

```powershell
$env:HTT_PNP_CLIENT_ID = "<approved-pnp-client-id>"

pwsh -File ./phase4-migration/scripts/audit-master-dce.ps1 `
  -SiteUrl "https://httbrands.sharepoint.com/sites/HTTHQ" `
  -LibraryName "Shared Documents" `
  -RootFolder "Master DCE" `
  -Tenant "httbrands.onmicrosoft.com" `
  -OutputDirectory ".local/reports/master-dce"
```

## Recursive audit command

Use recursive mode only after the top-level audit succeeds and Tyler explicitly approves deeper inventory in the issue notes. Recursive outputs may expose more sensitive folder names, file relationships, and permission details, so raw recursive outputs must remain local until reviewed/redacted.

```powershell
pwsh -File ./phase4-migration/scripts/audit-master-dce.ps1 -Recursive
```

Recursive output may reveal more folder names and permission details. Review before committing.

## Expected files

After successful execution:

```text
.local/reports/master-dce/master-dce-folder-inventory.csv
.local/reports/master-dce/master-dce-permissions.csv
.local/reports/master-dce/master-dce-summary.md
```

Validate outputs:

```powershell
Get-ChildItem ./.local/reports/master-dce/master-dce-*
Import-Csv ./.local/reports/master-dce/master-dce-folder-inventory.csv | Format-Table -AutoSize
Import-Csv ./.local/reports/master-dce/master-dce-permissions.csv | Select-Object -First 20 | Format-Table -AutoSize
Get-Content ./.local/reports/master-dce/master-dce-summary.md
```

## Output review before commit

Before committing reports, check for:

- secrets;
- tokens;
- overly sensitive user details;
- client/customer data;
- financial or strategy file names that should not be public;
- external user emails that should be summarized instead of committed.

If outputs are sensitive, do not commit raw CSVs. Instead:

1. keep raw outputs local;
2. create a redacted summary;
3. document that raw outputs were withheld;
4. commit only the redacted summary and decision notes.

Suggested redacted summary path if Tyler approves committing a summary:

```text
reports/master-dce-summary-redacted.md
```

## Success criteria

The audit execution issue can advance when:

- the script ran successfully or the auth/access blocker is documented;
- generated outputs are reviewed for sensitivity;
- safe outputs are committed, or sensitive outputs are summarized/redacted;
- each top-level Master DCE folder can be mapped in `docs/master-dce-resource-map.md` later;
- no SharePoint content, permissions, or tenant settings were changed.

## Failure handling

### Authentication fails

Capture:

- account used, if safe to document;
- error message summary;
- request ID / correlation ID / timestamp from Microsoft sign-in error pages;
- whether a PnP client ID was provided;
- whether browser/device/OS auth completed;
- next required access step.

Do not retry repeatedly with random accounts. That is not troubleshooting; that is ritual.

#### Known blocker: AADSTS500113

If Microsoft returns:

```text
AADSTS500113: No reply address is registered for the application.
```

Stop the PnP audit attempt. This means the PnP/Entra app registration used for delegated login does not have the required redirect/reply configuration for the auth flow. It is not a user password problem.

If Azure CLI is already logged into the HTT tenant, use `phase4-migration/scripts/audit_master_dce_graph.py` as the read-only Graph fallback.

Resolution path for PnP:

1. Identify or configure an approved PnP/Entra app registration for `httbrands.onmicrosoft.com`.
2. Confirm the app supports the chosen delegated login flow.
3. Confirm requested permissions are read-only.
4. Set the approved client ID locally, not in git:

   ```powershell
   $env:HTT_PNP_CLIENT_ID = "<approved-pnp-client-id>"
   ```

5. Retry with `-DeviceLogin`, `-OSLogin`, or standard interactive auth.

Do not grant write scopes such as `Sites.ReadWrite.All`, `Sites.FullControl.All`, `Directory.ReadWrite.All`, or `Group.ReadWrite.All` just to make auth pass. That is how tiny audit tasks become tenant-wide chaos raccoons.

### Folder not found

Confirm:

- site URL;
- library name;
- folder name;
- whether the folder is visible in browser;
- whether user has access.

### Permission read fails

The account may have folder visibility but not permission visibility. Record the limitation and ask for elevated read/admin access before guessing.

## Handoff after audit

Update these issues:

- `DeltaSetup-127` — execution status and output paths.
- `DeltaSetup-128` — ready to create resource map if outputs exist.
- `DeltaSetup-122` — parent audit status.

Then create or update:

```text
docs/master-dce-resource-map.md
```

Do not start content moves or tenant cleanup from the audit results. The next step is mapping and decision-making, not yeeting files across tenants.
