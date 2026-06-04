# Delta Crown Extensions — Email + Domain Level-Set & Fresh Poll

> **Date:** 2026-06-02 (refreshed 2026-06-04 with live inventory)  
> **Auditor:** code-puppy-c70339 (Richard)  
> **Scope:** DCE tenant Exchange + DNS domain publish state vs. other HTT brand standard  
> **Method:** Repo evidence audit + raw-data inspection + shared-brand registry cross-check + LIVE tenant inventory (2026-06-04)

---

## 1. What exists today — Exchange Online

### Accepted domains (from raw evidence: 2026-04-30)
| Domain | Type | Default | Status |
|---|---|---|---|
| `deltacrown.com` | Authoritative | **Yes** |  Live |
| `deltacrown.onmicrosoft.com` | Authoritative | No |  Live |

### Shared mailboxes (6) — from live inventory 2026-06-04
| Mailbox | Email | Send-As | Full Access | Auto-Reply | Status |
|---|---|---|---|---|---|
| DCE Operations | `operations@deltacrown.com` | AllStaff | Managers | None |  Live |
| DCE Help | `help@deltacrown.com` | AllStaff | AllStaff | 24hr support ack |  Live — converted from UserMailbox to SharedMailbox 6/4/2026 |
| DCE Info | `info@deltacrown.com` | AllStaff | Managers | 48hr response |  Live |
| DCE Bookings (deprecated) | `bookings@deltacrown.com` | None | None | Disabled | Hidden from GAL, permissions stripped 6/4/2026 |
| DCE Careers | `careers@deltacrown.com` | Unknown | Unknown | Disabled | Discovered 6/4/2026 — **intent unknown** |
| DCE No Reply | `noreply@deltacrown.com` | Unknown | Unknown | Disabled | Discovered 6/4/2026 — **intent unknown** |

### User mailboxes (7) — from live inventory 2026-06-04
| User | Email | Status |
|---|---|---|
| Allynn Shepherd | `Allynn.Shepherd@deltacrown.com` | Live |
| Amit Shah | `Amit.Shah@deltacrown.com` | Live |
| Jay Miller | `Jay.Miller@deltacrown.com` | Live |
| Lindy Sturgill | `Lindy.Sturgill@deltacrown.com` | Live |
| Sarah Miller | `Sarah.Miller@deltacrown.com` | Live |
| Toni Careccia | `Toni.Careccia@deltacrown.com` | Live |
| Colorado Springs | `ColoradoSprings@deltacrown.com` | Created 6/1/2026 — **intent unknown** |

### Dynamic Distribution Groups (4 DDGs) — confirmed live 2026-06-04
| Group | Email | Recipient Filter | Status |
|---|---|---|---|
| DCE All Staff | `allstaff@deltacrown.com` | UserMailbox + Company = "Delta Crown Extensions" |  Live |
| DCE Managers | `managers@deltacrown.com` | ↑ + Title starts "Manager*" |  Live |
| DCE Stylists | `stylists@deltacrown.com` | ↑ + Title starts "Stylist*" |  Live |
| DCE Franchise Owners | `franchise_owners@deltacrown.com` | ↑ + Dept = "Franchisee" + Title = "Owner" |  Live — confirmed 6/4/2024 |

### Transport rules / Connectors
- Transport rules: **1** — "No Reply Mailbox Blocker" (DISABLED) — discovered 2026-06-04
- Inbound connectors: **0**
- Outbound connectors: **0**
- Static distribution groups: **0**

### What the fresh inventory (2026-06-04) confirms
- **6 shared mailboxes** (was 3 in old inventory): operations, help, info, bookings (deprecated), careers, noreply
- **7 user mailboxes** (was 6): 6 known users + ColoradoSprings (new, 6/1/2026)
- **4 DDGs** confirmed live: AllStaff, Managers, Stylists, Franchise Owners
- **1 transport rule** discovered: "No Reply Mailbox Blocker" (disabled)
- Old inventory was significantly stale — new mailboxes and rules had been added since April 30

---

## 2. What exists today — DNS / Domain Publish State

### Repo claim
-  `deltacrown.com` SPF, DKIM, DMARC "verified live"
-  Phase 1 marked "COMPLETE" in `DEPLOYMENT-STATUS.md`

