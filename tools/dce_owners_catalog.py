"""DCE Franchise Owners of Record — static data catalog.

This module is the single source of truth for center → owner → location mappings.
Update these constants when ownership or location data changes, then re-run
`generate_dce_franchise_owners_report.py` to regenerate the CSV and markdown.

Sources:
  - May 2026 audit CSVs in ../visual-dashboard/
  - Jamie Baer confirmation, June 9 Dustin Boyd email thread
  - Zenoti BCC corroboration for Amber Caley
"""

from __future__ import annotations

import dataclasses


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------


@dataclasses.dataclass(frozen=True)
class Owner:
    """An owner of record for a DCE center."""

    name: str
    upn: str                    # authoritative email / UPN
    identity_type: str          # "DCE-tenant" | "HTT-corp-guest"
    dce_mailbox: str | None     # @deltacrown.com mailbox, if any
    entra_object_id: str        # DCE-tenant Entra object ID
    in_franchise_owners_ddg: bool
    billing_status: str         # "BILLABLE" | "BILLING-GAP"
    notes: str = ""


@dataclasses.dataclass(frozen=True)
class Operator:
    """A center operator (on-site manager, NOT the legal owner of record)."""

    name: str
    upn: str
    dce_mailbox: str
    role: str
    in_franchise_owners_ddg: bool
    notes: str = ""


@dataclasses.dataclass(frozen=True)
class Center:
    """A Delta Crown Extensions franchise center."""

    center_id: str
    center_name: str
    entra_office_location: str      # value currently in Entra
    location_confidence: str        # "HIGH" | "NEEDS-VERIFICATION"
    location_open_question: str     # empty string if HIGH
    owners: tuple[Owner, ...]
    operators: tuple[Operator, ...]


# ---------------------------------------------------------------------------
# Center catalog
# ---------------------------------------------------------------------------

CENTERS: tuple[Center, ...] = (
    Center(
        center_id="DCE-PGH-01",
        center_name="Pittsburgh",
        entra_office_location="Pittsburgh, Pennsylvania",
        location_confidence="HIGH",
        location_open_question="",
        owners=(
            Owner(
                name="Toni Careccia",
                upn="Toni.Careccia@deltacrown.com",
                identity_type="DCE-tenant",
                dce_mailbox="Toni.Careccia@deltacrown.com",
                entra_object_id="32106117-b83c-4cfa-936c-e620c874188b",
                in_franchise_owners_ddg=True,
                billing_status="BILLABLE",
                notes="franchise_owners@ DDG member; metadata clean.",
            ),
            Owner(
                name="Amit Shah",
                upn="Amit.Shah@deltacrown.com",
                identity_type="DCE-tenant",
                dce_mailbox="Amit.Shah@deltacrown.com",
                entra_object_id="fcf4a106-4b56-4208-bf63-535705a55c6a",
                in_franchise_owners_ddg=True,
                billing_status="BILLABLE",
                notes="franchise_owners@ DDG member; metadata clean.",
            ),
        ),
        operators=(),
    ),
    Center(
        center_id="DCE-LEX-01",
        center_name="Lexington / Columbus",
        entra_office_location="Lexington, Ohio",
        location_confidence="NEEDS-VERIFICATION",
        location_open_question=(
            "Jamie Baer flagged operating reality may be Columbus, OH not Lexington, OH. "
            "Entra currently shows 'Lexington, Ohio'. Confirm with Jamie or franchise "
            "agreement before updating. See DeltaSetup-de3."
        ),
        owners=(
            Owner(
                name="Sarah Miller",
                upn="Sarah.Miller@deltacrown.com",
                identity_type="DCE-tenant",
                dce_mailbox="Sarah.Miller@deltacrown.com",
                entra_object_id="32784479-e42a-485e-8f0c-5449496a8b09",
                in_franchise_owners_ddg=True,
                billing_status="BILLABLE",
                notes="franchise_owners@ DDG member; metadata clean.",
            ),
            Owner(
                name="Jay Miller",
                upn="Jay.Miller@deltacrown.com",
                identity_type="DCE-tenant",
                dce_mailbox="Jay.Miller@deltacrown.com",
                entra_object_id="60da24d4-0268-46a0-aaec-ef9573b03777",
                in_franchise_owners_ddg=True,
                billing_status="BILLABLE",
                notes="franchise_owners@ DDG member; metadata clean.",
            ),
        ),
        operators=(),
    ),
    Center(
        center_id="DCE-LIV-01",
        center_name="Livonia / Birmingham",
        entra_office_location="Livonia, Michigan",
        location_confidence="NEEDS-VERIFICATION",
        location_open_question=(
            "Jamie Baer flagged operating reality may be Birmingham, MI not Livonia, MI. "
            "Entra currently shows 'Livonia, Michigan'. Confirm with Jamie or franchise "
            "agreement before updating. See DeltaSetup-de3."
        ),
        owners=(
            Owner(
                name="Allynn Shepherd",
                upn="Allynn.Shepherd@deltacrown.com",
                identity_type="DCE-tenant",
                dce_mailbox="Allynn.Shepherd@deltacrown.com",
                entra_object_id="567c57a4-6e39-4cac-8716-3520227eb6c1",
                in_franchise_owners_ddg=True,
                billing_status="BILLABLE",
                notes="franchise_owners@ DDG member; metadata clean.",
            ),
        ),
        operators=(),
    ),
    Center(
        center_id="DCE-COS-01",
        center_name="Colorado Springs",
        entra_office_location="Colorado Springs, Colorado",
        location_confidence="HIGH",
        location_open_question="",
        owners=(
            Owner(
                name="Jenna Bowden",
                upn="Jenna.Bowden@httbrands.com",
                identity_type="HTT-corp-guest",
                dce_mailbox=None,
                entra_object_id="26e9afa6-3e1b-4830-b0c6-68eceba42781",
                in_franchise_owners_ddg=False,
                billing_status="BILLING-GAP",
                notes=(
                    "COS owner confirmed by Jamie Baer (June 9 thread). "
                    "HTT corp cross-tenant guest only — no @deltacrown.com mailbox. "
                    "Not in franchise_owners@ DDG or any dynamic security group by design. "
                    "Proposed fix (DeltaSetup-dez): extensionAttribute1 on HTT guest record. "
                    "Requires Tyler approval before any Entra write."
                ),
            ),
        ),
        operators=(
            Operator(
                name="Lindy Sturgill",
                upn="Lindy.Sturgill@deltacrown.com",
                dce_mailbox="Lindy.Sturgill@deltacrown.com",
                role="Salon Manager (on-site operator, NOT owner of record)",
                in_franchise_owners_ddg=False,
                notes=(
                    "Intentionally excluded from franchise_owners@ DDG. "
                    "Title 'Salon Manager', dept 'Salon Operations'. "
                    "Lindy is the operator; Jenna Bowden is the legal owner."
                ),
            ),
        ),
    ),
)


