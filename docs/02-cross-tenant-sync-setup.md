# Phase 2: Entra ID Cross-Tenant Synchronization

## Overview

This phase configures **Entra ID Cross-Tenant Synchronization** to automatically sync user accounts from the HTT Brands tenant (source) to the Delta Crown Extensions tenant (target). Synced users will be **Member-type** accounts with access to DCE SharePoint, Teams, and email groups.

## Prerequisites

- [ ] Global Admin on **both** tenants
- [ ] Microsoft 365 Business Premium active on both tenants (includes Entra ID P1)
- [ ] Decide which users to sync (security group based)

## Cost: $0
Cross-tenant sync is included with Entra ID P1, which is bundled in Microsoft 365 Business Premium.

## Step 1: Configure Cross-Tenant Access (DCE Tenant — Target/Resource)

> **Portal**: [Entra Admin Center](https://entra.microsoft.com) → Switch to **DCE tenant**

1. Navigate to **Identity → External Identities → Cross-tenant access settings**
2. Click **+ Add organization**
3. Enter the HTT Brands tenant ID: `0c0e35dc-188a-4eb3-b8ba-61752154b407`
4. Click **Add**
5. Click on the newly added **HTT Brands** row → **Inbound access**

### Inbound Access — B2B Collaboration Tab:
- **Users and groups**: Allow access → All users (or specific groups)
- **Applications**: Allow access → All applications

### Inbound Access — Trust Settings Tab:
- ✅ Trust multi-factor authentication from this tenant
- ✅ Trust compliant devices from this tenant
- ✅ Trust Microsoft Entra hybrid joined devices from this tenant

### Inbound Access — Cross-tenant sync Tab:
- ✅ **Allow users sync into this tenant** → Toggle to **Yes**

### Automatic Redemption:
- ✅ **Automatically redeem invitations** with tenant `0c0e35dc-...` → Toggle to **Yes**

## Step 2: Configure Cross-Tenant Access (HTT Brands Tenant — Source)

> **Portal**: [Entra Admin Center](https://entra.microsoft.com) → Switch to **HTT Brands tenant**

1. Navigate to **Identity → External Identities → Cross-tenant access settings**
2. Click **+ Add organization** (if DCE not already listed)
3. Enter the DCE tenant ID: `ce62e17d-2feb-4e67-a115-8ea4af68da30`
4. Click on the DCE row → **Outbound access**

### Outbound Access — B2B Collaboration Tab:
- **Users and groups**: Allow access → Select the sync security group (created in Step 3)
- **Applications**: Allow access → All applications

### Automatic Redemption:
- ✅ **Automatically redeem invitations** with tenant `ce62e17d-...` → Toggle to **Yes**

## Step 3: Create the Sync Security Group (HTT Brands Tenant)

> **Portal**: Entra Admin Center → HTT Brands → Groups

1. Create a new **Security Group**:
   - Name: `SG-DCE-Sync-Users`
   - Description: `Users synchronized to the Delta Crown Extensions tenant`
   - Membership type: **Assigned** (add users manually) or **Dynamic** (rule-based)
   - Group owner: `t-granlund@httbrands.com`

2. Add the users who need DCE access as members

**PowerShell alternative** (see `scripts/02-Configure-CrossTenantAccess.ps1`):
```powershell
Connect-MgGraph -TenantId "0c0e35dc-188a-4eb3-b8ba-61752154b407" -Scopes "Group.ReadWrite.All"
New-MgGroup -DisplayName "SG-DCE-Sync-Users" `
    -Description "Users synchronized to the Delta Crown Extensions tenant" `
    -MailEnabled:$false `
    -SecurityEnabled:$true `
    -MailNickname "sg-dce-sync-users"
```

## Step 4: Create the Cross-Tenant Sync Configuration (HTT Brands Tenant)

> **Portal**: Entra Admin Center → HTT Brands → Cross-tenant synchronization

1. Navigate to **Identity → External Identities → Cross-tenant synchronization**
2. Click **Configurations** → **+ New configuration**
3. Name: `HTT-to-DCE-User-Sync`
4. Click **Create**

### Provisioning Settings:
1. Click on the new configuration → **Provisioning**
2. Provisioning Mode: **Automatic**
3. **Admin Credentials**:
   - Tenant URL: Auto-populated for DCE tenant
   - Click **Authorize** → Sign in with DCE Global Admin credentials
   - Click **Test Connection** → Verify success
4. Click **Save**

### Scope:
1. Go to **Users and groups** → **+ Add user/group**
2. Select the `SG-DCE-Sync-Users` group
3. Scope: **Sync only assigned users and groups**

### Attribute Mappings:
Navigate to **Provisioning → Mappings → Provision Microsoft Entra ID Users**

Ensure these critical mappings:

| Source Attribute | Target Attribute | Type | Notes |
|------------------|------------------|------|-------|
| `userPrincipalName` | `userPrincipalName` | Direct | |
| `displayName` | `displayName` | Direct | |
| `mail` | `mail` | Direct | |
| `givenName` | `givenName` | Direct | |
| `surname` | `surname` | Direct | |
| `jobTitle` | `jobTitle` | Direct | |
| `department` | `department` | Direct | |
| `"Member"` | `userType` | **Constant** | ⚠️ **CRITICAL — Must be "Member", NOT "Guest"** |
| `true` | `showInAddressList` | Constant | Makes users visible in DCE address book |

**⚠️ The `userType = "Member"` mapping is the most important setting.** Without it, users sync as Guest-type and have limited access.

### Start Provisioning:
1. Return to the configuration overview
2. Click **Start provisioning**
3. Monitor **Provisioning logs** for success/failure

## Step 5: Validate Sync

After initial sync cycle (can take 20-40 minutes):

1. Switch to the **DCE tenant** → Entra Admin Center → Users → All users
2. Verify synced users appear with:
   - **User type**: Member
   - **Source**: External Microsoft Entra ID
   - **Creation type**: Invitation

**PowerShell validation**:
```powershell
Connect-MgGraph -TenantId "ce62e17d-2feb-4e67-a115-8ea4af68da30" -Scopes "User.Read.All"
Get-MgUser -Filter "userType eq 'Member' and creationType eq 'Invitation'" | 
    Select-Object DisplayName, UserPrincipalName, UserType, CreationType |
    Format-Table -AutoSize
```

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Users sync as Guest | `userType` mapping missing or set to "Guest" | Update attribute mapping to Constant "Member" |
| Sync fails with 403 | Missing admin consent in target tenant | Re-authorize in provisioning settings |
| Users not appearing | Scope set wrong or group empty | Verify `SG-DCE-Sync-Users` has members and is assigned to config |
| Duplicate users | User already exists as guest in DCE | Convert guest to member or delete guest account first |
