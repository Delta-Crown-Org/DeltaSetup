# Delta Crown Extensions — Freshdesk Provisioning Plan

> **Status:** Draft — pending owner review and live tenant auth  
> **Scope:** Add DCE as the 5th brand in the HTT Freshdesk support center  
> **Reference:** `FRESHDESK-ADMIN-PARITY-AUDIT.md` (4 brands live: HTT, BCC, TLL, Frenchies)  
> **Pattern:** Follow HTT + Frenchies (custom domain) rather than Bishops + TLL (freshdesk.com subdomain)  

---

## 1. Goal

Make Delta Crown Extensions a fully provisioned, SSO-enabled brand in the HTT Freshdesk support center with:
- `help@deltacrown.com` as the primary support email intake
- `help.deltacrown.com` as the custom portal domain
- Entra ID SSO for all DCE users
- Metadata inheritance (location, role, franchisee status) from Entra
- One FBC with visibility to all DCE tickets (location-agnostic for launch)
- Crown Connection (owners-only SharePoint spoke) as the gated knowledge base

---

## 2. Freshdesk Admin Work (requires Freshworks admin login)

### 2.1 Add DCE as the 5th Product/Brand

**Location:** Admin → Support Operations → Multiple Products

| Field | Value |
|---|---|
| Product Name | Delta Crown Extensions |
| Description | Hair extension franchise support |
| Portal URL | `help.deltacrown.com` (custom domain — see Section 3) |

**After creation, verify:**
- Product ID assigned (needed for routing rules)
- Default portal created under Channels → Portals

### 2.2 Configure Email Mailbox

**Location:** Admin → Channels → Email

| Field | Value |
|---|---|
| Email address | `help@deltacrown.com` |
| Forwarding target | Freshdesk ingestion endpoint (provided after mailbox creation) |
| Associated Group | "DCE Collaborators" (create new) or "Delta Crown Extensions" group |
| Associated Product | Delta Crown Extensions |

**Verification steps:**
1. Add `help@deltacrown.com` as a verified sender domain in Freshdesk
2. Configure SPF/DKIM for Freshdesk sending (Freshworks provides DNS records)
3. Set up email forwarding rule in Exchange Online (see Section 5.1)

### 2.3 Create DCE-Specific Groups

**Location:** Admin → Team → Groups

| Group | Members | Purpose |
|---|---|---|
| Delta Crown Collaborators | Initial: corporate ops + FBC | Primary ticket assignment pool |
| DCE Escalation Tier 2 | TBD | Escalations beyond initial response |

**Note:** The "one FBC for all locations" model means the FBC gets membership in the Collaborators group and ticket visibility via PSH RBAC, not via Freshdesk group membership alone.

### 2.4 Create Ticket Fields (Product-Scoped)

**Location:** Admin → Workflows → Ticket Fields

Reuse existing global fields where possible. DCE-specific additions:

| Field | Type | Values | Required |
|---|---|---|---|
| Location (DCE) | Dropdown | DCE-PHX, DCE-LV, DCE-Austin, ... | No (until locations populate) |
| System Category (DCE) | Dropdown | Operations, Marketing, Training, Mindbody, General | Yes |
| Franchisee Status | Dropdown | Owner, Manager, Stylist, Corporate | Yes |

**Important:** Per the parity audit, the Location field is the critical routing input for FBC visibility. Until the Entra user audit is complete (PSH dependency), this field may be under-populated.

### 2.5 Create Ticket Form (Portal Submission)

**Location:** Admin → Workflows → Ticket Forms

| Form | Fields | Portal |
|---|---|---|
| Submit a Request — Delta Crown | Subject, Description, Location (DCE), System Category (DCE), Franchisee Status, Attachments | DCE Portal |

### 2.6 Configure SLA Policy (Optional for Launch)

Per parity audit, SLA policies are flagged "skip" — only 1 active default exists across all brands. For DCE launch, the default SLA is acceptable.

### 2.7 Configure Canned Responses Folder

**Location:** Admin → Agent Productivity → Canned Responses

Create folder: "Delta Crown" — seeded with 3–5 starter responses for common franchisee questions.

---

## 3. Custom Domain Setup: `help.deltacrown.com`

### 3.1 Freshdesk Side

**Location:** Admin → Channels → Portals → DCE Portal → Custom Domain

1. Enter `help.deltacrown.com` as custom domain
2. Freshdesk generates a CNAME target (e.g., `customdomain.freshdesk.com`)
3. Copy the CNAME value

### 3.2 DNS Side (Cloudflare or DNS host for deltacrown.com)

Add DNS record:

```
Type: CNAME
Name: help
Target: [Freshdesk-provided CNAME target]
TTL: Auto
Proxy: DNS only (gray cloud — do NOT proxy through Cloudflare)
```

