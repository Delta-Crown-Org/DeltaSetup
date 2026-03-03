# Delta Crown Extensions — Automation Scripts

## Prerequisites

- PowerShell 7.0+ (`winget install Microsoft.PowerShell`)
- Required modules (run `00-Install-Prerequisites.ps1`):
  - `Microsoft.Graph` — Entra ID / Graph API operations
  - `ExchangeOnlineManagement` — Exchange Online / mailbox operations
  - `Az` — Azure subscription management

## Execution Order

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

## Safety

- Scripts that modify resources support `-WhatIf` where applicable
- All authentication is **interactive** (no stored credentials)
- Tenant config is read from `config/tenant-config.json`

## Helper Scripts

| Script | Purpose |
|--------|---------|
| helpers/Export-HTTUsers.ps1 | Export HTT Brands user list; with `-GenerateMailboxCSV` generates the provisioning CSV from synced DCE users |
| helpers/Add-SyncGroupMembers.ps1 | Bulk-add users to SG-DCE-Sync-Users; use `-TestOnly` for initial testing or no flag for all users |

## Usage

```powershell
# First time setup
.\scripts\00-Install-Prerequisites.ps1

# Export user list (before sync)
.\scripts\helpers\Export-HTTUsers.ps1

# Run cross-tenant setup
.\scripts\02-Configure-CrossTenantAccess.ps1 -WhatIf
.\scripts\03-Configure-CrossTenantSync.ps1

# Add test users to sync group
.\scripts\helpers\Add-SyncGroupMembers.ps1 -TestOnly

# After sync completes, generate mailbox CSV
.\scripts\helpers\Export-HTTUsers.ps1 -GenerateMailboxCSV

# Create mailboxes and grant permissions
.\scripts\04-Create-SharedMailboxes.ps1 -WhatIf
.\scripts\05-Grant-SendAs-Permissions.ps1 -WhatIf

# Create groups
.\scripts\06-Create-Groups.ps1 -WhatIf
```
