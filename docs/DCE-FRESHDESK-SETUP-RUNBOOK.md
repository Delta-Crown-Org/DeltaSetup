# DCE Freshdesk Portal — Step-by-Step Setup Runbook

> **Status:** Ready for execution (scripts staged, values pending from Freshdesk)  
> **Prepared by:** code-puppy-c70339 (Richard)  
> **Date:** 2026-06-04  
> **Prerequisite:** All scripts in `scripts/` are syntax-checked and ready

---

## What this is

A sequenced checklist to add Delta Crown Extensions as the **5th brand** in the HTT Freshdesk support center, with Entra SSO, custom domain, and `help@deltacrown.com` email intake.

**Time estimate:** 2–3 hours (mostly waiting for DNS propagation + SSL issuance)

---

## Pre-Flight (do these first)

- [ ] You have Freshworks admin access (`tyler.granlund@httbrands.com`)
- [ ] You have Azure Global Admin on DCE tenant (`tyler.granlund-admin@httbrands.com`)
- [ ] You have DNS management access for `deltacrown.com` (Cloudflare)
- [ ] Azure CLI is installed and you are logged in (`az account show` shows HTT-CORE)
- [ ] PowerShell 7 + ExchangeOnlineManagement module installed

**Quick check:**
```bash
az account show --query "user.name" -o tsv
# Expected: tyler.granlund-admin@httbrands.com

pwsh -Command "Get-Module ExchangeOnlineManagement -ListAvailable"
# Expected: 3.0.0 or higher
```

---

## Phase 1: Freshdesk Product Setup (you do this in browser)

### Step 1.1 — Create DCE Product

**Where:** `httbrandsorg.freshdesk.com/a/admin/products`

| Field | Value |
|-------|-------|
| Product Name | Delta Crown Extensions |
| Description | Hair extension franchise support |

**Click Save.** Note the Product ID (shown in the URL after saving, e.g. `.../products/160000XXXX`).

### Step 1.2 — Create Support Groups

**Where:** `httbrandsorg.freshdesk.com/a/admin/people/groups`

| Group Name | Members (for now) |
|------------|-------------------|
| Delta Crown Collaborators | You + whoever will be the FBC |
| DCE Escalation Tier 2 | Leave empty for now |

### Step 1.3 — Configure Email Channel

**Where:** `httbrandsorg.freshdesk.com/a/admin/channels/email`

1. Click **Add Mailbox**
2. Email address: `help@deltacrown.com`
3. Product: Delta Crown Extensions
4. Group: Delta Crown Collaborators
5. **Copy the ingestion email address** — it looks like:
   `support+dce_xxxxxx@deltacrown.freshdesk.com` or similar
   
   **This is CRITICAL.** You need this for Phase 3.

### Step 1.4 — Get SSO Values

**Where:** `httbrandsorg.freshdesk.com/a/admin/security/sso`

1. Enable SSO (if not already)
2. Select **SAML SSO**
3. **Copy these two values:**
   - **ACS URL** (e.g. `https://deltacrown.freshdesk.com/login/saml`)
   - **Entity ID** (e.g. `https://deltacrown.freshdesk.com`)

   **These are CRITICAL.** You need them for Phase 2.

**Checkpoint:** You should now have:
- [ ] Product ID
- [ ] Ingestion email address
- [ ] ACS URL
- [ ] Entity ID

---

## Phase 2: Entra SSO App Registration (script does this)

### Step 2.1 — Verify Azure CLI tenant

```bash
az login --tenant ce62e17d-2feb-4e67-a115-8ea4af68da30
# Browser opens — sign in with tyler.granlund-admin@httbrands.com

az account show --query "tenantId" -o tsv
# Expected: ce62e17d-2feb-4e67-a115-8ea4af68da30
```

### Step 2.2 — Run the SSO registration script

```powershell
cd ~/dev/DeltaSetup/scripts
pwsh -File Register-FreshdeskDCE-SSO.ps1 `
  -FreshdeskAcsUrl "PASTE_ACS_URL_HERE" `
  -FreshdeskEntityId "PASTE_ENTITY_ID_HERE"
```

