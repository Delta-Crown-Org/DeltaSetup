# DCE Franchise Owners of Record

**Generated:** 2026-06-10  
**Script:** `tools/generate_dce_franchise_owners_report.py`  
**Data:** `tools/dce_owners_catalog.py`  
**CSV:** `generated/dce-franchise-owners-report.csv`  
**Audience:** Finance (Dustin Boyd monthly billing), IT (Tyler), Operations (Jamie Baer)

> This is the authoritative source-of-truth for 'active DCE franchisee email accounts
> owner of record -> center -> operating location'. Edit `dce_owners_catalog.py` and
> re-run the generator script to refresh.
> Hard guardrail: no live Entra writes without Tyler arming an approval file.

---

## Summary

| Metric | Value |
|--------|-------|
| Franchise centers documented | 4 |
| Owners of record documented | 6 |
| Billing gaps (no DCE mailbox) | 1 |
| Location disputes (Entra vs operating reality) | 2 |
| Open questions requiring Tyler input | 7 |

---

## Centers -> Owners -> Billing

### DCE-PGH-01 -- Pittsburgh

**Entra officeLocation:** `Pittsburgh, Pennsylvania`  
**Location confidence:** HIGH

#### Owners of Record

| Name | UPN / Email | Identity type | DCE mailbox | In franchise_owners@ | Billing |
|------|-------------|---------------|-------------|----------------------|---------|
| Toni Careccia | `Toni.Careccia@deltacrown.com` | DCE-tenant | `Toni.Careccia@deltacrown.com` | Yes | BILLABLE |
| Amit Shah | `Amit.Shah@deltacrown.com` | DCE-tenant | `Amit.Shah@deltacrown.com` | Yes | BILLABLE |

> **Toni Careccia:** franchise_owners@ DDG member; metadata clean.
> **Amit Shah:** franchise_owners@ DDG member; metadata clean.

### DCE-LEX-01 -- Lexington / Columbus

**Entra officeLocation:** `Lexington, Ohio`  
**Location confidence:** NEEDS-VERIFICATION  **LOCATION DISPUTED** -- Jamie Baer flagged operating reality may be Columbus, OH not Lexington, OH. Entra currently shows 'Lexington, Ohio'. Confirm with Jamie or franchise agreement before updating. See DeltaSetup-de3.

#### Owners of Record

| Name | UPN / Email | Identity type | DCE mailbox | In franchise_owners@ | Billing |
|------|-------------|---------------|-------------|----------------------|---------|
| Sarah Miller | `Sarah.Miller@deltacrown.com` | DCE-tenant | `Sarah.Miller@deltacrown.com` | Yes | BILLABLE |
| Jay Miller | `Jay.Miller@deltacrown.com` | DCE-tenant | `Jay.Miller@deltacrown.com` | Yes | BILLABLE |

> **Sarah Miller:** franchise_owners@ DDG member; metadata clean.
> **Jay Miller:** franchise_owners@ DDG member; metadata clean.

### DCE-LIV-01 -- Livonia / Birmingham

**Entra officeLocation:** `Livonia, Michigan`  
**Location confidence:** NEEDS-VERIFICATION  **LOCATION DISPUTED** -- Jamie Baer flagged operating reality may be Birmingham, MI not Livonia, MI. Entra currently shows 'Livonia, Michigan'. Confirm with Jamie or franchise agreement before updating. See DeltaSetup-de3.

#### Owners of Record

| Name | UPN / Email | Identity type | DCE mailbox | In franchise_owners@ | Billing |
|------|-------------|---------------|-------------|----------------------|---------|
| Allynn Shepherd | `Allynn.Shepherd@deltacrown.com` | DCE-tenant | `Allynn.Shepherd@deltacrown.com` | Yes | BILLABLE |

> **Allynn Shepherd:** franchise_owners@ DDG member; metadata clean.

### DCE-COS-01 -- Colorado Springs

**Entra officeLocation:** `Colorado Springs, Colorado`  
**Location confidence:** HIGH

#### Owners of Record

| Name | UPN / Email | Identity type | DCE mailbox | In franchise_owners@ | Billing |
|------|-------------|---------------|-------------|----------------------|---------|
| Jenna Bowden | `Jenna.Bowden@httbrands.com` | HTT-corp-guest | `**NONE**` | No | **BILLING GAP** |

