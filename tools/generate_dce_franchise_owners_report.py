#!/usr/bin/env python3
"""Generate the DCE Franchise Owners of Record report.

This is the source-of-truth for "active DCE franchisee email accounts →
owner of record → center → operating location" that finance can pull monthly
(see DeltaSetup-de3).

Data source: tools/dce_owners_catalog.py (edit that file to update owner/center data)

Outputs:
  generated/dce-franchise-owners-report.csv
  generated/dce-franchise-owners-report.md

Run:
    python3 tools/generate_dce_franchise_owners_report.py

Hard guardrail: this script never touches the tenant. All data is static.
Refresh by updating dce_owners_catalog.py and re-running.
"""

from __future__ import annotations

import csv
import datetime
import sys
import textwrap
from pathlib import Path

# Allow `import dce_owners_catalog` when running as python3 tools/generate_...py
sys.path.insert(0, str(Path(__file__).parent))

from dce_owners_catalog import (  # noqa: E402
    CENTERS,
    MANUAL_REVIEW_RESOLUTIONS,
    OPEN_QUESTIONS,
    Center,
)

# ---------------------------------------------------------------------------
# Output paths
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).parent.parent
OUT_CSV = REPO_ROOT / "generated" / "dce-franchise-owners-report.csv"
OUT_MD = REPO_ROOT / "generated" / "dce-franchise-owners-report.md"

# ---------------------------------------------------------------------------
# CSV generation
# ---------------------------------------------------------------------------

CSV_HEADERS = (
    "center_id",
    "center_name",
    "entra_office_location",
    "location_confidence",
    "person_type",          # "owner" | "operator"
    "person_name",
    "upn",
    "identity_type",
    "dce_licensed_mailbox",
    "in_franchise_owners_ddg",
    "billing_status",
    "notes",
)


def build_csv_rows() -> list[dict]:
    rows: list[dict] = []
    for center in CENTERS:
        for owner in center.owners:
            rows.append({
                "center_id": center.center_id,
                "center_name": center.center_name,
                "entra_office_location": center.entra_office_location,
                "location_confidence": center.location_confidence,
                "person_type": "owner",
                "person_name": owner.name,
                "upn": owner.upn,
                "identity_type": owner.identity_type,
                "dce_licensed_mailbox": owner.dce_mailbox or "NONE — BILLING GAP",
                "in_franchise_owners_ddg": "YES" if owner.in_franchise_owners_ddg else "NO",
                "billing_status": owner.billing_status,
                "notes": owner.notes,
            })
        for operator in center.operators:
            rows.append({
                "center_id": center.center_id,
                "center_name": center.center_name,
                "entra_office_location": center.entra_office_location,
                "location_confidence": center.location_confidence,
                "person_type": "operator",
                "person_name": operator.name,
                "upn": operator.upn,
                "identity_type": "DCE-tenant",
                "dce_licensed_mailbox": operator.dce_mailbox,
                "in_franchise_owners_ddg": "YES" if operator.in_franchise_owners_ddg else "NO",
                "billing_status": "N/A-OPERATOR",
                "notes": operator.notes,
            })
    return rows


def write_csv(rows: list[dict]) -> None:
    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=CSV_HEADERS)
        writer.writeheader()
        writer.writerows(rows)


# ---------------------------------------------------------------------------
# Markdown generation
# ---------------------------------------------------------------------------

def _ddg_badge(flag: bool) -> str:
    return "Yes" if flag else "No"


def _billing_badge(status: str) -> str:
    return {
        "BILLABLE": "BILLABLE",
        "BILLING-GAP": "**BILLING GAP**",
        "N/A-OPERATOR": "N/A (operator)",
    }.get(status, status)


