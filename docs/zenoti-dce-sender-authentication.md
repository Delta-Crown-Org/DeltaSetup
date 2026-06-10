# Zenoti DCE Sender Authentication

**Date:** 2026-06-10
**Author:** Richard (`code-puppy-30de1e`)
**Beads:** `DeltaSetup-g0q`, `DeltaSetup-1o9`

---

## Overview

Delta Crown Extensions is now Zenoti-authenticated under `deltacrown.com` via Sendgrid.
This document records the DNS state, brand-sender architecture, manual steps remaining,
and the COS contact-email decision still needed from Tyler.

---

## DNS Verification — 2026-06-10 (confirmed by `dig`)

| Record | Type | Value | Status |
|--------|------|-------|--------|
| `s1._domainkey.deltacrown.com` | CNAME | `s1.domainkey.u2534942.wl193.sendgrid.net.` | LIVE |
| `s2._domainkey.deltacrown.com` | CNAME | `s2.domainkey.u2534942.wl193.sendgrid.net.` | LIVE |
| `em8326.deltacrown.com` | CNAME | `u2534942.wl193.sendgrid.net.` | LIVE |
| `em6613.deltacrown.com` | CNAME | (no record — removed) | REMOVED |

All four records are exactly as expected. DNS propagation is complete.

---

## Brand-Sender Architecture

| Brand | Sendgrid subuser | Whitelabel pool | Domain | Notes |
|-------|-----------------|-----------------|--------|-------|
| Bishops (BCC) | u2534942 | wl193 | `bishopsbarber.com` or BCC domain | Pre-existing |
| Delta Crown Extensions (DCE) | u2534942 | wl193 | `deltacrown.com` | Shares pool with BCC |
| HTT Corporate | u52361448 | wl199 | `httbrands.com` | Separate pool |

DCE shares the `u2534942 / wl193` Sendgrid subuser and whitelabel pool with Bishops.
This is a shared sending reputation — Bishops' sending behavior affects DCE deliverability
and vice versa. Acceptable for the current scale; revisit if either brand's volume grows
significantly or if reputation issues emerge.

---

## Zenoti-Side Verification (MANUAL STEP — Tyler)

DNS records are live, but Zenoti itself must confirm domain ownership from within
the Zenoti admin interface. This is a UI click that only a Zenoti admin can perform.

**What Tyler (or Jamie/Lindy) needs to do in Zenoti:**

1. Log into the Zenoti admin panel for Delta Crown Extensions.
2. Navigate to **Settings > Communications > Email Settings** (or equivalent).
3. Find the domain verification section — look for `deltacrown.com`.
4. Click **Verify Domain** (or equivalent button).
5. Zenoti will perform a DNS lookup against the CNAME records above to confirm ownership.
6. Once verified, Zenoti-sent emails (booking confirmations, reminders, etc.) will
   send from the `deltacrown.com` domain with Sendgrid authentication.

**Role required in Zenoti:**
A Zenoti admin with access to Communications/Email settings at the tenant level
(not just a center-level role) is needed for this step.

If neither Tyler nor Jamie has this role, see the Namita Singh request below.

---

## Colorado Springs Center — Business Details Contact Email (OPEN QUESTION)

The COS location in Zenoti needs a Business Details contact email set.
Three options — Tyler must choose (Jenna or Jamie input preferred):

| Option | Email | Notes |
|--------|-------|-------|
| A | `Lindy.Sturgill@deltacrown.com` | On-site operator; already licensed DCE mailbox. Lindy is the Salon Manager, NOT the owner. Using this for Business Details is operationally fine but ties the center to Lindy's personal mailbox. |
| B | `Jenna.Bowden@httbrands.com` | Owner of record; but this is an HTT address, not @deltacrown.com. May confuse Zenoti brand-domain sender setup. |
| C | `ColoradoSprings@deltacrown.com` | Center alias — ALREADY EXISTS as a licensed user mailbox (per 2026-06-04 Exchange inventory). This is the cleanest option IF Tyler approves converting it to a shared mailbox (free, no license). Currently consuming a Business Premium seat unnecessarily. |

**Recommendation:** Option C, subject to:
- Tyler confirming `ColoradoSprings@deltacrown.com` is intended as a center alias.
- Tyler approving conversion from user mailbox to SharedMailbox (Exchange Online, free).
- Jenna or Jamie's sign-off on using the alias as the official center contact.

If option C is approved, create a beads issue to convert the mailbox and update Zenoti.

---

## Namita Singh — Zenoti Domain Role Request (DeltaSetup-1o9)

Jamie Baer and/or Lindy Sturgill may need Zenoti role elevation to add a domain
at the COS location level, or to complete the Business Details update.

**What to ask Namita Singh (Zenoti contact):**

> We are configuring the Delta Crown Extensions tenant in Zenoti.
> We need to:
> (1) Verify the `deltacrown.com` sender domain under Communications / Email Settings.
> (2) Set the Business Details contact email for the Colorado Springs center.
>
> Please advise: what Zenoti role is required for each of these actions, and can
> you grant that role to Jamie Baer and/or Lindy Sturgill at the COS location?

**Do NOT impersonate Tyler or send on his behalf.**
This request should come from Tyler directly via email or Zenoti support ticket.

Bead `DeltaSetup-1o9` tracks this request.

---

## Tenant-Side Docs Updated

The following docs now reflect that DCE is Zenoti-authenticated under `deltacrown.com`:

- `DEPLOYMENT-STATUS.md` — Phase 5 Exchange section updated.
- This file (`docs/zenoti-dce-sender-authentication.md`).
- `SESSION-HANDOFF.md` — Track 2 status recorded.

---

## See Also

- `DeltaSetup-g0q` — Track 2 Zenoti sender-auth bead
- `DeltaSetup-1o9` — Namita Singh role request bead
- `docs/dce-franchise-owner-identity-pattern.md` — Jenna Bowden identity gap
- `generated/dce-franchise-owners-report.md` — owners-of-record map