> **Jenna Bowden:** COS owner confirmed by Jamie Baer (June 9 thread). HTT corp cross-tenant guest only — no @deltacrown.com mailbox. Not in franchise_owners@ DDG or any dynamic security group by design. Proposed fix (DeltaSetup-dez): extensionAttribute1 on HTT guest record. Requires Tyler approval before any Entra write.

#### Operators (NOT owners -- for reference only)

| Name | UPN | Role | In franchise_owners@ |
|------|-----|------|----------------------|
| Lindy Sturgill | `Lindy.Sturgill@deltacrown.com` | Salon Manager (on-site operator, NOT owner of record) | No |

> **Lindy Sturgill (operator):** Intentionally excluded from franchise_owners@ DDG. Title 'Salon Manager', dept 'Salon Operations'. Lindy is the operator; Jenna Bowden is the legal owner.

---

## Proposed Resolutions -- Manual-Review Rows

Evidence already exists in audit data; no Tyler input needed beyond approval.
No live writes until Tyler approves.

### Amber Caley

- **DCE guest UPN:** `Amber.Caley_httbrands.com#EXT#@deltacrown.onmicrosoft.com`
- **Evidence source:** BCC Zenoti staff audit (audit-zenoti-bishops-staff.csv, 2026-05-13)
- **Proposed department:** `Operations`
- **Proposed job title:** `Corporate Admin`
- **Proposed employeeType:** `Employee`
- **Confidence:** MEDIUM
- **Evidence:** Zenoti BCC: job_name='Corporate Admin', center_name='Austin Buro' (BCC corporate, not a franchisee center). HTT corp staff supporting BCC.
- **Action needed:** Apply via Apply-DceMetadataPopulation.ps1 pattern after Tyler approval. No live write without explicit sign-off.

---

## Open Questions -- Tyler Input Required

### OQ-001 -- Megan Myrand — confirm DCE account type and admin-role scope

**Bead:** `DeltaSetup-k1n`  
**Needs:** Tyler to confirm DCE account admin role is scoped correctly for MSP.

Megan Myrand is the Managed Service Provider (MSP) helping manage user licensing and occasional
Microsoft 365 issues for the DCE tenant (confirmed by Tyler). Two records exist: (1)
Megan.Myrand@deltacrown.com (DCE-native cloud account, object 651c4252) — blank metadata; NOT a
franchisee. This is her MSP working identity in DCE. No #EXT# suffix = separately provisioned cloud-
native account, NOT inherited via SyncFabric from HTT. (2) megan.myrand@httbrands.com (HTT corp
guest in DCE, object 971e0f08) — her HTT corporate identity showing up as a cross-tenant guest.
Action needed: confirm DCE account admin role is correct for MSP scope, and exclude the HTT guest
row from any bulk metadata population (she is not a DCE employee or franchisee).

### OQ-002 -- Location ground truth — Lexington OH vs Columbus OH

**Bead:** `DeltaSetup-de3`  
**Needs:** Jamie Baer or Tyler to confirm operating location.

Sarah Miller and Jay Miller (DCE-LEX-01) have officeLocation='Lexington, Ohio' in Entra ID. Jamie
Baer flagged operating reality may be Columbus, OH. Source of truth: franchise agreement or Zenoti
CRM center record. If Columbus is correct: update officeLocation via Apply-DceMetadataPopulation.ps1
(Tyler must arm approval file first).

### OQ-003 -- Location ground truth — Livonia MI vs Birmingham MI

**Bead:** `DeltaSetup-de3`  
**Needs:** Jamie Baer or Tyler to confirm operating location.

Allynn Shepherd (DCE-LIV-01) has officeLocation='Livonia, Michigan' in Entra ID. Jamie Baer flagged
operating reality may be Birmingham, MI. Source of truth: franchise agreement or Zenoti CRM center
record. If Birmingham is correct: update Allynn's officeLocation.

### OQ-004 -- COS Zenoti Business Details contact email

**Bead:** `DeltaSetup-g0q`  
**Needs:** Tyler (Jenna or Jamie input) to select A/B/C.