### What I could verify *right now*
- **DNS queries timed out** — this sandbox has no external DNS resolver access.
- I attempted `dig MX`, `dig TXT`, `dig _dmarc`, `dig selector1._domainkey` for both `deltacrown.com` and `httbrands.com` — both returned `connection timed out; no servers could be reached`.
- **I cannot independently verify DNS publish state from this environment.**

### Where the DNS setup lives
- **Phase 1 (SPF/DKIM/DMARC) has NO dedicated scripts in this repo.**
- It was done via M365 Admin Center / Pax8 CSP during initial tenant provisioning.
- The shared `DNS-Domain-Management` repo (`01-htt-brands/`) contains `email-auth-audit.sh` which *can* verify this across all brands, but it also needs external DNS access.

---

## 3. Cross-check against other HTT brands

### Brand registry (from `DNS-Domain-Management/config/brands.yaml`)
| Brand | Primary Domain | In Shared Audit? |
|---|---|---|
| HTT Brands | `httbrands.com` |  |
| The Lash Lounge | `thelashlounge.com` |  |
| Bishops | `bishops.co` |  |
| Frenchies | `frenchiesnails.com` |  |
| **Delta Crown** | **`deltacrown.com`** | **Listed in `config/domains.txt` but no evidence it has been audited by the shared script** |

### Shared email-auth standard
The `email-auth-audit.sh` script checks for all brands:
- **SPF**: Must exist, `-all` (hard fail) preferred, ≤9 includes
- **DKIM**: At least one selector resolving (`google`, `selector1`, `selector2`, `mbo`, `k1`, `s1`, `default`)
- **DMARC**: Must exist, `p=reject` preferred

**Lash Lounge reference issue** (`issues/2025-01-lashlounge-mindbody-email-auth.md`):
- Had SPF overload (15–18 lookups, > RFC 7208 limit of 10).
- Fixed by removing unused `google` and `secureserver` includes.
- DKIM was broken by Cloudflare proxy; fixed by disabling proxy on CNAME.

**Takeaway for DCE:** The other brands went through explicit email-auth remediation and have documented standards. DCE's Phase 1 was done but is **not auditable from code** and has **no runbook for re-verification**.

---

## 4. The actual gaps (honest)

| # | Gap | Evidence | Priority |
|---|---|---|---|
| 1 | **Stale inventory** — franchise_owners DDG not reflected in raw evidence | Raw CSV dated Apr 30; DDG added May 12 | **CLOSED** — inventory re-run 2026-06-04 confirms all 4 DDGs |
| 2 | **No re-runnable Phase 1 scripts** — SPF/DKIM/DMARC done via admin center, no code | No `phase1/` scripts found | P2 |
| 3 | **Cannot verify DNS publish from this env** — `dig` times out | Sandbox network restriction | N/A (env) |
| 4 | **Shared mailbox permission review** — trustees captured in local-only `.local/` files | Fresh inventory 2026-06-04 now in repo | **CLOSED** |
| 5 | **Auto-reply copy** — enabled but copy was never owner-reviewed | Fresh inventory confirms copy; owner review still recommended | P3 |
| 6 | **Transport rule discovered** — "No Reply Mailbox Blocker" exists but is DISABLED | New finding from fresh inventory 2026-06-04 | P3 |
| 7 | **New shared mailboxes discovered** — `careers@` and `noreply@` created recently | `careers@` 6/4/2026, `noreply@` 6/3/2026 | P2 — need to know intent |
| 8 | **New user mailbox discovered** — `ColoradoSprings@` created 6/1/2026 | Was this intentional? | P2 — need to know intent |

---

## 5. What "match the other brands" means — concrete next steps

To make DCE email + domain config match the maturity of HTT/TLL/BCC/FN, the following are needed:

1. **Re-run the Exchange inventory** to capture the current state (including `franchise_owners@`).
   - Requires interactive device login to `deltacrown.com`.
   - Script: `phase4-migration/scripts/inventory-delta-crown-exchange.ps1 -UseDeviceAuthentication`

2. **Add DCE to the shared `email-auth-audit.sh` rotation** (or run it once).
   - Requires external DNS access (not available here, but works on a machine with `dig`).
   - Command: `cd ~/dev/01-htt-brands/DNS-Domain-Management && ./scripts/email-auth-audit.sh deltacrown.com`

