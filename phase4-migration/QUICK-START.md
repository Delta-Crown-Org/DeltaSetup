# Phase 4: Quick Start — Run This in PowerShell

## Step 1: Run the User Audit (read-only, safe)

Open a PowerShell 7 terminal and run:

```powershell
cd ~/dev/DeltaSetup/phase4-migration/scripts

# This will open a browser window for Azure AD authentication.
# Sign in with your deltacrownext admin account.
./4.1-User-Property-Audit.ps1 -TenantName "deltacrownext" -ExportCsv
```

**What it does:**
- Connects to Microsoft Graph (browser auth popup)
- Lists ALL users on the deltacrownext tenant
- Shows their current companyName, department, jobTitle
- Simulates which dynamic security groups they'd match
- Flags users with missing properties
- Exports two CSVs to `phase4-migration/logs/`:
  - Full audit: `user-audit-TIMESTAMP.csv`
  - Needs attention: `user-audit-TIMESTAMP-needs-attention.csv`

**What to look for:**
- Users with `Brand = UNASSIGNED` → need companyName set
- Users with `MissingFields` → need properties filled in
- Users matching `SG-DCE-Leadership` → verify these are actually leadership

## Step 2: Review and Update the User Mapping

Open `phase4-migration/config/dce-user-mapping.csv` in Excel or VS Code.

The CSV is pre-populated with known corporate users from the HTTHQ audit. **You need to:**

1. ✅ **Verify UPNs** — The `@deltacrownext.onmicrosoft.com` UPNs are best-guesses. Check against the audit CSV from Step 1.
2. ✅ **Verify job titles** — Fill in actual titles (triggers Leadership group if Manager/Director/VP)
3. ✅ **Verify departments** — Fill in actual departments (triggers Marketing group)
4. ➕ **Add missing users** — Anyone on deltacrownext not in the CSV
5. ➖ **Remove wrong users** — Anyone who shouldn't be DCE-branded

### Dynamic Group Rules Cheat Sheet

| Property | Value | Auto-Joins |
|----------|-------|------------|
| `companyName` = "Delta Crown Extensions" | Required for all DCE users | SG-DCE-AllStaff |
| `jobTitle` contains Manager/Director/VP/Chief/Head | Leadership roles | SG-DCE-Leadership |
| `department` contains "Marketing" | Marketing team | SG-DCE-Marketing |

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
3. Verify users appeared in SG-DCE-AllStaff
4. Report results

## Step 5: Run the Full Deployment (Phase 2 + 3 + 4)

Once user properties are set, deploy the full architecture:

```powershell
# Phase 2: Hub Foundation (~45 min)
cd ~/dev/DeltaSetup/phase2-week1/scripts
./2.0-Master-Provisioning.ps1 -TenantName "deltacrownext" -OwnerEmail "YOUR_EMAIL" -Environment Development -SkipBusinessPremiumWarning

# Phase 3: Sites + Teams + Security (~30 min)
cd ~/dev/DeltaSetup/phase3-week2/scripts
./3.0-Master-Phase3.ps1 -TenantName "deltacrownext" -Environment Development

# Phase 4: Document Migration (after Phase 2+3)
cd ~/dev/DeltaSetup/phase4-migration/scripts

# Dry run first:
./4.3-Document-Migration.ps1 -MappingFile "../config/dce-file-mapping.csv" -WhatIf

# Then for real:
./4.3-Document-Migration.ps1 -MappingFile "../config/dce-file-mapping.csv" -VerifyAfterCopy
```

## What Happens After

Once everything is deployed:
- Users with `companyName = "Delta Crown Extensions"` automatically see the DCE Hub
- Their dynamic group membership gives them the right site permissions
- Documents from HTTHQ's Master DCE folder are in the new structured sites
- DLP policies protect against external sharing
- Teams workspace is ready with channels and tabs

**Estimated total time: ~90 minutes (mostly waiting for scripts to run)**