Three options for Colorado Springs Zenoti contact email: (A) Lindy.Sturgill@deltacrown.com
(operator, licensed). (B) Jenna.Bowden@httbrands.com (owner of record, HTT address). (C)
ColoradoSprings@deltacrown.com (center alias — ALREADY EXISTS as a licensed user mailbox per
2026-06-04 Exchange inventory; should be a shared mailbox). Note: option C may be accruing
unnecessary license cost — see OQ-006. Default to option C if Jenna or Jamie approve. Ask Tyler.

### OQ-005 -- Jenna Bowden — provision jenna.bowden@deltacrown.com SharedMailbox + Send As

**Bead:** `DeltaSetup-dez`  
**Needs:** Tyler to arm approval file; then Richard runs the provision scaffold.

Jenna needs to be able to send FROM jenna.bowden@deltacrown.com even though her primary mailbox
lives at HTT (jenna.bowden@httbrands.com). Recommended approach: (1) Create
jenna.bowden@deltacrown.com as a SharedMailbox in DCE Exchange (no license). (2) Grant Jenna's DCE
guest object Full Access + Send As on that mailbox. (3) Jenna opens the shared mailbox in Outlook
and selects it as her FROM address. Dry-run scaffold in tools/provision-jenna-dce-mailbox.ps1.
BLOCKED: requires Tyler to arm an approval file before any Exchange write. Note: extensionAttribute1
pattern is still useful for Entra visibility but the SharedMailbox provision is the primary ask.

### OQ-006 -- ColoradoSprings@deltacrown.com — licensed user mailbox (billing concern)

**Bead:** `DeltaSetup-de3`  
**Needs:** Tyler to confirm: keep as user mailbox, convert to shared, or delete?

The 2026-06-04 Exchange inventory lists 'ColoradoSprings' as one of 7 user mailboxes — consuming a
Business Premium seat. If intended as a center alias or shared mailbox, convert to SharedMailbox
(free). Tyler must confirm intent before any conversion.

### OQ-007 -- 15 manual-review HTT corp rows — 13 still unresolvable

**Bead:** `DeltaSetup-de3`  
**Needs:** Tyler (or HR) to provide dept/title for the 13 remaining accounts.

From the May 19 audit, 15 HTT corp guest accounts had no dept/title anywhere. ONE resolved this
session: Amber Caley (BCC Zenoti: Corporate Admin, Operations). Remaining 13 need HR input: Tabitha
Addison, David Hendley, Jeff Fincher, Colten Hunt, Katie Loerts, Kurtis Davis, Donnie Little, Jerrod
Braun, Genesis Umanzor, Lindsey Nabors, Scott Humiston, james.cates, megan.myrand@httbrands.com (see
OQ-001).

---

## Refresh Cadence

| Trigger | Action |
|---------|--------|
| New franchisee onboarded | Add entry to `CENTERS` in `dce_owners_catalog.py`; re-run. |
| Owner change (sale/transfer) | Update owner entry; re-run. Update canonical CSV. |
| Location confirmed (Jamie) | Update catalog + set confidence HIGH; re-run. Update Entra. |
| Jenna Bowden gets DCE mailbox | Update catalog; re-run. |
| Monthly billing pull (Dustin) | `python3 tools/generate_dce_franchise_owners_report.py` |

---

## Identity Framework Reference

| Group / List | Membership basis | Includes Jenna Bowden? |
|---|---|---|
| `AllStaff` dynamic group | `companyName = 'Delta Crown Extensions'` (DCE-tenant only) | No |
| `Managers` dynamic group | AllStaff + title contains Owner/Manager/Director/VP | No |
| `franchise_owners@deltacrown.com` DDG | DCE company + Franchisee dept + Owner title | No (no DCE mailbox) |
| This owners-of-record report | Confirmed ownership from audit + Jamie attestation | Yes |

> **Design note (Tyler May 19 decision):** Dynamic groups stay DCE-only.
> HTT-corp owners like Jenna do not appear in those groups by design.
> The owner-of-record source of truth lives in THIS report, not dynamic-group membership.

---

*Generated by Richard (`code-puppy-30de1e`) via `tools/generate_dce_franchise_owners_report.py`*
