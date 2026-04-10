# Phase 4: Migration & User Onboarding

## Overview

Phase 4 migrates existing users and documents from the legacy HTT Headquarters SharePoint site (`httbrands.sharepoint.com/sites/HTTHQ`) to the new hub-and-spoke architecture on `deltacrown`.

**Prerequisites**: Phase 2 + Phase 3 must be deployed first.

## Scripts

| Script | Purpose | Mode |
|--------|---------|------|
| `4.0-Master-Phase4.ps1` | Master orchestrator — runs all steps in order | Orchestrator |
| `4.1-User-Property-Audit.ps1` | Audit Azure AD user properties, simulate group matching | Read-only |
| `4.2-User-Onboarding.ps1` | Bulk-update user properties, verify dynamic group membership | Write |
| `4.3-Document-Migration.ps1` | Copy documents from HTTHQ to new sites | Write |

## Quick Start

```powershell
cd phase4-migration/scripts

# Step 1: Audit existing users (read-only, safe to run anytime)
./4.1-User-Property-Audit.ps1 -TenantName "deltacrown" -ExportCsv

# Step 2: Review the audit CSV and update dce-user-mapping.csv

# Step 3: Dry run user onboarding
./4.2-User-Onboarding.ps1 -MappingFile "../config/dce-user-mapping.csv" -WhatIf

# Step 4: Apply user onboarding (sets Azure AD properties)
./4.2-User-Onboarding.ps1 -MappingFile "../config/dce-user-mapping.csv"

# Step 5: Dry run document migration
./4.3-Document-Migration.ps1 -MappingFile "../config/dce-file-mapping.csv" -WhatIf

# Step 6: Run document migration (copies files cross-tenant)
./4.3-Document-Migration.ps1 -MappingFile "../config/dce-file-mapping.csv" -VerifyAfterCopy

# Or run everything via the master orchestrator:
./4.0-Master-Phase4.ps1 -UserMappingFile "../config/dce-user-mapping.csv" \
    -FileMappingFile "../config/dce-file-mapping.csv"
```

## Configuration Files

### `config/dce-user-mapping.csv`

Maps existing users to their new Azure AD properties. Edit this before running 4.2.

| Column | Description |
|--------|-------------|
| UserPrincipalName | User's email/UPN |
| NewCompanyName | Set to "Delta Crown Extensions" for DCE users |
| NewJobTitle | User's job title (triggers Leadership group if Manager/Director/VP) |
| NewDepartment | User's department (triggers Marketing group if "Marketing") |

### `config/dce-file-mapping.csv`

Maps source folders to destination sites. Review/edit before running 4.3.

| Column | Description |
|--------|-------------|
| SourceSite | HTTHQ site URL |
| SourceFolder | Folder path within Shared Documents |
| DestinationSite | Target site URL on deltacrown |
| DestinationLibrary | Target document library |
| DestinationFolder | Target folder within the library |
| Priority | 1 (critical), 2 (important), 3 (nice to have) |

## Architecture Reference

See [ADR-003: HTTHQ Document Migration Strategy](../docs/architecture/decisions/ADR-003-htthq-document-migration-strategy.md) for the full migration plan.