def write_markdown(rows: list[dict]) -> None:  # noqa: ARG001
    as_of = datetime.date.today().isoformat()
    total_owners = sum(len(c.owners) for c in CENTERS)
    billing_gaps = sum(1 for c in CENTERS for o in c.owners if o.billing_status != "BILLABLE")
    location_disputes = sum(1 for c in CENTERS if c.location_confidence == "NEEDS-VERIFICATION")

    lines: list[str] = [
        "# DCE Franchise Owners of Record",
        "",
        f"**Generated:** {as_of}  ",
        "**Script:** `tools/generate_dce_franchise_owners_report.py`  ",
        "**Data:** `tools/dce_owners_catalog.py`  ",
        "**CSV:** `generated/dce-franchise-owners-report.csv`  ",
        "**Audience:** Finance (Dustin Boyd monthly billing), IT (Tyler), Operations (Jamie Baer)",
        "",
        "> This is the authoritative source-of-truth for 'active DCE franchisee email accounts",
        "> owner of record -> center -> operating location'. Edit `dce_owners_catalog.py` and",
        "> re-run the generator script to refresh.",
        "> Hard guardrail: no live Entra writes without Tyler arming an approval file.",
        "",
        "---",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "|--------|-------|",
        f"| Franchise centers documented | {len(CENTERS)} |",
        f"| Owners of record documented | {total_owners} |",
        f"| Billing gaps (no DCE mailbox) | {billing_gaps} |",
        f"| Location disputes (Entra vs operating reality) | {location_disputes} |",
        f"| Open questions requiring Tyler input | {len(OPEN_QUESTIONS)} |",
        "",
        "---",
        "",
        "## Centers -> Owners -> Billing",
        "",
    ]

    for center in CENTERS:
        loc_note = ""
        if center.location_confidence == "NEEDS-VERIFICATION":
            loc_note = f"  **LOCATION DISPUTED** -- {center.location_open_question}"

        lines += [
            f"### {center.center_id} -- {center.center_name}",
            "",
            f"**Entra officeLocation:** `{center.entra_office_location}`  ",
            f"**Location confidence:** {center.location_confidence}{loc_note}",
            "",
            "#### Owners of Record",
            "",
            "| Name | UPN / Email | Identity type | DCE mailbox | In franchise_owners@ | Billing |",
            "|------|-------------|---------------|-------------|----------------------|---------|",
        ]
        for owner in center.owners:
            mailbox = owner.dce_mailbox or "**NONE**"
            lines.append(
                f"| {owner.name} | `{owner.upn}` | {owner.identity_type} "
                f"| `{mailbox}` | {_ddg_badge(owner.in_franchise_owners_ddg)} "
                f"| {_billing_badge(owner.billing_status)} |"
            )
        lines.append("")
        for owner in center.owners:
            if owner.notes:
                lines.append(f"> **{owner.name}:** {owner.notes}")
        lines.append("")

        if center.operators:
            lines += [
                "#### Operators (NOT owners -- for reference only)",
                "",
                "| Name | UPN | Role | In franchise_owners@ |",
                "|------|-----|------|----------------------|",
            ]
            for op in center.operators:
                lines.append(
                    f"| {op.name} | `{op.upn}` | {op.role} "
                    f"| {_ddg_badge(op.in_franchise_owners_ddg)} |"
                )
            lines.append("")
            for op in center.operators:
                if op.notes:
                    lines.append(f"> **{op.name} (operator):** {op.notes}")
            lines.append("")

    lines += [
        "---",
        "",
        "## Proposed Resolutions -- Manual-Review Rows",
        "",
        "Evidence already exists in audit data; no Tyler input needed beyond approval.",
        "No live writes until Tyler approves.",
        "",
    ]
    for res in MANUAL_REVIEW_RESOLUTIONS:
        lines += [
            f"### {res['name']}",
            "",
            f"- **DCE guest UPN:** `{res['upn_dce']}`",
            f"- **Evidence source:** {res['source']}",
            f"- **Proposed department:** `{res['proposed_department']}`",
            f"- **Proposed job title:** `{res['proposed_job_title']}`",
            f"- **Proposed employeeType:** `{res['proposed_employee_type']}`",
            f"- **Confidence:** {res['confidence']}",
            f"- **Evidence:** {res['evidence']}",
            f"- **Action needed:** {res['action_needed']}",
            "",
        ]

    lines += [
        "---",
        "",
        "## Open Questions -- Tyler Input Required",
        "",
    ]
    for oq in OPEN_QUESTIONS:
        lines += [
            f"### {oq['id']} -- {oq['subject']}",
            "",
            f"**Bead:** `{oq['bead']}`  ",
            f"**Needs:** {oq['needs']}",
            "",
            textwrap.fill(oq["detail"], width=100),
            "",
        ]

    lines += [
        "---",
        "",
        "## Refresh Cadence",
        "",
        "| Trigger | Action |",
        "|---------|--------|",
        "| New franchisee onboarded | Add entry to `CENTERS` in `dce_owners_catalog.py`; re-run. |",
        "| Owner change (sale/transfer) | Update owner entry; re-run. Update canonical CSV. |",
        "| Location confirmed (Jamie) | Update catalog + set confidence HIGH; re-run. Update Entra. |",
        "| Jenna Bowden gets DCE mailbox | Update catalog; re-run. |",
        "| Monthly billing pull (Dustin) | `python3 tools/generate_dce_franchise_owners_report.py` |",
        "",
        "---",
        "",
        "## Identity Framework Reference",
        "",
        "| Group / List | Membership basis | Includes Jenna Bowden? |",
        "|---|---|---|",
        "| `AllStaff` dynamic group | `companyName = 'Delta Crown Extensions'` (DCE-tenant only) | No |",
        "| `Managers` dynamic group | AllStaff + title contains Owner/Manager/Director/VP | No |",
        "| `franchise_owners@deltacrown.com` DDG | DCE company + Franchisee dept + Owner title | No (no DCE mailbox) |",
        "| This owners-of-record report | Confirmed ownership from audit + Jamie attestation | Yes |",
        "",
        "> **Design note (Tyler May 19 decision):** Dynamic groups stay DCE-only.",
        "> HTT-corp owners like Jenna do not appear in those groups by design.",
        "> The owner-of-record source of truth lives in THIS report, not dynamic-group membership.",
        "",
        "---",
        "",
        "*Generated by Richard (`code-puppy-30de1e`) via "
        "`tools/generate_dce_franchise_owners_report.py`*",
    ]

    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

