# Phase 3: SharePoint, Teams & Microsoft 365 Groups

## Overview

Set up collaboration infrastructure in the DCE tenant for synced users: SharePoint sites, Teams workspaces, and Microsoft 365 Groups.

## Prerequisites

- [ ] Cross-tenant sync complete (Phase 2)
- [ ] Synced users visible in DCE tenant as Member-type
- [ ] Global Admin or SharePoint Admin + Teams Admin on DCE tenant

## Step 1: Create Microsoft 365 Groups

> **Portal**: [Microsoft 365 Admin Center](https://admin.microsoft.com) → Switch to DCE tenant → Groups

| Group Name | Email | Type | Privacy | Purpose |
|------------|-------|------|---------|----------|
| Delta Crown All Staff | `all-staff@deltacrown.com` | Microsoft 365 | Private | Company-wide |
| DCE Operations | `operations@deltacrown.com` | Microsoft 365 | Private | Operations team |
| DCE Leadership | `leadership@deltacrown.com` | Microsoft 365 | Private | Leadership |

Each M365 Group automatically creates:
- A **SharePoint team site**
- A **shared mailbox** (group mailbox)
- A **Teams team** (if Teams-enabled)
- A **Planner plan**

### Steps:
1. Go to **Groups → Active groups → + Add a Microsoft 365 group**
2. Name: `Delta Crown All Staff`
3. Group email: `all-staff`
4. Privacy: Private
5. Owners: `t-granlund` (or DCE admin account)
6. Members: Add synced DCE users
7. Repeat for each group

## Step 2: Configure SharePoint Sites

> **Portal**: [SharePoint Admin Center](https://admin.sharepoint.com) → DCE tenant

The M365 Group creation (Step 1) auto-creates SharePoint sites. Additional configuration:

### For Each Site:
1. Navigate to **Sites → Active sites** → Click the site
2. **Permissions**:
   - Site owners: DCE admins
   - Site members: All synced users (via M365 Group membership)
3. **Storage quota**: Set appropriate limit (default 25 TB per tenant)
4. **Sharing**: Set to "Only people in your organization" (recommended for internal use)

### Create Additional Document Libraries:
- `Policies & Procedures`
- `Project Files`
- `Templates`

## Step 3: Create and Configure Teams

> **Portal**: [Teams Admin Center](https://admin.teams.microsoft.com) → DCE tenant

### Option A: Team from Existing M365 Group (Recommended)
Since M365 Groups were created in Step 1, just "Teams-enable" them:

1. Open **Microsoft Teams** (signed into DCE tenant)
2. Click **Join or create a team → Create team → From a group or team → Microsoft 365 group**
3. Select the M365 Group (e.g., `Delta Crown All Staff`)
4. Configure channels:

| Channel | Purpose | Privacy |
|---------|---------|----------|
| General | Company announcements | Standard |
| Operations | Day-to-day operations | Standard |
| IT & Systems | Tech support, system access | Standard |
| Leadership | Executive discussions | Private |

### Option B: Shared Channels (B2B Direct Connect)
If you want HTT Brands users to access DCE channels **without switching tenants** in Teams:

1. In DCE Teams Admin Center → **Teams policies → Enable shared channels**
2. In the Team → Add channel → Channel type: **Shared**
3. Invite external participants from HTT Brands tenant

> **Note**: Shared channels require B2B Direct Connect configuration in cross-tenant access settings (similar to Phase 2 setup).

## Step 4: Create Distribution Lists (Optional)

> **Portal**: [Exchange Admin Center](https://admin.exchange.microsoft.com) → DCE tenant

For email-only groups that don't need SharePoint/Teams:

| Distribution List | Email | Purpose |
|------------------|-------|----------|
| DCE Notifications | `notifications@deltacrown.com` | System notifications |
| DCE Support | `support@deltacrown.com` | Customer-facing support |

1. Go to **Recipients → Groups → + Add a distribution list**
2. Configure name, email, and members
3. Set **Delivery management**: Allow senders inside and outside the org (if customer-facing)

## Validation Checklist

- [ ] All M365 Groups created with correct members
- [ ] SharePoint sites accessible to synced users
- [ ] Teams teams created and channels configured
- [ ] Synced users can post in Teams channels
- [ ] Synced users can access/upload SharePoint documents
- [ ] Distribution lists resolve correctly