**The script will:**
1. Create app registration `Freshdesk-DCE-SSO`
2. Generate a self-signed certificate for SAML signing
3. Configure optional claims (email, givenName, surname)
4. Output three values you need for Freshdesk:
   - **Login URL**
   - **Azure AD Identifier**
   - **Certificate (Base64)**

5. Save a JSON report file (`freshdesk-dce-sso-report-*.json`)

**Checkpoint:** The script output shows the Login URL, Identifier, and certificate.

### Step 2.3 — Paste values into Freshdesk

**Where:** Back in Freshdesk — Admin — Security — SSO

| Freshdesk Field | Value from Script Output |
|-----------------|--------------------------|
| SAML SSO URL | Login URL |
| IdP Entity ID | Azure AD Identifier |
| Certificate | Copy the Base64 block, save as `.cer`, upload |
| Name ID Format | `EmailAddress` |
| Sign algorithm | `SHA-256` |

Click **Save**.

**Test:** In a private browser window, go to `https://deltacrown.freshdesk.com` and click "Sign in with SSO." You should be redirected to Microsoft login.

---

## Phase 3: Email Forwarding (script does this)

### Step 3.1 — Create Exchange Transport Rule

```powershell
cd ~/dev/DeltaSetup/scripts
pwsh -File New-DCEFreshdeskTransportRule.ps1 `
  -FreshdeskIngestionAddress "PASTE_INGESTION_ADDRESS_HERE"
```

**What this does:**
- Creates a transport rule named `Freshdesk support forwarding - Delta Crown Extensions`
- Any email sent to `help@deltacrown.com` gets redirected to Freshdesk
- Copies also land in the `help@` shared mailbox (compliance)

**Alternative:** If you prefer mailbox-level forwarding instead:
```powershell
pwsh -File Set-DCEHelpMailboxForwarding.ps1 `
  -FreshdeskIngestionAddress "PASTE_INGESTION_ADDRESS_HERE"
```

### Step 3.2 — Update Auto-Reply on help@

```powershell
pwsh -Command @"
  Connect-ExchangeOnline -UserPrincipalName 'tyler.granlund-admin@httbrands.com' -DelegatedOrganization 'deltacrown.onmicrosoft.com' -ShowBanner:\$false
  Set-MailboxAutoReplyConfiguration -Identity 'help@deltacrown.com' `
    -AutoReplyState Enabled `
    -ExternalAudience All `
    -InternalMessage 'Thank you for contacting Delta Crown Extensions Support. Your request has been received and our team aims to respond within 24 hours. For faster service, visit https://help.deltacrown.com/support/tickets' `
    -ExternalMessage 'Thank you for contacting Delta Crown Extensions Support. Your request has been received and our team aims to respond within 24 hours. For faster service, visit https://help.deltacrown.com/support/tickets'
  Disconnect-ExchangeOnline -Confirm:\$false
"@
```

---

## Phase 4: Custom Domain (DNS + Freshdesk)

### Step 4.1 — Configure Custom Domain in Freshdesk

**Where:** Freshdesk — Admin — Channels — Portals — DCE Portal — Custom Domain

1. Enter `help.deltacrown.com`
2. Freshdesk shows you a **CNAME target** (e.g. `customdomain.freshdesk.com`)
3. **Copy the CNAME target**

### Step 4.2 — Add DNS Record in Cloudflare

**Where:** Cloudflare dashboard — deltacrown.com — DNS — Records

| Type | Name | Target | Proxy status | TTL |
|------|------|--------|-------------|-----|
| CNAME | `help` | `PASTE_CNAME_TARGET_HERE` | **DNS only (gray cloud)** | Auto |

**CRITICAL:** Gray cloud only. Do NOT orange-cloud this record. Freshdesk needs direct DNS resolution.

### Step 4.3 — Verify DNS

```bash
# Wait 5–15 minutes, then:
dig CNAME help.deltacrown.com +short
# Expected: your CNAME target
```

### Step 4.4 — Verify SSL