def validate() -> None:
    assert OUT_CSV.exists(), f"CSV not written: {OUT_CSV}"
    assert OUT_MD.exists(), f"Markdown not written: {OUT_MD}"

    with OUT_CSV.open(encoding="utf-8") as fh:
        csv_rows = list(csv.DictReader(fh))

    center_ids_in_csv = {r["center_id"] for r in csv_rows}
    for center in CENTERS:
        assert center.center_id in center_ids_in_csv, f"Center {center.center_id} missing from CSV"

    gap_rows = [r for r in csv_rows if r["billing_status"] == "BILLING-GAP"]
    assert any(r["person_name"] == "Jenna Bowden" for r in gap_rows), (
        "Jenna Bowden should appear as BILLING-GAP"
    )

    lindy_rows = [r for r in csv_rows if r["person_name"] == "Lindy Sturgill"]
    assert lindy_rows, "Lindy Sturgill missing from CSV"
    assert all(r["person_type"] == "operator" for r in lindy_rows), (
        "Lindy Sturgill should be 'operator', not 'owner'"
    )

    ddg_yes_rows = [r for r in csv_rows if r["in_franchise_owners_ddg"] == "YES"]
    for row in ddg_yes_rows:
        assert "NONE" not in row["dce_licensed_mailbox"], (
            f"{row['person_name']} in DDG but no DCE mailbox -- inconsistency"
        )

    print(
        f"   Validation passed -- {len(csv_rows)} rows, "
        f"{len(center_ids_in_csv)} centers, {len(gap_rows)} billing gap(s)"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    rows = build_csv_rows()
    write_csv(rows)
    write_markdown(rows)
    validate()

    print(f"CSV  -> {OUT_CSV}  ({OUT_CSV.stat().st_size:,} bytes)")
    print(f"MD   -> {OUT_MD}  ({OUT_MD.stat().st_size:,} bytes)")
    print()
    print("Billing gaps:")
    for center in CENTERS:
        for owner in center.owners:
            if owner.billing_status != "BILLABLE":
                print(f"  {center.center_name}: {owner.name} -- {owner.billing_status}")
    print()
    print("Location disputes:")
    for center in CENTERS:
        if center.location_confidence == "NEEDS-VERIFICATION":
            print(f"  {center.center_name}: Entra='{center.entra_office_location}'")
    print()
    print("Open questions requiring Tyler input:", len(OPEN_QUESTIONS))


if __name__ == "__main__":
    main()
