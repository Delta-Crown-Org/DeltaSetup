# DCE Current State Summary — For Dustin Boyd

> **Date:** 2026-06-04  
> **Prepared by:** code-puppy-c70339 (Richard) for Tyler  
> **Purpose:** Validate Dustin's owner/license output against live tenant state and flag discrepancies.

---

## 1. What Dustin showed you

Dustin's script output shows 8 rows:

| Row | Person/Resource | Location | Role | License | Monthly Cost |
|-----|----------------|----------|------|---------|-------------|
| 1 | Allynn Shepherd | Livonia, MI | Owner | Basic | $8 |
| 2 | Amit Shah | Pittsburgh, PA | Owner | Basic | $8 |
| 3 | Toni Careccia | Pittsburgh, PA | Owner | Basic | $8 |
| 4 | Jay Miller | Lexington, OH | Owner | Basic | $8 |
| 5 | Sarah Miller | Lexington, OH | Owner | Basic | $8 |
| 6 | Colorado Springs | Colorado Springs, CO | SharedMailbox | Standard | $14.50 |
| 7 | Lindy Sturgill | Colorado Springs, CO | Salon Manager | Basic | $8 |

**Dustin's question:** "this seem correct? ... assumed we'd be charging the owners for this [shared mailbox]."

---

## 2. What's CORRECT in Dustin's output

### Owner list — 5 owners confirmed

| Owner | Location | Status |
|-------|----------|--------|
| Allynn Shepherd | Livonia, Michigan | Confirmed — franchisee owner per DCE metadata |
| Amit Shah | Pittsburgh, Pennsylvania | Confirmed — franchisee owner per DCE metadata |
| Toni Careccia | Pittsburgh, Pennsylvania | Confirmed — franchisee owner per DCE metadata |
| Jay Miller | Lexington, Ohio | Confirmed — franchisee owner per DCE metadata |
| Sarah Miller | Lexington, Ohio | Confirmed — franchisee owner per DCE metadata |

These 5 match the `franchise_owners@deltacrown.com` dynamic distribution group, which resolves to exactly these 5 users based on their Entra ID metadata (`Company = "Delta Crown Extensions"`, `Department = "Franchisee"`, `Title = "Owner"`).

**Verdict:** Dustin's owner list is accurate.

### Lindy Sturgill — correctly classified

| Field | Value |
|-------|-------|
| Name | Lindy Sturgill |
| Location | Colorado Springs, Colorado |
| Title | Salon Manager |
| Role | NOT an owner |
| License | Basic ($8) |

Lindy is a franchisee employee (not an owner) with `Department = "Salon Operations"`, `Title = "Salon Manager"`, `EmployeeType = "Franchisee"`. She is intentionally excluded from the `franchise_owners@` DDG because she is not an owner.

**Verdict:** Dustin correctly classified Lindy as non-owner Salon Manager.

---

## 3. What's WRONG or needs a flag

### CRITICAL: Colorado Springs mailbox — license assignment is incorrect

Dustin shows:
- **Type:** SharedMailbox
- **License:** Standard ($14.50/mo)
- **Owner:** Unknown Owner (Colorado Springs)

**The problem:** Shared mailboxes in Exchange Online do **NOT** require a license.

| Scenario | Should have license? | Monthly cost |
|----------|---------------------|-------------|
| SharedMailbox under 50GB, no archiving/hold | **NO** | **$0** |
| SharedMailbox with archiving or litigation hold | Yes (any M365 license) | $6–$22 |
| UserMailbox (real person) | Yes (required) | $6–$22 |

If Colorado Springs is truly a **SharedMailbox**, the $14.50/mo Standard license is **wasted money**. It should be removed immediately.

If Colorado Springs is meant to be a **UserMailbox** (for a real person at that location), then:
1. It should NOT be labeled "SharedMailbox"
2. It DOES need a license
3. It MUST have an assigned owner — "Unknown Owner" is a governance gap

**What I found in live inventory (2026-06-04):**
- `ColoradoSprings@deltacrown.com` exists as a **UserMailbox** (not SharedMailbox)
- Created: 2026-06-01 1:54 PM CT
- Last logon: 2026-06-01 7:18 PM CT (same day — someone logged in)
- 6 items of mail, 180.5 KB

