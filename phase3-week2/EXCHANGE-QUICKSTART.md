# Exchange Online Quick-Start Guide — deltacrown.com

> **Tenant:** deltacrown.com (`ce62e17d-2feb-4e67-a115-8ea4af68da30`)  
> **Script:** `phase3-week2/scripts/5.1-Exchange-Setup.ps1`  
> **Admin:** `tyler.granlund-admin@httbrands.com` (cross-tenant Global Admin)

---

## 1. Prerequisites Checklist

Before touching anything, make sure all of these are true:

- [ ] **PowerShell 7+** installed (`pwsh --version` → should show 7.x)
- [ ] **ExchangeOnlineManagement ≥ 3.0.0** module installed
  ```powershell
  Install-Module ExchangeOnlineManagement -MinimumVersion 3.0.0 -Scope CurrentUser
  ```
- [ ] **Microsoft.Graph.Authentication ≥ 2.0.0** module installed
  ```powershell
  Install-Module Microsoft.Graph.Authentication -MinimumVersion 2.0.0 -Scope CurrentUser
  ```
- [ ] **Global Admin access** on the deltacrown.com tenant via `tyler.granlund-admin@httbrands.com`
- [ ] **Pax8 CSP relationship** established for the DCE tenant (if not, see [Section 3](#3-if-exchange-online-is-not-active-yet))
- [ ] **At least one user with an Exchange Online license** — Lindy Sturgill (`lindy.sturgill@deltacrown.com`) is the recommended first user

**Verify modules are installed:**
```powershell
Get-Module -ListAvailable ExchangeOnlineManagement | Select-Object Version
Get-Module -ListAvailable Microsoft.Graph.Authentication | Select-Object Version
```

---

## 2. Pre-Flight Verification (READ-ONLY — safe to run anytime)

The `-VerifyOnly` flag runs a **read-only reconnaissance** of the deltacrown.com tenant. It connects to both Exchange Online and Microsoft Graph, checks what exists, and writes a report. It changes **nothing**.

**Run it:**
```bash
cd ~/dev/DeltaSetup/phase3-week2/scripts
pwsh -File ./5.1-Exchange-Setup.ps1 -VerifyOnly
```

**What happens:**
1. A browser window opens for Exchange Online auth → sign in as `tyler.granlund-admin@httbrands.com`
2. A second browser window opens for Microsoft Graph auth → sign in again
3. The script checks and reports on:
   - Whether Exchange Online is active (`Get-OrganizationConfig`)
   - Existing mailboxes (user + shared)
   - Existing distribution groups and dynamic distribution groups
   - Azure AD security groups (expects 4: AllStaff, Managers, Stylists, External)
   - Licensed users in the tenant

**How to interpret the output:**

| Line | Good ✅ | Needs Action ⚠️ |
|------|---------|-----------------|
| `Exchange Active` | `True` | `False` → need a licensed user first (see Section 3) |
| `Mailboxes Found` | ≥ 1 (Lindy's mailbox) | `0` → no licensed users yet |
| `Azure AD Groups` | 4 (AllStaff, Managers, Stylists, External) | < 4 → groups missing from Phase 2 |
| `Licensed Users` | ≥ 1 | `0` → Exchange won't activate without one |
| `Errors` | `0` | Any errors → read the message, fix, re-run |

**Report output:** Saved to `phase3-week2/docs/5.1-exchange-setup-results.json`

> **💡 Tip:** If Exchange Active shows `False`, stop here and complete Section 3 before proceeding.

---

## 3. If Exchange Online Is NOT Active Yet

Exchange Online doesn't just "turn on" when you create a tenant. It activates when **at least one user has an Exchange Online license assigned**. No license → no Exchange → the script can't create mailboxes or DDGs.

### Step 1: Establish the Pax8 CSP Relationship

If the Pax8 CSP (Cloud Solution Provider) partnership isn't set up for the deltacrown.com tenant yet, Tyler needs to send the request email to Megan.

**The email template is ready at:** [`templates/email-megan-csp-request.md`](../templates/email-megan-csp-request.md)

This email asks Megan for three things:
1. **CSP relationship** for the DCE tenant (ID: `ce62e17d-2feb-4e67-a115-8ea4af68da30`)
2. **Azure subscription** named `DCE-CORE`
3. **One M365 Business license** for Lindy Sturgill (`lindy.sturgill@deltacrown.com`)

**Recommended SKU:** M365 Business Basic ($6/user/mo) — sufficient to activate Exchange Online. Upgrade later if needed.

### Step 2: Assign the Exchange Online License

Once Megan provisions the license through Pax8, assign it to Lindy:

**Option A — M365 Admin Center (GUI):**
1. Go to [admin.microsoft.com](https://admin.microsoft.com)
2. Switch to the **Delta Crown Extensions** tenant
3. Navigate to **Users → Active users → Lindy Sturgill**
4. Click **Licenses and apps** → assign the M365 Business Basic (or Premium) license
5. Save

**Option B — PowerShell:**
```powershell
# Connect to Microsoft Graph for the DCE tenant
Connect-MgGraph -Scopes "User.ReadWrite.All" -TenantId "ce62e17d-2feb-4e67-a115-8ea4af68da30"

# Find available license SKUs
Get-MgSubscribedSku | Select-Object SkuPartNumber, SkuId, ConsumedUnits

# Assign to Lindy (replace <sku-id> with the actual SKU ID from above)
$userId = (Get-MgUser -Filter "userPrincipalName eq 'lindy.sturgill@deltacrown.com'").Id
Set-MgUserLicense -UserId $userId -AddLicenses @(@{SkuId = "<sku-id>"}) -RemoveLicenses @()
```

### Step 3: Wait for Exchange Activation

After assigning the license, Exchange Online can take **15–60 minutes** to fully provision. Re-run the pre-flight check to confirm:

```bash
pwsh -File ./5.1-Exchange-Setup.ps1 -VerifyOnly
```

When `Exchange Active` shows `True` and Lindy appears in the mailbox list, you're good to go.

---

## 4. Full Deployment

Once pre-flight passes (Exchange active, ≥ 1 licensed user, 4 Azure AD groups found), run the full deployment:

```bash
cd ~/dev/DeltaSetup/phase3-week2/scripts
pwsh -File ./5.1-Exchange-Setup.ps1
```

### What to Expect

| Step | What It Does | Time |
|------|-------------|------|
| **Step 1** | Connects to Exchange Online (browser auth prompt) | ~10s |
| **Step 2** | Connects to Microsoft Graph (browser auth prompt) | ~10s |
| **Step 3** | Creates 3 Dynamic Distribution Groups | ~15s |
| **Step 4** | Creates 3 Shared Mailboxes + sets permissions (Send-As & Full Access) | ~45s (includes 10s provisioning wait per mailbox) |
| **Step 5** | Configures auto-replies on `bookings@` and `info@` | ~10s |
| **Step 6** | Runs a verification sweep of everything just created | ~15s |

**Total expected runtime: ~2–3 minutes**

### Browser Prompts

You'll get **two** browser authentication prompts:
1. **Exchange Online** → sign in as `tyler.granlund-admin@httbrands.com`
2. **Microsoft Graph** → sign in as `tyler.granlund-admin@httbrands.com` again

Both connect cross-tenant to the deltacrown.com organization.

### What Gets Created

**3 Dynamic Distribution Groups:**
- `allstaff@deltacrown.com` — all DCE user mailboxes
- `managers@deltacrown.com` — DCE users with "Manager" in their title
- `stylists@deltacrown.com` — DCE users with "Stylist" in their title

**3 Shared Mailboxes:**
- `operations@deltacrown.com` — Send-As: AllStaff, Full Access: Managers
- `bookings@deltacrown.com` — Send-As: AllStaff, Full Access: AllStaff, auto-reply enabled
- `info@deltacrown.com` — Send-As: AllStaff, Full Access: Managers, auto-reply enabled

### Dry Run (WhatIf)

Want to see what _would_ happen without actually doing it?
```bash
pwsh -File ./5.1-Exchange-Setup.ps1 -WhatIf
```

### Results Output

Results are saved to `phase3-week2/docs/5.1-exchange-setup-results.json` with full details on what was created, permissions set, and any errors.

---

## 5. Post-Deployment Verification

After the script completes, manually verify everything landed correctly.

### Verify Dynamic Distribution Groups

```powershell
# Connect if not already connected
Connect-ExchangeOnline -UserPrincipalName tyler.granlund-admin@httbrands.com -Organization deltacrown.com

# List all DDGs
Get-DynamicDistributionGroup | Format-Table DisplayName, PrimarySmtpAddress, RecipientFilter -AutoSize

# Preview members of a DDG (shows who would receive mail)
$ddg = Get-DynamicDistributionGroup -Identity "allstaff@deltacrown.com"
Get-Recipient -RecipientPreviewFilter $ddg.RecipientFilter | Format-Table DisplayName, PrimarySmtpAddress
```

### Verify Shared Mailboxes

```powershell
# List all shared mailboxes
Get-Mailbox -RecipientTypeDetails SharedMailbox | Format-Table DisplayName, PrimarySmtpAddress -AutoSize

# Check permissions on each mailbox
@("operations@deltacrown.com", "bookings@deltacrown.com", "info@deltacrown.com") | ForEach-Object {
    Write-Host "`n=== $_ ===" -ForegroundColor Cyan

    Write-Host "Send-As:" -ForegroundColor Yellow
    Get-RecipientPermission -Identity $_ |
        Where-Object { $_.Trustee -ne "NT AUTHORITY\SELF" } |
        Format-Table Trustee, AccessRights

    Write-Host "Full Access:" -ForegroundColor Yellow
    Get-MailboxPermission -Identity $_ |
        Where-Object { $_.User -ne "NT AUTHORITY\SELF" -and -not $_.IsInherited } |
        Format-Table User, AccessRights
}
```

### Verify Auto-Replies

```powershell
@("bookings@deltacrown.com", "info@deltacrown.com") | ForEach-Object {
    Write-Host "`n=== $_ ===" -ForegroundColor Cyan
    Get-MailboxAutoReplyConfiguration -Identity $_ |
        Format-List AutoReplyState, InternalMessage, ExternalMessage
}
```

**Expected auto-replies:**
- `bookings@` → _"Thank you for contacting Delta Crown Extensions. We will confirm your booking within 24 hours."_
- `info@` → _"Thank you for contacting Delta Crown Extensions. We will respond within 48 hours."_
- `operations@` → No auto-reply (by design)

### Send Test Emails

1. From your personal Outlook, send a test email to `info@deltacrown.com`
2. You should receive the auto-reply within a few minutes
3. Check that the email appears in the shared mailbox (sign in as a user with Full Access, or use OWA)

---

## 6. Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| **"Exchange not active"** / `Get-OrganizationConfig` fails | No user has an Exchange Online license in the tenant | Assign a license to Lindy Sturgill first (see [Section 3](#3-if-exchange-online-is-not-active-yet)) |
| **Cross-tenant auth failure** | Missing `-Organization deltacrown.com` or admin doesn't have Exchange Admin role | Verify you're using `tyler.granlund-admin@httbrands.com` and that this account has Global Admin (which includes Exchange Admin) on deltacrown.com |
| **"Group not found"** when setting permissions | Azure AD groups (AllStaff, etc.) are security groups, not mail-enabled | Security groups work for mailbox permissions — this shouldn't error. If it does, verify the group exists: `Get-MgGroup -Filter "displayName eq 'AllStaff'"` |
| **"Mailbox already exists"** | Script is **idempotent** — it skips existing resources | Safe to re-run. The script checks for existing DDGs and mailboxes before creating them. |
| **Connection timeout / "session expired"** | Stale PowerShell sessions | Disconnect everything and retry: `Disconnect-ExchangeOnline -Confirm:$false; Disconnect-MgGraph` then re-run the script |
| **"Access denied" or 403** | Admin account lacks permissions on the DCE tenant | Verify Global Admin role assignment at [entra.microsoft.com](https://entra.microsoft.com) → switch to DCE tenant → Roles |
| **DDG shows 0 members** | Users don't have `Company` set to "Delta Crown Extensions" or matching `Title` | Check user attributes: `Get-User -Identity lindy.sturgill@deltacrown.com \| Select Company, Title` |
| **Script errors on module import** | DeltaCrown custom modules not found | This is fine — the script falls back to built-in logging. The warning is cosmetic. |

---

## 7. What Was Created (Reference)

### Dynamic Distribution Groups

| Name | Email | Recipient Filter |
|------|-------|-------------------|
| DCE All Staff | `allstaff@deltacrown.com` | `RecipientType = UserMailbox AND Company = "Delta Crown Extensions"` |
| DCE Managers | `managers@deltacrown.com` | `RecipientType = UserMailbox AND Company = "Delta Crown Extensions" AND Title like *Manager*` |
| DCE Stylists | `stylists@deltacrown.com` | `RecipientType = UserMailbox AND Company = "Delta Crown Extensions" AND Title like *Stylist*` |

### Shared Mailboxes

| Name | Email | Send-As | Full Access | Auto-Reply |
|------|-------|---------|-------------|------------|
| DCE Operations | `operations@deltacrown.com` | AllStaff | Managers | None |
| DCE Bookings | `bookings@deltacrown.com` | AllStaff | AllStaff | _"...confirm your booking within 24 hours."_ |
| DCE Info | `info@deltacrown.com` | AllStaff | Managers | _"...respond within 48 hours."_ |

### Native Users (4)

| User | Email |
|------|-------|
| Allynn Shepherd | `Allynn.Shepherd@deltacrown.com` |
| Jay Miller | `Jay.Miller@deltacrown.com` |
| Lindy Sturgill | `Lindy.Sturgill@deltacrown.com` |
| Sarah Miller | `Sarah.Miller@deltacrown.com` |

### Architecture Note

> Azure AD dynamic security groups (AllStaff, Managers, Stylists, External) handle SharePoint/Teams permissions. Exchange Dynamic Distribution Groups provide independent mail routing at `@deltacrown.com`. This hybrid group strategy gives maximum versatility on Business Premium licensing — shared mailboxes cost nothing extra.

---

_Guide created for DeltaSetup-102. Script version: 1.0.0._
