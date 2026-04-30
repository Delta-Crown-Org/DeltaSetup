# Phase 4: User Onboarding

## Current Decision

**HTTHQ document migration is skipped.** Tyler decided on 2026-04-29 that no documents will be copied from `httbrands.sharepoint.com/sites/HTTHQ` into the `deltacrown` tenant for this rollout.

The active Phase 4 scope is user audit/onboarding only. Historical migration scripts and mapping files remain in this folder for traceability, but they are **not** part of the production cutover path.

## Prerequisites

Phase 2 + Phase 3 SharePoint/Teams deployment and security hardening should be complete before onboarding users.

## Active Scripts

| Script | Purpose | Mode |
|--------|---------|------|
| `4.1-User-Property-Audit.ps1` | Audit Azure AD user properties, simulate group matching | Read-only |
| `4.2-User-Onboarding.ps1` | Bulk-update user properties, verify dynamic group membership | Write |

## Historical / Do Not Run for Cutover

| Script | Status | Notes |
|--------|--------|-------|
| `4.0-Master-Phase4.ps1` | Historical | Orchestrates migration-era flow; do not use for current cutover without editing out document migration. |
| `4.3-Document-Migration.ps1` | Skipped | Do not run. No HTTHQ files should be copied for production launch. |

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

Historical only. This file documents the previous migration mapping that was considered before the skip decision. Do not use it to run document migration for production cutover.

## Architecture Reference

See [ADR-003: HTTHQ Document Migration Strategy](../docs/architecture/decisions/ADR-003-htthq-document-migration-strategy.md), now marked **Superseded / Not Implemented**, for historical context.