# ---------------------------------------------------------------------------
# Open questions — Tyler input required
# ---------------------------------------------------------------------------

OPEN_QUESTIONS: tuple[dict, ...] = (
    {
        "id": "OQ-001",
        "bead": "DeltaSetup-k1n",
        "subject": "Megan Myrand — dual identity (DCE + HTT)",
        "detail": (
            "Two Megan Myrand records exist: "
            "(1) Megan.Myrand@deltacrown.com (DCE-native, object 651c4252) — "
            "blank companyName/dept/title/location; action=UPDATE MEDIUM in May 19 CSV. "
            "(2) megan.myrand@httbrands.com (HTT corp guest, object 971e0f08) — "
            "also fully blank; needs_manual=YES in canonical CSV. "
            "UNKNOWN: same human or two distinct people? "
            "If SAME: populate DCE record with center/location, add her to the center catalog. "
            "If DIFFERENT: document intentional split; populate both records separately. "
            "Tyler must confirm before any write. Do not merge without explicit sign-off."
        ),
        "needs": "Tyler to confirm same vs distinct identity.",
    },
    {
        "id": "OQ-002",
        "bead": "DeltaSetup-de3",
        "subject": "Location ground truth — Lexington OH vs Columbus OH",
        "detail": (
            "Sarah Miller and Jay Miller (DCE-LEX-01) have officeLocation='Lexington, Ohio' in "
            "Entra ID. Jamie Baer flagged operating reality may be Columbus, OH. "
            "Source of truth: franchise agreement or Zenoti CRM center record. "
            "If Columbus is correct: update officeLocation via Apply-DceMetadataPopulation.ps1 "
            "(Tyler must arm approval file first)."
        ),
        "needs": "Jamie Baer or Tyler to confirm operating location.",
    },
    {
        "id": "OQ-003",
        "bead": "DeltaSetup-de3",
        "subject": "Location ground truth — Livonia MI vs Birmingham MI",
        "detail": (
            "Allynn Shepherd (DCE-LIV-01) has officeLocation='Livonia, Michigan' in Entra ID. "
            "Jamie Baer flagged operating reality may be Birmingham, MI. "
            "Source of truth: franchise agreement or Zenoti CRM center record. "
            "If Birmingham is correct: update Allynn's officeLocation."
        ),
        "needs": "Jamie Baer or Tyler to confirm operating location.",
    },
    {
        "id": "OQ-004",
        "bead": "DeltaSetup-g0q",
        "subject": "COS Zenoti Business Details contact email",
        "detail": (
            "Three options for Colorado Springs Zenoti contact email: "
            "(A) Lindy.Sturgill@deltacrown.com (operator, licensed). "
            "(B) Jenna.Bowden@httbrands.com (owner of record, HTT address). "
            "(C) ColoradoSprings@deltacrown.com (center alias — ALREADY EXISTS as a licensed "
            "user mailbox per 2026-06-04 Exchange inventory; should be a shared mailbox). "
            "Note: option C may be accruing unnecessary license cost — see OQ-006. "
            "Default to option C if Jenna or Jamie approve. Ask Tyler."
        ),
        "needs": "Tyler (Jenna or Jamie input) to select A/B/C.",
    },
    {
        "id": "OQ-005",
        "bead": "DeltaSetup-dez",
        "subject": "Jenna Bowden — extensionAttribute1 write approval",
        "detail": (
            "Proposed: set extensionAttribute1='DCE Owner of Record | Center: Colorado Springs' "
            "on Jenna's DCE guest record (object 26e9afa6). Dry-run scaffold is in "
            "docs/dce-franchise-owner-identity-pattern.md. "
            "BLOCKED: requires Tyler to arm an approval file before any Entra write."
        ),
        "needs": "Tyler to arm approval file; then Richard runs the PS command.",
    },
    {
        "id": "OQ-006",
        "bead": "DeltaSetup-de3",
        "subject": "ColoradoSprings@deltacrown.com — licensed user mailbox (billing concern)",
        "detail": (
            "The 2026-06-04 Exchange inventory lists 'ColoradoSprings' as one of 7 user mailboxes "
            "— consuming a Business Premium seat. If intended as a center alias or shared mailbox, "
            "convert to SharedMailbox (free). Tyler must confirm intent before any conversion."
        ),
        "needs": "Tyler to confirm: keep as user mailbox, convert to shared, or delete?",
    },
    {
        "id": "OQ-007",
        "bead": "DeltaSetup-de3",
        "subject": "15 manual-review HTT corp rows — 13 still unresolvable",
        "detail": (
            "From the May 19 audit, 15 HTT corp guest accounts had no dept/title anywhere. "
            "ONE resolved this session: Amber Caley (BCC Zenoti: Corporate Admin, Operations). "
            "Remaining 13 need HR input: Tabitha Addison, David Hendley, Jeff Fincher, "
            "Colten Hunt, Katie Loerts, Kurtis Davis, Donnie Little, Jerrod Braun, "
            "Genesis Umanzor, Lindsey Nabors, Scott Humiston, james.cates, "
            "megan.myrand@httbrands.com (see OQ-001)."
        ),
        "needs": "Tyler (or HR) to provide dept/title for the 13 remaining accounts.",
    },
)


# ---------------------------------------------------------------------------
# Manual-review resolutions (evidence already in audit data — no Tyler input needed)
# ---------------------------------------------------------------------------

MANUAL_REVIEW_RESOLUTIONS: tuple[dict, ...] = (
    {
        "name": "Amber Caley",
        "upn_dce": "Amber.Caley_httbrands.com#EXT#@deltacrown.onmicrosoft.com",
        "source": "BCC Zenoti staff audit (audit-zenoti-bishops-staff.csv, 2026-05-13)",
        "proposed_department": "Operations",
        "proposed_job_title": "Corporate Admin",
        "proposed_employee_type": "Employee",
        "confidence": "MEDIUM",
        "evidence": (
            "Zenoti BCC: job_name='Corporate Admin', center_name='Austin Buro' "
            "(BCC corporate, not a franchisee center). HTT corp staff supporting BCC."
        ),
        "action_needed": (
            "Apply via Apply-DceMetadataPopulation.ps1 pattern after Tyler approval. "
            "No live write without explicit sign-off."
        ),
    },
)
