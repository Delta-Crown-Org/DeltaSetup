---
name: validate-dns
description: Validate SPF, DKIM, and DMARC DNS records for deltacrown.com and explain results
user_invocable: true
---

# DNS Record Validator — deltacrown.com

You are helping the user validate email authentication DNS records for the DCE tenant domain.

## Steps

1. **Read context**: Read `config/tenant-config.json` to get the target domain (deltacrown.com) and `docs/05-dns-spf-dkim-dmarc.md` for reference documentation.

2. **Run DNS lookups** using `dig` or `nslookup` (available on macOS) to check these records:

   - **SPF**: `dig TXT deltacrown.com` — look for `v=spf1 ... include:spf.protection.outlook.com ... -all`
   - **DKIM selector1**: `dig CNAME selector1._domainkey.deltacrown.com`
   - **DKIM selector2**: `dig CNAME selector2._domainkey.deltacrown.com`
   - **DMARC**: `dig TXT _dmarc.deltacrown.com` — look for `v=DMARC1`
   - **MX**: `dig MX deltacrown.com` — should point to `*.mail.protection.outlook.com`

   If `dig` is unavailable, try `nslookup`. If neither works, offer to run `scripts/07-Validate-DNS-Records.ps1` via PowerShell instead.

3. **Display results** in a table with Pass/Warn/Fail status for each record.

4. **Explain each record** briefly:
   - **SPF** — Tells receiving servers which IPs can send mail for this domain. Must include Microsoft 365's SPF.
   - **DKIM** — Cryptographic signatures that prove mail wasn't tampered with. Two selectors provide key rotation.
   - **DMARC** — Policy that tells receivers what to do when SPF/DKIM fail (none/quarantine/reject).
   - **MX** — Mail routing. Must point to Microsoft 365 for mail to flow correctly.

5. **For any failures**, explain what's missing and reference `docs/05-dns-spf-dkim-dmarc.md` for the fix procedure (usually involves adding records in the domain registrar's DNS panel).
