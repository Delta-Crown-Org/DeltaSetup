#!/usr/bin/env python3
"""Generate the Delta Crown owner-decision Excel workbook.

Run with:
    uv run --with XlsxWriter --with openpyxl python tools/generate_owner_decision_workbook.py

Why XlsxWriter?
    It writes Excel-native XLSX files. Keep this boring. Excel hates clever.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import xlsxwriter
from openpyxl import load_workbook

OUT = Path("generated/delta-crown-owner-decision-workbook.xlsx")


@dataclass(frozen=True)
class Option:
    key: str
    description: str
    pros: str
    cons: str


@dataclass(frozen=True)
class Decision:
    decision_id: str
    title: str
    current_state: str
    risk: str
    recommendation: str
    owner_needed: str
    evidence: tuple[str, ...]
    options: tuple[Option, ...]
    followups: tuple[str, ...]


DECISIONS: tuple[Decision, ...] = (
    Decision(
        "OD-001",
        "GitHub default branch / stale main",
        "Remote default branch is main; canonical current project work and GitHub Pages source are on gh-pages.",
        "Future operators may land on stale architecture and treat it as current.",
        "Prefer changing GitHub default branch to gh-pages. If that is not possible, make main a hard redirect/archive branch.",
        "Tyler / repo owner",
        (
            "git remote show origin reports HEAD branch: main.",
            "README says gh-pages is canonical and main is abandoned earlier architecture.",
            "Live public site publishes from gh-pages.",
        ),
        (
            Option("A", "Change GitHub default branch to gh-pages.", "Repo landing page matches current work.", "Requires GitHub repo admin action."),
            Option("B", "Keep main but replace README with a clear redirect to gh-pages.", "Fast and low risk.", "Users can still browse stale files."),
            Option("C", "Archive/delete stale main after preservation tag.", "Cleanest long-term.", "Higher governance risk; needs explicit approval."),
        ),
        (
            "If A: update GitHub repository default branch setting.",
            "If B: patch main README to point to gh-pages and warn it is legacy.",
            "If C: tag legacy main, verify no workflows depend on it, then archive/delete.",
        ),
    ),
    Decision(
        "OD-002",
        "Brand Resources vs Brand Assets model",
        "Docs target Brand Resources; tenant/docs still include Marketing Brand Assets and legacy ClientServices artifacts.",
        "Users and MSP operators may confuse reference material, marketing execution assets, legacy ClientServices, and client records.",
        "Use Brand Resources as the staff-facing reference concept; keep Brand Assets as Marketing execution/library if needed. Do not repurpose ClientServices yet.",
        "Tyler + business/content owner",
        (
            "docs/brand-resources-target-model.md defines Brand Resources as reusable reference material, not CRM/client records.",
            "docs/clientservices-to-brand-resources-transition-plan.md says ClientServices assumptions are legacy.",
            "docs/legacy-clientservices-cleanup-register.md prohibits tenant cleanup without inventory and approval.",
        ),
        (
            Option("A", "Brand Resources = staff reference; Brand Assets = Marketing execution library.", "Clear separation of audience and purpose.", "Requires explaining two related terms."),
            Option("B", "Consolidate everything to Brand Resources.", "Simplest user-facing label.", "Unsafe before dependency/content review."),
            Option("C", "Keep Brand Assets as the only user-facing term.", "Matches current Marketing wording.", "Weakens replacement of ClientServices assumptions."),
            Option("D", "Defer until owners classify current usage.", "Avoids premature naming decision.", "Slows launch cleanup."),
        ),
        (
            "Approve final vocabulary.",
            "Create follow-up Brand Resources implementation issue after decision.",
            "Do not rename/delete/repurpose live ClientServices resources yet.",
        ),
    ),
    Decision(
        "OD-003",
        "Dynamic security group owners",
        "AllStaff, Managers, Marketing, Stylists, and External have zero owners in Graph.",
        "Nobody is clearly accountable when metadata, membership, or access drifts.",
        "Assign at least two owners per group: MSP/operator plus business/access owner.",
        "Tyler / Megan",
        (
            "docs/delta-crown-identity-inventory-summary.md shows zero owners for all five dynamic groups.",
            "Current group counts: AllStaff=6, Managers=1, Marketing=0, Stylists=0, External=0.",
            "Production launch readiness report marks named operational owners as a no-go item.",
        ),
        (
            Option("A", "Two owners per group: MSP operator + business/access owner.", "Best production governance.", "Requires naming humans now."),
            Option("B", "One central identity owner for all dynamic groups.", "Fastest owner assignment.", "Weak business accountability."),
            Option("C", "Keep ownerless until metadata cleanup finishes.", "Avoids churn.", "Leaves governance gap open."),
        ),
        (
            "Name owner candidates for each group.",
            "Create tenant change issue for owner assignment.",
            "Verify owner assignment via Graph after change.",
        ),
    ),
    Decision(
        "OD-004",
        "DLP test mode vs enforce path",
        "DCE-Data-Protection and Corp-Data-Protection are TestWithNotifications; External-Sharing-Block is enabled.",
        "Test mode is not final enforcement. Claims about production DLP must distinguish test from enforce.",
        "Review raw DLP rule details, then choose a staged enforce flip unless rule review proves very low risk.",
        "Tyler + security/compliance owner",
        (
            "docs/delta-crown-compliance-inventory-summary.md lists 6 DLP policies and 8 rules.",
            "DCE-Data-Protection mode: TestWithNotifications.",
            "Corp-Data-Protection mode: TestWithNotifications.",
            "External-Sharing-Block mode: Enable.",
        ),
        (
            Option("A", "Keep test mode for 30 days and review alerts.", "Lower business disruption risk.", "Not fully enforcing."),
            Option("B", "Flip both policies to enforce in one window.", "Fastest enforcement posture.", "Higher false-positive risk."),
            Option("C", "Enforce one policy first, then the other.", "Balanced staged rollout.", "Takes longer."),
            Option("D", "Keep test mode indefinitely.", "Avoids disruption.", "Not production-grade."),
        ),
        (
            "Review local raw DLP rule exports.",
            "Pick enforce order and maintenance window.",
            "Create change issue with rollback owner and validation plan.",
        ),
    ),
    Decision(
        "OD-005",
        "DeltaCrown-TeamsProvisioner-TEMP app fate",
        "TEMP app registration exists with three password credentials expired on 2026-04-16.",
        "Expired temporary apps are security/governance clutter unless dependency and owner are documented.",
        "Delete the app if no dependency remains. Otherwise rename/document owner and remove expired secrets.",
        "Tyler / tenant app owner",
        (
            "docs/delta-crown-security-apps-licenses-inventory-summary.md lists DeltaCrown-TeamsProvisioner-TEMP.",
            "Inventory found three expired app password credentials for the TEMP app.",
            "Safety notes say not to delete app registrations without dependency review and approval.",
        ),
        (
            Option("A", "Delete app after dependency check.", "Cleanest if no longer used.", "Requires confidence no automation depends on it."),
            Option("B", "Keep, rename, assign owner, remove expired credentials, document purpose.", "Safe if still needed.", "Keeps extra app surface."),
            Option("C", "Keep as-is temporarily with deadline.", "Buys time.", "Still leaves known smell."),
        ),
        (
            "Confirm whether any Teams provisioning automation still uses the app.",
            "Create cleanup issue for delete or rename/credential cleanup.",
            "Verify app inventory after cleanup.",
        ),
    ),
    Decision(
        "OD-006",
        "ClientServices deprecation banner / cleanup",
        "Legacy ClientServices artifacts are documented as empty/broad and client records are out of M365 scope.",
        "Users may treat old ClientServices resources as approved client-data storage, conflicting with current scope.",
        "Add a visible deprecation/owner note first. Do not delete, rename, or repurpose until owner approval and cleanup plan exist.",
        "Tyler + data/content owner",
        (
            "docs/legacy-clientservices-cleanup-register.md states ClientServices/client-record assumptions are legacy.",
            "docs/delta-crown-sharepoint-pnp-inventory-summary.md documents ClientServices artifacts and permissions metadata.",
            "Brand Resources target model says client records are out of Microsoft 365 scope.",
        ),
        (
            Option("A", "Add deprecation/banner notice: do not use for client records; pending cleanup.", "Immediate clear signal without destructive changes.", "Requires tenant page/banner edit."),
            Option("B", "Remove navigation links only.", "Reduces accidental use.", "Does not explain what happened."),
            Option("C", "Archive or delete after owner approval.", "Cleaner long-term.", "Unsafe before dependency/content approval."),
            Option("D", "Repurpose as Brand Resources after approval.", "May reuse existing resource.", "Risky URL/history/permission baggage."),
        ),
        (
            "Approve banner wording.",
            "Create tenant change issue for non-destructive deprecation signal.",
            "Decide later: archive, replace, repurpose, or remove.",
        ),
    ),
)


def formats(workbook: xlsxwriter.Workbook) -> dict[str, xlsxwriter.format.Format]:
    base = {"font_name": "Aptos", "font_size": 11, "text_wrap": True, "valign": "top"}
    return {
        "title": workbook.add_format({"font_name": "Aptos Display", "font_size": 20, "bold": True, "font_color": "#0B3D3D"}),
        "subtitle": workbook.add_format({"font_name": "Aptos", "font_size": 11, "italic": True, "font_color": "#666666", "text_wrap": True, "valign": "top"}),
        "section": workbook.add_format({**base, "font_size": 13, "bold": True, "font_color": "#0B3D3D"}),
        "header": workbook.add_format({**base, "bold": True, "font_color": "#FFFFFF", "bg_color": "#0B3D3D", "border": 1, "border_color": "#D9E2F3", "align": "center"}),
        "body": workbook.add_format({**base, "border": 1, "border_color": "#D9E2F3"}),
        "body_bold": workbook.add_format({**base, "bold": True, "border": 1, "border_color": "#D9E2F3"}),
        "decision": workbook.add_format({**base, "bg_color": "#FFF2CC", "border": 1, "border_color": "#D9E2F3"}),
        "green": workbook.add_format({**base, "bg_color": "#E2F0D9", "border": 1, "border_color": "#D9E2F3"}),
        "red": workbook.add_format({**base, "bg_color": "#FCE4D6", "border": 1, "border_color": "#D9E2F3"}),
        "blue": workbook.add_format({**base, "bg_color": "#DDEBF7", "border": 1, "border_color": "#D9E2F3"}),
    }


def setup_sheet(ws: xlsxwriter.worksheet.Worksheet, widths: list[int]) -> None:
    ws.hide_gridlines(2)
    ws.freeze_panes(4, 0)
    ws.set_default_row(36)
    for i, width in enumerate(widths):
        ws.set_column(i, i, width)


def write_title(ws: xlsxwriter.worksheet.Worksheet, title: str, subtitle: str, fmt: dict[str, xlsxwriter.format.Format], cols: int) -> int:
    ws.merge_range(0, 0, 0, cols - 1, title, fmt["title"])
    ws.merge_range(1, 0, 1, cols - 1, subtitle, fmt["subtitle"])
    ws.set_row(0, 30)
    ws.set_row(1, 42)
    return 3


def write_table(ws, row: int, headers: list[str], rows: list[list[object]], fmt, autofilter: bool = True) -> int:
    for col, header in enumerate(headers):
        ws.write(row, col, header, fmt["header"])
    for r_offset, values in enumerate(rows, start=1):
        for col, value in enumerate(values):
            cell_fmt = fmt["decision"] if isinstance(value, str) and value == "TBD" else fmt["body"]
            ws.write(row + r_offset, col, value, cell_fmt)
    if autofilter and rows:
        ws.autofilter(row, 0, row + len(rows), len(headers) - 1)
    return row + len(rows) + 2


def dashboard(workbook, fmt) -> None:
    ws = workbook.add_worksheet("Dashboard")
    setup_sheet(ws, [28, 36, 80, 20, 20])
    row = write_title(ws, "Delta Crown Owner Decision Workbook", "Launch-blocking owner decisions, recommendations, evidence, and follow-up actions", fmt, 5)
    row = write_table(ws, row, ["Metric", "Value", "Why it matters"], [
        ["Workbook purpose", "Owner launch decisions", "Converts launch blockers into explicit choices."],
        ["Decision count", len(DECISIONS), "Six decisions currently block full production-launch claims."],
        ["Recommended launch posture", "Controlled pilot / owner validation", "Built and hardened, but not full production launch yet."],
        ["Top technical blocker", "Teams channel read context", "Members readable; team/channel detail still blocked."],
        ["Top governance blocker", "Named owners + DLP posture", "Needs accountable owners and enforcement decisions."],
    ], fmt)
    ws.write(row, 0, "How to use this workbook", fmt["section"])
    for idx, text in enumerate([
        "1. Start on Decision Matrix and pick a Tyler decision for each row.",
        "2. Use OD-001 through OD-006 tabs for evidence, risks, options, and recommendations.",
        "3. Use Action Tracker to split approved work into small follow-up change issues.",
        "4. Do not make tenant-impacting changes from this workbook alone; create tracked change issues first.",
    ], start=row + 1):
        ws.merge_range(idx, 0, idx, 2, text, fmt["body"])


def decision_matrix(workbook, fmt) -> None:
    ws = workbook.add_worksheet("Decision Matrix")
    setup_sheet(ws, [11, 30, 46, 44, 50, 24, 22, 16, 34])
    row = write_title(ws, "Decision Matrix", "One-line view of what Tyler/Megan need to decide", fmt, 9)
    rows = [[d.decision_id, d.title, d.current_state, d.risk, d.recommendation, d.owner_needed, "TBD", "TBD", ""] for d in DECISIONS]
    write_table(ws, row, ["ID", "Decision", "Current state", "Risk", "Recommendation", "Owner needed", "Tyler decision", "Decision date", "Notes"], rows, fmt)


def action_tracker(workbook, fmt) -> None:
    ws = workbook.add_worksheet("Action Tracker")
    setup_sheet(ws, [13, 62, 18, 28, 18, 16, 36])
    row = write_title(ws, "Action Tracker", "Follow-up actions after decisions are approved", fmt, 7)
    rows = []
    for d in DECISIONS:
        rows.extend([[d.decision_id, action, "TBD", d.owner_needed, "Not started", "TBD", ""] for action in d.followups])
    write_table(ws, row, ["Decision ID", "Follow-up action", "Type", "Owner", "Status", "Target date", "Notes"], rows, fmt)


def evidence_sheet(workbook, fmt) -> None:
    ws = workbook.add_worksheet("Evidence")
    setup_sheet(ws, [14, 88, 46])
    row = write_title(ws, "Evidence", "Supporting evidence behind recommendations", fmt, 3)
    rows = []
    for d in DECISIONS:
        rows.extend([[d.decision_id, evidence, "See repo docs and owner-decision worksheet."] for evidence in d.evidence])
    write_table(ws, row, ["Decision ID", "Evidence", "Source / context"], rows, fmt)


def glossary(workbook, fmt) -> None:
    ws = workbook.add_worksheet("Glossary")
    setup_sheet(ws, [26, 90])
    row = write_title(ws, "Glossary", "Plain-English definitions for decision terms", fmt, 2)
    write_table(ws, row, ["Term", "Meaning"], [
        ["DDG", "Dynamic Distribution Group for Exchange mail routing."],
        ["Dynamic security group", "Entra group whose membership is calculated from user attributes."],
        ["TestWithNotifications", "DLP policy mode that warns/tests without full enforcement."],
        ["Brand Resources", "Approved staff-facing reference material, not client records."],
        ["Brand Assets", "Marketing execution/asset library concept."],
        ["ClientServices", "Legacy concept/artifacts; not approved client-record storage in M365."],
        ["Controlled pilot", "Limited validation state before full launch approval."],
    ], fmt)


def decision_detail(workbook, fmt, d: Decision) -> None:
    ws = workbook.add_worksheet(d.decision_id)
    setup_sheet(ws, [24, 70, 50, 50])
    row = write_title(ws, f"{d.decision_id} — {d.title}", "Decision detail, options, evidence, and action prompts", fmt, 4)
    row = write_table(ws, row, ["Field", "Detail"], [
        ["Current state", d.current_state],
        ["Risk", d.risk],
        ["Recommendation", d.recommendation],
        ["Owner needed", d.owner_needed],
        ["Tyler selected option", "TBD"],
        ["Approval / date", "TBD"],
        ["Follow-up issue", "TBD"],
    ], fmt, autofilter=False)
    ws.write(row, 0, "Options", fmt["section"])
    row = write_table(ws, row + 1, ["Option", "Description", "Pros", "Cons"], [[o.key, o.description, o.pros, o.cons] for o in d.options], fmt, autofilter=False)
    ws.write(row, 0, "Supporting evidence", fmt["section"])
    row = write_table(ws, row + 1, ["Evidence", "Detail"], [["Evidence", evidence] for evidence in d.evidence], fmt, autofilter=False)
    ws.write(row, 0, "Follow-up actions", fmt["section"])
    write_table(ws, row + 1, ["Action", "Detail"], [["Action", action] for action in d.followups], fmt, autofilter=False)


def build() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    workbook = xlsxwriter.Workbook(OUT)
    fmt = formats(workbook)
    dashboard(workbook, fmt)
    decision_matrix(workbook, fmt)
    action_tracker(workbook, fmt)
    evidence_sheet(workbook, fmt)
    glossary(workbook, fmt)
    for decision in DECISIONS:
        decision_detail(workbook, fmt, decision)
    workbook.set_properties({
        "title": "Delta Crown Owner Decision Workbook",
        "subject": "Launch decision matrix",
        "author": "Richard / code-puppy-e7999e",
        "comments": "Generated with XlsxWriter for Microsoft Excel compatibility.",
    })
    workbook.close()


def validate() -> None:
    loaded = load_workbook(OUT)
    expected = {"Dashboard", "Decision Matrix", "Action Tracker", "Evidence", "Glossary"} | {d.decision_id for d in DECISIONS}
    missing = expected - set(loaded.sheetnames)
    if missing:
        raise RuntimeError(f"Workbook missing sheets: {sorted(missing)}")
    if loaded["Dashboard"]["A1"].value != "Delta Crown Owner Decision Workbook":
        raise RuntimeError("Dashboard title missing")
    if loaded["Decision Matrix"].max_row < len(DECISIONS) + 4:
        raise RuntimeError("Decision Matrix missing decision rows")


def main() -> None:
    build()
    validate()
    print(f"Wrote Excel-compatible workbook: {OUT} ({OUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