Freshdesk auto-provisions SSL via Let's Encrypt. Check after 24 hours:
```bash
curl -I https://help.deltacrown.com
# Expected: HTTP/2 200
```

---

## Phase 5: PSH Integration (code change)

### Step 5.1 — Add DCE to PSH Brand Registry

**File:** `~/dev/01-htt-brands/freshdesk-oracle/support-center-app/hub/config/brands.ts`

Add this object to the brands array:

```typescript
{
  id: 'dce',
  name: 'Delta Crown Extensions',
  shortName: 'Delta Crown',
  domain: 'deltacrown.com',
  freshdeskProductId: 'PASTE_PRODUCT_ID_HERE',
  primaryColor: '#03534D',
  supportEmail: 'help@deltacrown.com',
  portalUrl: 'https://help.deltacrown.com',
  entraTenantId: 'ce62e17d-2feb-4e67-a115-8ea4af68da30'
}
```

### Step 5.2 — Deploy PSH Update

```bash
cd ~/dev/01-htt-brands/freshdesk-oracle
# Standard deploy flow (Git push + CI/CD or manual)
```

---

## Phase 6: E2E Test

### Step 6.1 — Email Test

1. Send an email to `help@deltacrown.com` from your personal email
2. Check Freshdesk — Tickets — a new ticket should appear within 1–2 minutes
3. Verify the ticket is assigned to "Delta Crown Extensions" product

### Step 6.2 — Portal Test

1. Open `https://help.deltacrown.com` in a private window
2. Click "Sign in with SSO"
3. Sign in with a DCE user account (e.g. `Allynn.Shepherd@deltacrown.com`)
4. You should land in the DCE portal
5. Submit a test ticket

### Step 6.3 — PSH Sync Test

1. Wait for PSH scheduled sync (or trigger manually)
2. Check PSH dashboard for DCE tickets
3. Verify the FBC can see the ticket

---

## Rollback (if anything breaks)

### Roll back email forwarding
```powershell
pwsh -Command "
  Connect-ExchangeOnline -UserPrincipalName 'tyler.granlund-admin@httbrands.com' -DelegatedOrganization 'deltacrown.onmicrosoft.com'
  Remove-TransportRule -Identity 'Freshdesk support forwarding - Delta Crown Extensions' -Confirm:`$false
  Disconnect-ExchangeOnline -Confirm:`$false
"
```

### Roll back SSO
1. Freshdesk — Admin — Security — SSO — Disable
2. Azure Portal — App registrations — `Freshdesk-DCE-SSO` — Delete

### Roll back custom domain
1. Remove CNAME from Cloudflare
2. Freshdesk — Admin — Channels — Portals — remove custom domain

---

## Scripts Reference

| Script | Purpose | Parameters |
|--------|---------|------------|
| `scripts/Register-FreshdeskDCE-SSO.ps1` | Create Entra app for SAML | `-FreshdeskAcsUrl`, `-FreshdeskEntityId` |
| `scripts/New-DCEFreshdeskTransportRule.ps1` | Exchange transport rule for email forwarding | `-FreshdeskIngestionAddress` |
| `scripts/Set-DCEHelpMailboxForwarding.ps1` | Alternative: mailbox-level forwarding | `-FreshdeskIngestionAddress` |

---

## Values You Need to Paste

Fill this in as you go:

| Value | Source | Your Value |
|-------|--------|------------|
| Freshdesk Product ID | Freshdesk Admin — Products | _________________ |
| Freshdesk Ingestion Email | Freshdesk Admin — Email Channels | _________________ |
| Freshdesk ACS URL | Freshdesk Admin — SSO | _________________ |
| Freshdesk Entity ID | Freshdesk Admin — SSO | _________________ |
| Freshdesk CNAME Target | Freshdesk Admin — Custom Domain | _________________ |
| Entra Login URL | Script output | _________________ |
| Entra Azure AD Identifier | Script output | _________________ |
| Entra Certificate Thumbprint | Script output | _________________ |

---

*Ready when you are, Tyler. Run Phase 1, grab the values, then we execute the scripts.*