3. **Document Phase 1 setup** as a runbook (even if it was done via GUI).
   - The other brands have explicit SPF/DKIM/DMARC docs in `DNS-Domain-Management/issues/`.
   - DCE has nothing comparable.

4. **Review shared mailbox permissions + auto-reply copy**.
   - `phase3-week2/EXCHANGE-QUICKSTART.md` has the expected copy; verify it matches what's live.
   - Trustee permissions should be reviewed for correctness.

5. **Consider whether DCE needs transport rules** (e.g., forwarding `info@` to a ticketing system).
   - Other brands may have these. TLL definitely has complex routing (MindBody, HubSpot, etc.).

---

## 6. Fresh-poll blockers

| Check | Can I do it now? | Notes |
|---|---|---|
| Exchange tenant state (mailboxes, DDGs, permissions) |  Needs interactive delegated org auth | `inventory-delta-crown-exchange.ps1` requires browser/device login to deltacrown.com |
| DNS publish state (SPF/DKIM/DMARC/MX) |  `dig` times out in this sandbox | Shared `email-auth-audit.sh` also needs `dig` → external DNS |
| GitHub Pages publish state |  Up to date | `gh-pages` branch == `origin/gh-pages` |
| Raw evidence freshness |  Audited | `.local/reports/tenant-inventory/exchange/` — all Apr 30 except May 16 `qa-review-after-fixes` |
| Bead tracker state |  Current | 10 ready issues, `gh-pages` branch in sync |

---

## 7. Recommendations

| Priority | Action | Owner |
|---|---|---|
| P1 | Re-run `inventory-delta-crown-exchange.ps1` with device auth to refresh raw evidence | Tyler (needs browser login) or Richard (with Tyler present) |
| P2 | Run `email-auth-audit.sh deltacrown.com` from a machine with external DNS to verify SPF/DKIM/DMARC parity | Tyler / any machine with `dig` |
| P2 | Create a Phase 1 DNS runbook (document what was done manually for SPF/DKIM/DMARC) | Richard (can draft) |
| P3 | Review auto-reply copy and shared mailbox trustees against live tenant | Tyler |
| P3 | Decide on transport rules / connectors (none vs. some) | Tyler |

---

## 8. What was done this session (2026-06-02)

| Action | Files | Status |
|---|---|---|
| **Replaced `bookings@` with `help@`** across all scripts, docs, tests, templates, and public pages | 20+ files | Done |
| **Updated PowerShell scripts** (`5.1-Exchange-Setup.ps1`, `3.5-Shared-Mailboxes.ps1`, `deploy-phase3-complete.ps1`, `3.6-Template-Export.ps1`, `3.7-Phase3-Verification.ps1`, `inventory-delta-crown-exchange.ps1`) | 6 scripts | Done, syntax-checked |
| **Created migration script** `migrate-bookings-to-help.ps1` — idempotent, handles create `help@` + deprecate `bookings@` (hide, strip permissions, disable auto-reply, optional soft-delete) | 1 script | Done, syntax-checked |
| **Updated public mockup** — `index.html` and `crown-connection.html` now link to `https://help.deltacrown.com` | 2 HTML files | Done |
| **Updated docs** — `EXCHANGE-QUICKSTART.md`, `DEPLOYMENT-STATUS.md`, `DEPLOYMENT-RUNBOOK.md`, `README.md`, `exchange-inventory-summary.md`, ADRs, onboarding docs, specs | 12+ docs | Done |
| **Updated tests** — `test_adr_002_phase3_sites_teams.py` | 1 test | Done, `py_compile` passes |
| **Updated templates** — `dce-group-resource-mapping-template.csv`, `dce-user-access-matrix-template.csv` | 2 CSVs | Done |
| **Created Freshdesk provisioning plan** — full 10-section plan for adding DCE as 5th brand with SSO, custom domain, FBC visibility, Crown Connection integration | `docs/DELTA-FRESHDESK-PROVISIONING-PLAN.md` | Done |

### What still needs live auth
- Run `migrate-bookings-to-help.ps1` in the deltacrown.com tenant (device login required)
- Re-run `inventory-delta-crown-exchange.ps1` to refresh raw evidence
- Execute Freshdesk provisioning steps (Freshworks admin portal + Azure portal)
- Configure `help.deltacrown.com` DNS CNAME

---

*Level-set + prep complete. All scripts and docs are staged. Ready for live execution on your word, Tyler.* 