**This conflicts with Dustin's output.** Either:
1. Dustin recently converted it to SharedMailbox after our inventory (possible — our inventory ran at 4:05 PM CT, Dustin's message at 4:15 PM CT)
2. Dustin's script is misclassifying it
3. There are two Colorado Springs mailboxes (unlikely)

**Recommendation for Dustin:**
- If Colorado Springs is a shared resource (studio mailbox, not a person): convert to SharedMailbox, **remove the $14.50 license**, save $174/year
- If Colorado Springs is a real person: keep as UserMailbox, keep the license, but **assign an owner** — "Unknown Owner" is not acceptable for governance

### Dustin thinks shared mailboxes cost money

Dustin said: "assumed we'd be charging the owners for this."

**This is incorrect.** Shared mailboxes are free. The only mailboxes that cost money are **UserMailboxes** (real people's mailboxes).

Current shared mailboxes in the DCE tenant (all free):
- `operations@deltacrown.com`
- `help@deltacrown.com` (converted from UserMailbox to SharedMailbox today — now free)
- `info@deltacrown.com`
- `careers@deltacrown.com` (discovered 2026-06-04, unplanned)
- `noreply@deltacrown.com` (discovered 2026-06-04, unplanned)
- `bookings@deltacrown.com` (deprecated, hidden, no longer used)

**Dustin should NOT assign licenses to shared mailboxes unless there's a specific need** (archiving, litigation hold, or >50GB storage).

---

## 4. SharePoint Hub State (for context)

### Hub sites (2) — LIVE
| Hub | URL | Status |
|-----|-----|--------|
| Corp Hub | `deltacrown.sharepoint.com/sites/corp-hub` | Registered, themed Gold/Black |
| DCE Hub | `deltacrown.sharepoint.com/sites/dce-hub` | Registered, themed Gold/Black |

### Spoke sites (4) — LIVE, associated to corp-hub
| Spoke | URL | Status |
|-------|-----|--------|
| corp-hr | `/sites/corp-hr` | Associated |
| corp-it | `/sites/corp-it` | Associated |
| corp-finance | `/sites/corp-finance` | Associated |
| corp-training | `/sites/corp-training` | Associated |

### DCE sites (4) — LIVE, associated to dce-hub
| Site | URL | Type | Status |
|------|-----|------|--------|
| dce-operations | `/sites/dce-operations` | Team Site | Associated |
| dce-clientservices | `/sites/dce-clientservices` | Team Site | Associated — **legacy, flagged for cleanup** |
| dce-marketing | `/sites/dce-marketing` | Communication | Associated |
| dce-docs | `/sites/dce-docs` | Document Center | Associated |

### Dynamic groups (5) — LIVE
| Group | Members | Purpose |
|-------|---------|---------|
| AllStaff | 6 | Broad DCE access |
| Managers | 1 | Manager-level access |
| Stylists | 0 | Stylist access (no stylists onboarded yet) |
| Marketing | 0 | Marketing access (no marketing staff onboarded yet) |
| External | 0 | Guest access (no guests yet) |

**Note:** Only 6 of 89 total tenant users have `companyName = "Delta Crown Extensions"` populated. The other 83 users are from other brands or unclassified and do NOT resolve into DCE dynamic groups. This is expected — the tenant is multi-brand.

---

## 5. What we're working on next (for Dustin's awareness)

| Priority | Item | Status | Owner |
|----------|------|--------|-------|
| P1 | Freshdesk brand portal setup for DCE | In progress — Tyler doing portal config | Tyler |
| P1 | Entra SSO app registration for Freshdesk | In progress — Azure portal | Tyler |
| P1 | `help.deltacrown.com` DNS CNAME | Pending — Cloudflare | Tyler |
| P2 | Email forwarding `help@` -> Freshdesk | Pending — needs Freshdesk ingestion address first | Tyler/Richard |
| P2 | Colorado Springs mailbox classification | Needs Dustin decision | Dustin |
| P2 | careers@ and noreply@ shared mailboxes | Unplanned — need owner intent | DCE team |
| P3 | dce-clientservices site cleanup | Legacy — deferred | DCE team |
| P3 | Auto-reply copy review | Pending owner review | DCE team |

---

## 6. What to tell KK

If Dustin is presenting this to KK (Kari/Kristin?), here's the summary:

1. **Owner list is accurate** — 5 franchise owners correctly identified.
2. **Lindy is correctly classified** — Salon Manager, not owner.
3. **Colorado Springs needs a decision** — is it a shared mailbox (free) or a user mailbox (needs license + owner)? Right now it's burning $14.50/mo potentially for no reason.
4. **Shared mailboxes are free** — don't assign licenses to `operations@`, `help@`, `info@`, `careers@`, `noreply@` unless there's a specific archiving/hold need.
5. **All 5 owners at Basic ($8) + Lindy at Basic ($8) = $48/mo** is the correct baseline. Colorado Springs should either be $0 (shared) or $14.50 with an assigned owner (user).

---

## 7. Quick math for Dustin

| Scenario | Monthly cost | Annual cost |
|----------|-------------|-------------|
| Current (Dustin's output) | $62.50 | $750 |
| If Colorado Springs is shared mailbox (no license) | $48 | $576 |
| Savings | **$14.50/mo** | **$174/yr** |

---

*Shared mailboxes are free. User mailboxes need licenses. Don't mix them up. — Richard*
