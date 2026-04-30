# Phase 4: Quick Start — User Onboarding Only

> **Current decision (2026-04-29): HTTHQ document migration is skipped.**
>
> Do **not** run `4.3-Document-Migration.ps1` for production cutover. This folder still contains historical migration tooling, but active Phase 4 work is user audit/onboarding only.

## Step 1: Run the User Audit (read-only, safe)

Open a PowerShell 7 terminal and run:

```powershell
cd ~/dev/DeltaSetup/phase4-migration/scripts

# This will open a browser window for Azure AD authentication.
# Sign in with your deltacrown admin account.
./4.1-User-Property-Audit.ps1 -TenantName "deltacrown" -ExportCsv
```

**What it does:**
- Connects to Microsoft Graph (browser auth popup)
- Lists ALL users on the deltacrown tenant
- Shows their current companyName, department, jobTitle
- Simulates which dynamic security groups they'd match
- Flags users with missing properties
- Exports two CSVs to `phase4-migration/logs/`:
  - Full audit: `user-audit-TIMESTAMP.csv`
  - Needs attention: `user-audit-TIMESTAMP-needs-attention.csv`

**What to look for:**
- Users with `Brand = UNASSIGNED` → need companyName set
- Users with `MissingFields` → need properties filled in
- Users matching `Managers` → verify these are actually leadership

## Step 2: Review and Update the User Mapping

Open `phase4-migration/config/dce-user-mapping.csv` in Excel or VS Code.

The CSV is pre-populated with known corporate users from the HTTHQ audit. **You need to:**

1. ✅ **Verify UPNs** — The `@deltacrown.onmicrosoft.com` UPNs are best-guesses. Check against the audit CSV from Step 1.
2. ✅ **Verify job titles** — Fill in actual titles (triggers Leadership group if Manager/Director/VP)
3. ✅ **Verify departments** — Fill in actual departments (triggers Marketing group)
4. ➕ **Add missing users** — Anyone on deltacrown not in the CSV
5. ➖ **Remove wrong users** — Anyone who shouldn't be DCE-branded

### Dynamic Group Rules Cheat Sheet

| Property | Value | Auto-Joins |
|----------|-------|------------|
| `companyName` = "Delta Crown Extensions" | Required for all DCE users | AllStaff |
| `jobTitle` contains Manager/Director/VP/Chief/Head | Leadership roles | Managers |
| `department` contains "Marketing" | Marketing team | Marketing |

## Step 3: Dry Run User Onboarding

```powershell
# See what WOULD change without actually changing anything:
./4.2-User-Onboarding.ps1 -MappingFile "../config/dce-user-mapping.csv" -WhatIf
```

Review the output. If it looks right, proceed to Step 4.

## Step 4: Apply User Onboarding

```powershell
# Actually update Azure AD properties:
./4.2-User-Onboarding.ps1 -MappingFile "../config/dce-user-mapping.csv"
```

This will:
1. Update each user's Azure AD properties
2. Wait ~5 minutes for dynamic group evaluation
3. Verify users appeared in AllStaff
4. Report results

## Step 5: Continue Deployment Without Document Migration

Once user properties are set, continue with validation and launch readiness. The core SharePoint/Teams deployment and security hardening have already been completed live.

```powershell
# Optional verification examples:
cd ~/dev/DeltaSetup/phase3-week2/scripts
./deploy-security-hardening.ps1 -VerifyOnly

cd ~/dev/DeltaSetup/phase4-migration/scripts
./4.1-User-Property-Audit.ps1 -TenantName "deltacrown" -ExportCsv
```

## What Happens After

Once onboarding and validation are complete:
- Users with `companyName = "Delta Crown Extensions"` automatically see the DCE Hub
- Their dynamic group membership gives them the right site permissions
- HTTHQ documents remain in place; no files are copied into the `deltacrown` tenant
- DLP policies protect against external sharing
- Teams workspace is ready with channels and tabs

**Estimated active Phase 4 time: user audit/onboarding only; document migration is intentionally skipped.**
