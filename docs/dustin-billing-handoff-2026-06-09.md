# Dustin Boyd — DCE License Billing Handoff

**Date:** 2026-06-10
**Prepared by:** Tyler Granlund (IT) + Richard (`code-puppy-30de1e`)
**Context:** Dustin's June 9 email — monthly license-billing spreadsheet sourced from Entra
**Beads:** `DeltaSetup-de3`, `DeltaSetup-dez`, `DeltaSetup-k1n`, `DeltaSetup-g0q`

---

## TL;DR for Dustin

You asked about Delta Crown email licenses per owner. Here is the ground truth.

**The authoritative file is:**
`generated/dce-franchise-owners-report.csv` (in the DeltaSetup repo, `gh-pages` branch)

**To regenerate it:**
```bash
cd /path/to/DeltaSetup
python3 tools/generate_dce_franchise_owners_report.py
# outputs generated/dce-franchise-owners-report.csv
```

---

## What the Data Shows

### Active DCE Franchisee Licensed Mailboxes (as of 2026-06-04 Exchange inventory)

| Center | Owner | Email (licensed mailbox) | In franchise_owners@ | Billing status |
|--------|-------|--------------------------|----------------------|----------------|
| Pittsburgh, PA | Toni Careccia | Toni.Careccia@deltacrown.com | Yes | BILLABLE |
| Pittsburgh, PA | Amit Shah | Amit.Shah@deltacrown.com | Yes | BILLABLE |
| Lexington / Columbus, OH* | Sarah Miller | Sarah.Miller@deltacrown.com | Yes | BILLABLE |
| Lexington / Columbus, OH* | Jay Miller | Jay.Miller@deltacrown.com | Yes | BILLABLE |
| Livonia / Birmingham, MI** | Allynn Shepherd | Allynn.Shepherd@deltacrown.com | Yes | BILLABLE |
| Colorado Springs, CO | Jenna Bowden | jenna.bowden@httbrands.com | **NO DCE MAILBOX** | **BILLING GAP** |
| Colorado Springs, CO | Lindy Sturgill (operator) | Lindy.Sturgill@deltacrown.com | No (operator, not owner) | Billable as employee |

*Location disputed — Entra says Lexington, OH; operating reality may be Columbus, OH.
Pending Jamie Baer confirmation.

**Location disputed — Entra says Livonia, MI; operating reality may be Birmingham, MI.
Pending Jamie Baer confirmation.

---

## The Colorado Springs Billing Gap

**Jenna Bowden is the confirmed COS owner of record (Jamie Baer, June 9).**

However:
- Jenna has NO `@deltacrown.com` mailbox.
- Her identity is `jenna.bowden@httbrands.com` (HTT Brands Corporate guest in DCE tenant).
- She does NOT appear in the `franchise_owners@deltacrown.com` Dynamic Distribution Group.
- She does NOT appear in the AllStaff, Managers, or other dynamic security groups.

**For your billing spreadsheet:**
Jenna Bowden owns the COS franchise. She does not have a billed DCE email account.
If your billing model requires a DCE mailbox per owner, COS is currently under-provisioned.
Track this as a gap — see `DeltaSetup-dez` for the proposed fix.

---

## Jamie Baer's Location Questions

Jamie flagged two possible location mismatches between Entra and operating reality:

| Person | Current Entra location | Jamie's question | Status |
|--------|------------------------|------------------|--------|
| Sarah Miller, Jay Miller | Lexington, Ohio | Operating reality Columbus, OH? | Open — needs Jamie/Tyler confirmation |
| Allynn Shepherd | Livonia, Michigan | Operating reality Birmingham, MI? | Open — needs Jamie/Tyler confirmation |

These do NOT affect billing right now — the M365 accounts and mailboxes exist regardless
of which city name is in Entra. But for your billing spreadsheet, use the operating
location (Columbus / Birmingham) once confirmed, not the Entra value.

---

## Megan Myrand — Dual Identity (Open Question)

There are TWO Megan Myrand records in the system:

