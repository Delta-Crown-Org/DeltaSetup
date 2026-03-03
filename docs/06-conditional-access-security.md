# Phase 6: Conditional Access & Security Baseline

## Overview

Apply security policies in the DCE tenant to protect synced user accounts and ensure compliance.

## Prerequisites

- [ ] Cross-tenant sync complete (Phase 2)
- [ ] Microsoft 365 Business Premium active in DCE (includes Entra ID P1 for Conditional Access)
- [ ] Global Admin or Security Admin on DCE tenant

## Step 1: Trust HTT Brands MFA (Already Done in Phase 2)

In Phase 2, we configured inbound trust settings in the DCE tenant:
- ✅ Trust multi-factor authentication from HTT Brands
- ✅ Trust compliant devices
- ✅ Trust hybrid-joined devices

This means synced users are **not** prompted for MFA again when accessing DCE resources — their HTT Brands MFA is trusted.

## Step 2: Conditional Access Policies for DCE Tenant

> **Portal**: Entra Admin Center → DCE tenant → Protection → Conditional Access → Policies

### Policy 1: Require MFA for All Users
| Setting | Value |
|---------|-------|
| Name | `CA001 - Require MFA for all users` |
| Users | All users (include), Break-glass accounts (exclude) |
| Target resources | All cloud apps |
| Conditions | None (applies always) |
| Grant | Require multifactor authentication |
| Session | N/A |
| State | **Report-only** (enable after validation) |

> Since MFA is trusted from HTT Brands, synced users satisfy this automatically.

### Policy 2: Block Legacy Authentication
| Setting | Value |
|---------|-------|
| Name | `CA002 - Block legacy authentication` |
| Users | All users |
| Target resources | All cloud apps |
| Conditions | Client apps → Exchange ActiveSync clients, Other clients |
| Grant | **Block access** |
| State | **Report-only** → then **On** |

### Policy 3: Require Compliant/Trusted Device for SharePoint & Exchange
| Setting | Value |
|---------|-------|
| Name | `CA003 - Require trusted device for data apps` |
| Users | All users (include), Break-glass (exclude) |
| Target resources | Office 365 SharePoint Online, Office 365 Exchange Online |
| Conditions | Any device platform |
| Grant | Require device compliance OR Require Hybrid Azure AD joined device |
| State | **Report-only** |

## Step 3: Create Break-Glass Accounts

> **Critical**: Always have emergency access accounts excluded from Conditional Access.

1. Create two break-glass accounts in DCE tenant:
   - `breakglass1@deltacrown.com`
   - `breakglass2@deltacrown.com`
2. Assign **Global Admin** role
3. Use strong, unique passwords stored in a physical safe or secure vault
4. **Do NOT** require MFA on these accounts (they are your emergency access)
5. Set up **sign-in log alerts** for these accounts (Azure Monitor)

## Step 4: Security Defaults Check

If Conditional Access policies are being used, **Security Defaults must be disabled**:
1. Entra Admin Center → Properties → Manage Security Defaults
2. Toggle to **Disabled** (since we're using CA policies instead)

## Step 5: Review Synced User Permissions

Ensure synced users have **only** the access they need:

| Check | Action |
|-------|--------|
| No admin roles assigned to synced users | Review Entra ID → Roles and administrators |
| SharePoint access scoped to specific sites | Review SharePoint Admin → Site permissions |
| Teams access scoped to specific teams | Review Teams membership |
| Shared mailbox access is explicit | Review Exchange permissions (Phase 4) |

## Validation Checklist

- [ ] CA policies created in Report-only mode
- [ ] Verified synced users are not double-prompted for MFA
- [ ] Break-glass accounts created and tested
- [ ] Security defaults disabled (CA policies active instead)
- [ ] CA Insights (Report-only) reviewed after 48 hours
- [ ] CA policies moved from Report-only to On (after validation)