**Critical:** Do NOT orange-cloud this CNAME. Freshdesk requires direct DNS resolution. (This was the exact root cause of the Lash Lounge DKIM failure in `issues/2025-01-lashlounge-mindbody-email-auth.md`.)

### 3.3 SSL Certificate

Freshdesk auto-provisions SSL via Let's Encrypt once the CNAME resolves. Verify after 24 hours.

### 3.4 Verify

```bash
dig CNAME help.deltacrown.com +short
# Expected: [Freshdesk CNAME target]
```

---

## 4. SSO Setup — Entra ID → Freshdesk

### 4.1 Freshdesk Side

**Location:** Admin → Account → Security → SSO

1. Enable SSO
2. Select SAML SSO
3. Copy the ACS URL and Entity ID (needed for Entra app registration)

### 4.2 Entra Side (requires Global Admin on deltacrown.com)

**Option A: Manual Azure Portal**
1. Navigate to `entra.microsoft.com` → switch to Delta Crown Extensions tenant
2. App registrations → New registration
3. Name: `Freshdesk-DCE-SSO`
4. Supported account types: Accounts in this organizational directory only
5. Redirect URI: Web → paste ACS URL from Freshdesk
6. Register
7. Configure SAML:
   - Identifier (Entity ID): Freshdesk Entity ID
   - Reply URL (ACS): Freshdesk ACS URL
   - Sign-on URL: `https://help.deltacrown.com` (or `https://deltacrown.freshdesk.com` until custom domain is live)
8. Download certificate (Base64)
9. Copy Login URL and Azure AD Identifier

**Option B: PowerShell Script** (preferred — reproducible)

See `scripts/Register-FreshdeskDCE-SSO.ps1` (to be created in this repo).

### 4.3 Complete Freshdesk SAML Config

1. Paste Azure AD Identifier → IdP Entity ID
2. Paste Login URL → SAML SSO URL
3. Upload certificate
4. Set Name ID format: EmailAddress
5. Enable "Sign users in automatically"
6. Save

### 4.4 Map Entra Attributes → Freshdesk Contact Fields

| Entra Attribute | Freshdesk Contact Field | Purpose |
|---|---|---|
| `userPrincipalName` | Email | Primary identifier |
| `displayName` | Name | Contact name |
| `jobTitle` | Job Title | Role-based routing |
| `department` | Department | Franchisee vs corporate |
| `companyName` | Company | Brand affiliation |
| `officeLocation` | Location | FBC routing (critical) |
| `employeeType` | Custom: FranchiseeStatus | Owner/Manager/Stylist |

**Note:** The parity audit found that `companyName` is only set on 6 of 89 DCE users, and `officeLocation` on 22 of 89. The Entra user audit (`DeltaSetup-1b3`) MUST be complete before metadata-driven routing works at scale. For launch, manual location entry on tickets is acceptable.

---

## 5. Exchange Online Integration

### 5.1 Mail Flow: `help@deltacrown.com` → Freshdesk

**Two options:**

**Option A: Forwarding rule (simplest)**
```powershell
# Connect to Exchange Online for deltacrown.com
Connect-ExchangeOnline -UserPrincipalName tyler.granlund-admin@httbrands.com -DelegatedOrganization deltacrown.com

# Create transport rule: forward help@ to Freshdesk ingestion
New-TransportRule -Name "DCE-Help-To-Freshdesk" `
  -From "help@deltacrown.com" `
  -RedirectMessageTo "[Freshdesk-inbox-address]" `
  -Comments "Route DCE support email to Freshdesk"
```

**Option B: Shared mailbox + forwarding (recommended)**
```powershell
# Set forwarding on the help@ shared mailbox
Set-Mailbox -Identity "help@deltacrown.com" `
  -DeliverToMailboxAndForward $true `
  -ForwardingSmtpAddress "[Freshdesk-inbox-address]"
```

This preserves a copy in the Exchange shared mailbox for compliance/audit while also sending to Freshdesk.

### 5.2 Auto-Reply on `help@`

The auto-reply should acknowledge receipt AND direct users to the portal:

```
Thank you for contacting Delta Crown Extensions Support.

Your request has been received and assigned ticket #[Ticket ID].
Our team aims to respond within 24 hours.

For faster service and to track your request, visit:
https://help.deltacrown.com/support/tickets