1. `Megan.Myrand@deltacrown.com` — DCE-native franchisee. Blank metadata (no center, no location).
2. `megan.myrand@httbrands.com` — HTT Brands Corporate guest. Also blank.

**Unknown:** Same person or two distinct people?

- If same: she likely owns a DCE center that is not yet in the center catalog.
  Tyler needs to confirm which center and populate her record.
- If different: document the split separately.

For your billing spreadsheet: **hold Megan Myrand** until Tyler confirms.
She is listed as action=UPDATE MEDIUM confidence in the May 19 audit.
`DeltaSetup-k1n` tracks this.

---

## The `ColoradoSprings@deltacrown.com` Mailbox

The 2026-06-04 Exchange inventory shows `ColoradoSprings` as a **licensed user mailbox**
(one of only 7 in the tenant). This consumes a Business Premium seat.

If it is intended as a center alias or contact address, it should be converted to a
**SharedMailbox** (free — no license required). Tyler has been flagged to confirm.
`DeltaSetup-de3` OQ-006 tracks this.

For your billing spreadsheet: include it as a billed mailbox until Tyler confirms conversion.

---

## Dynamic Distribution Groups (DDGs) — What They Cover

| DDG | Filter | Current preview count |
|-----|--------|-----------------------|
| `franchise_owners@deltacrown.com` | Company = DCE + Dept = Franchisee + Title = Owner | 5 (Toni, Amit, Sarah, Jay, Allynn) |
| `allstaff@deltacrown.com` | Company = DCE | 6 |
| `managers@deltacrown.com` | DCE + Manager/Director/VP/Owner titles | variable |
| `stylists@deltacrown.com` | DCE + Stylist/Owner titles | variable |

Note: `franchise_owners@` has 5 members, not 6, because Jenna Bowden (COS owner)
has no @deltacrown.com mailbox and Lindy Sturgill is excluded by design.

---

## Do NOT Use the May 19 Audit Directly

The May 19 audit (`DCE-metadata-population-httbrands-canonical-2026-05-19.csv`)
covers HTT Brands Corporate staff metadata — it is NOT the owners-of-record list.
Using it for billing would include 50+ HTT corporate employees who are not franchisees.

**Use `generated/dce-franchise-owners-report.csv` for billing. That is the right file.**

---

## Monthly Refresh Process

1. Tyler (or Richard) runs: `python3 tools/generate_dce_franchise_owners_report.py`
2. The script reads hardcoded confirmed facts from the DeltaSetup repo.
3. Share `generated/dce-franchise-owners-report.csv` with Dustin.
4. If there are ownership changes (new franchisee, sale, etc.), update
   `tools/generate_dce_franchise_owners_report.py` `CENTERS` constant first.

**Cadence:** On-demand when ownership changes, or monthly before Dustin's billing cycle.
No live tenant queries needed — the data is compiled from audited evidence.

---

## What Still Needs Tyler Before Next Billing Cycle

| Item | Bead | Impact on billing |
|------|------|--------------------|
| Jenna Bowden — no DCE mailbox (COS billing gap) | `DeltaSetup-dez` | COS may be under-billed |
| Megan Myrand — confirm identity | `DeltaSetup-k1n` | May be missing a center from billing |
| Lexington vs Columbus (Sarah/Jay Miller) | `DeltaSetup-de3 OQ-002` | Location accuracy only; no billing impact |
| Livonia vs Birmingham (Allynn Shepherd) | `DeltaSetup-de3 OQ-003` | Location accuracy only; no billing impact |
| ColoradoSprings@ mailbox conversion | `DeltaSetup-de3 OQ-006` | One unnecessary licensed seat if converted |
| Amber Caley — HTT corp staff, NOT a franchisee | `DeltaSetup-de3` | Confirmed she does NOT own a DCE center |

---

*This document supplements Dustin's May 19 audit output. It does NOT supersede Tyler's
decisions or any live Entra/Exchange state. For current tenant state, run the
`Apply-DceMetadataPopulation.ps1` dry-run or request a fresh Exchange inventory.*
