# Phase 5: DNS — SPF, DKIM & DMARC for deltacrown.com

## Overview

Configure email authentication DNS records for `deltacrown.com` to ensure emails sent from shared mailboxes are not rejected or marked as spam.

## Prerequisites

- [ ] Access to DNS hosting for `deltacrown.com`
- [ ] Exchange Online active in DCE tenant
- [ ] At least one shared mailbox created (Phase 4)

## Step 1: SPF (Sender Policy Framework)

SPF tells receiving mail servers which servers are authorized to send email for `deltacrown.com`.

### DNS Record:
| Type | Host/Name | Value | TTL |
|------|-----------|-------|-----|
| TXT | `@` | `v=spf1 include:spf.protection.outlook.com -all` | 3600 |

### Notes:
- `include:spf.protection.outlook.com` authorizes Microsoft 365
- `-all` = hard fail (reject unauthorized senders). Use `~all` (soft fail) initially if testing
- If deltacrown.com already has an SPF record, **merge** — don't create a second TXT record

## Step 2: DKIM (DomainKeys Identified Mail)

DKIM cryptographically signs outgoing emails to prove they haven't been tampered with.

### Step 2a: Get DKIM CNAME values
> **Portal**: Exchange Admin Center → DCE tenant → Email authentication → DKIM

1. Click on `deltacrown.com`
2. Note the two CNAME records displayed

### DNS Records:
| Type | Host/Name | Value | TTL |
|------|-----------|-------|-----|
| CNAME | `selector1._domainkey` | `selector1-deltacrown-com._domainkey.deltacrown.onmicrosoft.com` | 3600 |
| CNAME | `selector2._domainkey` | `selector2-deltacrown-com._domainkey.deltacrown.onmicrosoft.com` | 3600 |

> **Note**: The exact CNAME values may vary. Always copy from the Exchange Admin Center.

### Step 2b: Enable DKIM Signing
After DNS records propagate (can take up to 48 hours, typically 15-60 min):

1. Return to Exchange Admin Center → DKIM
2. Click on `deltacrown.com`
3. Toggle **Sign messages for this domain with DKIM signatures** → **Enabled**

**PowerShell**:
```powershell
Connect-ExchangeOnline -Organization deltacrown.com
# Check current status
Get-DkimSigningConfig -Identity deltacrown.com | Format-List
# Enable
Set-DkimSigningConfig -Identity deltacrown.com -Enabled $true
```

## Step 3: DMARC (Domain-based Message Authentication, Reporting & Conformance)

DMARC ties SPF and DKIM together and tells receiving servers what to do with failures.

### DNS Record:
| Type | Host/Name | Value | TTL |
|------|-----------|-------|-----|
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc-reports@deltacrown.com; ruf=mailto:dmarc-reports@deltacrown.com; pct=100` | 3600 |

### DMARC Policy Rollout:
1. **Start with `p=none`** (monitor only) — collect reports for 2-4 weeks
2. **Move to `p=quarantine`** — suspicious emails go to spam
3. **Final: `p=reject`** — unauthorized emails are rejected

Update the DNS record as you progress:
```
# Phase 1 (monitoring):
v=DMARC1; p=none; rua=mailto:dmarc-reports@deltacrown.com; pct=100

# Phase 2 (quarantine):
v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@deltacrown.com; pct=100

# Phase 3 (reject - full protection):
v=DMARC1; p=reject; rua=mailto:dmarc-reports@deltacrown.com; pct=100
```

## Step 4: Validate DNS Records

### Online Tools:
- [MXToolbox SPF Check](https://mxtoolbox.com/spf.aspx) — Enter `deltacrown.com`
- [MXToolbox DKIM Check](https://mxtoolbox.com/dkim.aspx) — Selector: `selector1`, Domain: `deltacrown.com`
- [MXToolbox DMARC Check](https://mxtoolbox.com/dmarc.aspx) — Enter `deltacrown.com`

### PowerShell (see `scripts/07-Validate-DNS-Records.ps1`):
```powershell
# SPF
Resolve-DnsName -Name "deltacrown.com" -Type TXT | Where-Object { $_.Strings -like "*spf*" }

# DKIM
Resolve-DnsName -Name "selector1._domainkey.deltacrown.com" -Type CNAME

# DMARC
Resolve-DnsName -Name "_dmarc.deltacrown.com" -Type TXT
```

### Email Test:
1. Send email from `@deltacrown.com` shared mailbox to a Gmail account
2. Open in Gmail → **Show original**
3. Verify:
   - `SPF: PASS`
   - `DKIM: PASS`
   - `DMARC: PASS`

## Summary of All DNS Records

| # | Type | Host | Value |
|---|------|------|-------|
| 1 | TXT | `@` | `v=spf1 include:spf.protection.outlook.com -all` |
| 2 | CNAME | `selector1._domainkey` | `selector1-deltacrown-com._domainkey.deltacrown.onmicrosoft.com` |
| 3 | CNAME | `selector2._domainkey` | `selector2-deltacrown-com._domainkey.deltacrown.onmicrosoft.com` |
| 4 | TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc-reports@deltacrown.com; pct=100` |

## Validation Checklist

- [ ] SPF TXT record added and resolves correctly
- [ ] DKIM CNAME records added and propagated
- [ ] DKIM signing enabled in Exchange Admin Center
- [ ] DMARC TXT record added (starting with `p=none`)
- [ ] Test email to external Gmail passes SPF/DKIM/DMARC
- [ ] MXToolbox shows all green for deltacrown.com
