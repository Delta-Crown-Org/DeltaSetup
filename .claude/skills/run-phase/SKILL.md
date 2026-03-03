---
name: run-phase
description: Show the DCE setup execution order and run a specific phase script with safety checks
user_invocable: true
---

# Phase Runner — Delta Crown Extensions Setup

You are helping the user run one of the DCE tenant provisioning scripts in the correct order.

## Steps

1. **Read context**: Read `config/tenant-config.json` and `scripts/README.md` to understand the current tenant configuration and full script execution order.

2. **Display the execution order** as a numbered table:

| # | Script | Purpose | Tenant |
|---|--------|---------|--------|
| 00 | Install-Prerequisites.ps1 | Install required PS modules | N/A |
| 01 | Connect-Tenants.ps1 | Connect to Graph + Exchange for both tenants | Both |
| 02 | Configure-CrossTenantAccess.ps1 | Set up cross-tenant access policies | Both |
| 03 | Configure-CrossTenantSync.ps1 | Create sync security group + instructions | HTT Brands |
| 04 | Create-SharedMailboxes.ps1 | Create shared mailboxes from CSV | DCE |
| 05 | Grant-SendAs-Permissions.ps1 | Grant Send-As and Full Access | DCE |
| 06 | Create-Groups.ps1 | Create M365 Groups | DCE |
| 07 | Validate-DNS-Records.ps1 | Check SPF/DKIM/DMARC | N/A |
| 08 | Validation-Tests.ps1 | Full end-to-end validation | Both |

3. **Ask the user** which phase (number) they want to run.

4. **Before executing**, check and warn about:
   - **Prerequisites**: Scripts 02–08 require script 01 (Connect-Tenants) to have been run first in the current session. Remind the user to connect if they haven't.
   - **Dependencies**: Script 05 depends on 04 (mailboxes must exist before granting permissions). Script 03 should run before 04–06.
   - **WhatIf support**: Scripts **04, 05, and 06** support `-WhatIf`. Suggest running with `-WhatIf` first to preview changes before applying them.

5. **Execute the script** using PowerShell when the user confirms. For scripts that support `-WhatIf`, ask whether to do a dry run first.

## Safety Reminders
- Never skip script 01 — tenant connections must be active
- Always suggest `-WhatIf` for scripts that modify resources (04, 05, 06)
- The target tenant is **Delta Crown Extensions** (deltacrown.com) — confirm if the script touches the source tenant (HTT Brands)