Thank you,
Delta Crown Extensions Support Team
```

**Note:** Freshdesk can automatically append ticket numbers to auto-replies. Configure in Freshdesk → Admin → Workflows → Email Notifications → Requester tab.

---

## 6. PSH (People Support Hub) Integration

### 6.1 Add DCE to PSH Brand Registry

**File:** `~/dev/01-htt-brands/freshdesk-oracle/support-center-app/hub/config/brands.ts` (or equivalent)

```typescript
{
  id: 'dce',
  name: 'Delta Crown Extensions',
  shortName: 'Delta Crown',
  domain: 'deltacrown.com',
  freshdeskProductId: [TBD after creation],
  primaryColor: '#004538',
  supportEmail: 'help@deltacrown.com',
  portalUrl: 'https://help.deltacrown.com',
  entraTenantId: 'ce62e17d-2feb-4e67-a115-8ea4af68da30'
}
```

### 6.2 FBC Visibility Configuration

**Current model (one FBC for all locations):**

```typescript
// RBAC seed: FBC sees all DCE tickets regardless of location
{
  userId: 'jennifer.gregory@httbrands.com', // or whoever is the DCE FBC
  role: 'editor',
  brands: ['dce'], // scoped to DCE brand only
  locations: ['*'] // all locations — simplified for launch
}
```

**Future model (location-specific FBCs):**

Once the Entra location attribute is clean:
```typescript
{
  userId: 'fbcperson@httbrands.com',
  role: 'editor',
  brands: ['dce'],
  locations: ['DCE-PHX', 'DCE-LV'] // specific locations
}
```

### 6.3 Data Sync

**Current state:** PSH syncs Freshdesk tickets via API into Azure SQL.

**For DCE:** No code changes needed — the sync already pulls all tickets across all products. DCE tickets will appear in PSH once the Freshdesk product exists and tickets are created.

**Verification:** After first DCE ticket is created, run:
```bash
cd ~/dev/01-htt-brands/freshdesk-oracle
# Trigger manual sync or wait for scheduled sync
curl https://[psh-domain]/api/sync/status
```

---

## 7. Crown Connection (Owners-Only SharePoint Spoke)

### 7.1 Access Model

- **Audience:** DCE franchise owners only
- **Authentication:** Entra ID (same SSO as Freshdesk)
- **Authorization:** Membership derived from `employeeType = "Owner"` OR `Department = "Franchisee"` AND `Title = "Owner"`
- **Content:** Private KB articles, owner announcements, financial resources, operational updates

### 7.2 Link from Freshdesk

In the DCE portal, add a navigation link:

```
Label: "Owner Resources"
URL: https://deltacrown.sharepoint.com/sites/crown-connection
Visible to: Franchise Owners (via audience targeting)
```

**Note:** Audience targeting in Freshdesk portals requires Freshdesk SSO to be active (so it knows the user's role).

---

## 8. Implementation Order

| Step | Action | Owner | Blockers |
|---|---|---|---|
| 1 | Complete Entra user metadata cleanup (`DeltaSetup-1b3`) | Tyler + Dustin | None |
| 2 | Add DCE as Freshdesk product + create portal | Tyler (Freshworks admin) | None |
| 3 | Verify `help@deltacrown.com` mailbox exists | Already done | None |
| 4 | Configure email forwarding `help@` → Freshdesk | Tyler (Exchange admin) | Step 2 |
| 5 | Set up `help.deltacrown.com` custom domain | Tyler (DNS + Freshdesk) | Step 2 |
| 6 | Register Entra app for Freshdesk SSO | Tyler (Azure admin) | Step 2 |
| 7 | Configure SAML + attribute mapping | Tyler | Step 6 |
| 8 | Add DCE to PSH brand registry | Richard (code) | Step 2 |
| 9 | Seed FBC RBAC in PSH | Richard (code) | Step 8 |
| 10 | Configure Crown Connection audience targeting | Tyler/Dustin (SharePoint) | Step 1 |
| 11 | E2E test: submit ticket via email + portal + verify in PSH | Tyler + FBC | Steps 1–9 |

---

## 9. Pre-Flight Checklist (before any live changes)

- [ ] `help@deltacrown.com` mailbox exists and is accessible
- [ ] Freshworks admin access confirmed (tyler.granlund@httbrands.com)
- [ ] Azure Global Admin access on deltacrown.com tenant confirmed
- [ ] DNS management access for deltacrown.com confirmed
- [ ] PSH Azure deploy access confirmed
- [ ] DCE FBC identified and has Entra account
- [ ] Crown Connection SharePoint site exists (or creation planned)

---

## 10. Rollback Plan

If any step fails:

1. **Email:** Remove forwarding rule, restore `help@` as standalone mailbox
2. **Freshdesk:** Disable DCE product (hides portal but preserves tickets)
3. **SSO:** Disable SAML in Freshdesk, revert to password auth
4. **Custom domain:** Remove CNAME, revert to freshdesk.com subdomain
5. **PSH:** Remove DCE brand from registry (tickets remain in DB but are invisible)

All changes are additive before Step 11 (E2E test). No destructive ops until final go-live.

---

*Plan created by code-puppy-c70339 / Richard. Review with Tyler before execution.*
