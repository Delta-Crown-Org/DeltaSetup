#!/usr/bin/env python3
"""Generate Delta Crown owner-decision Excel workbook without third-party deps."""

from __future__ import annotations

import html
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

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


SHEETS = ["Dashboard", "Decision Matrix", "Action Tracker", "Evidence", "Glossary"] + [d.decision_id for d in DECISIONS]


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def col_name(index: int) -> str:
    result = ""
    while index:
        index, rem = divmod(index - 1, 26)
        result = chr(65 + rem) + result
    return result


def cell_ref(row: int, col: int) -> str:
    return f"{col_name(col)}{row}"


def inline(value: object, style: int | None = None) -> str:
    s_attr = f' s="{style}"' if style is not None else ""
    return f'<c{ s_attr } t="inlineStr"><is><t>{esc(value)}</t></is></c>'


def number(value: int | float, style: int | None = None) -> str:
    s_attr = f' s="{style}"' if style is not None else ""
    return f'<c{ s_attr }><v>{value}</v></c>'


def row_xml(row_num: int, values: Iterable[object], style: int | None = None) -> str:
    cells = []
    for i, value in enumerate(values, start=1):
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            cell = number(value, style)
        else:
            cell = inline(value, style)
        cells.append(cell.replace("<c", f'<c r="{cell_ref(row_num, i)}"', 1))
    return f'<row r="{row_num}">{"".join(cells)}</row>'


def sheet_xml(rows: list[list[object]], widths: dict[int, float] | None = None, freeze: str | None = None) -> str:
    max_col = max((len(r) for r in rows), default=1)
    max_row = len(rows)
    cols = ""
    if widths:
        cols = "<cols>" + "".join(
            f'<col min="{c}" max="{c}" width="{w}" customWidth="1"/>' for c, w in widths.items()
        ) + "</cols>"
    pane = ""
    if freeze:
        pane = (
            "<sheetViews><sheetView workbookViewId=\"0\">"
            f"<pane ySplit=\"1\" topLeftCell=\"{freeze}\" activePane=\"bottomLeft\" state=\"frozen\"/>"
            "</sheetView></sheetViews>"
        )
    xml_rows = []
    for idx, values in enumerate(rows, start=1):
        style = 1 if idx == 1 else None
        xml_rows.append(row_xml(idx, values, style))
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        f"{pane}<dimension ref=\"A1:{cell_ref(max_row, max_col)}\"/>{cols}"
        f"<sheetData>{''.join(xml_rows)}</sheetData>"
        "</worksheet>"
    )


def styles_xml() -> str:
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2"><font><sz val="11"/><name val="Aptos"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Aptos"/></font></fonts>
  <fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF0B3D3D"/><bgColor indexed="64"/></patternFill></fill></fills>
  <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFill="1" applyFont="1" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf></cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>'''


def workbook_xml() -> str:
    sheets = "".join(
        f'<sheet name="{esc(name)}" sheetId="{i}" r:id="rId{i}"/>' for i, name in enumerate(SHEETS, start=1)
    )
    return f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>{sheets}</sheets></workbook>'''


def workbook_rels() -> str:
    rels = [
        f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>'
        for i in range(1, len(SHEETS) + 1)
    ]
    rels.append('<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>')
    return f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">{''.join(rels)}</Relationships>'''


def content_types() -> str:
    overrides = [
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>',
    ]
    overrides.extend(
        f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        for i in range(1, len(SHEETS) + 1)
    )
    return f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/>{''.join(overrides)}</Types>'''


def root_rels() -> str:
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'''


def build_rows() -> dict[str, list[list[object]]]:
    rows: dict[str, list[list[object]]] = {}
    rows["Dashboard"] = [
        ["Metric", "Value", "Why it matters"],
        ["Workbook purpose", "Owner launch decisions", "Converts remaining launch blockers into explicit choices."],
        ["Decisions", len(DECISIONS), "Six decisions block full production-launch claims."],
        ["Recommended launch posture", "Controlled pilot / owner validation", "Full launch still needs decisions and Teams channel evidence."],
        ["Top technical blocker", "Teams channel read context", "Members are readable; team/channel detail still blocked."],
        ["Top governance blocker", "Named owners + DLP posture", "Production claims need accountable owners and enforcement decisions."],
    ]
    rows["Decision Matrix"] = [["ID", "Decision", "Current state", "Risk", "Recommendation", "Owner needed", "Tyler decision", "Decision date", "Notes"]]
    for d in DECISIONS:
        rows["Decision Matrix"].append([d.decision_id, d.title, d.current_state, d.risk, d.recommendation, d.owner_needed, "TBD", "TBD", ""])
    rows["Action Tracker"] = [["Decision ID", "Follow-up action", "Type", "Owner", "Status", "Target date", "Notes"]]
    for d in DECISIONS:
        for action in d.followups:
            rows["Action Tracker"].append([d.decision_id, action, "TBD", d.owner_needed, "Not started", "TBD", ""])
    rows["Evidence"] = [["Decision ID", "Evidence", "Source / context"]]
    for d in DECISIONS:
        for ev in d.evidence:
            rows["Evidence"].append([d.decision_id, ev, "See repo docs referenced in owner-decision worksheet."])
    rows["Glossary"] = [
        ["Term", "Meaning"],
        ["DDG", "Dynamic Distribution Group for Exchange mail routing."],
        ["Dynamic security group", "Entra group whose membership is calculated from user attributes."],
        ["TestWithNotifications", "DLP policy mode that warns/tests without full enforcement."],
        ["Brand Resources", "Approved staff-facing reference material, not client records."],
        ["Brand Assets", "Marketing execution/asset library concept."],
        ["ClientServices", "Legacy concept/artifacts; not approved client-record storage in M365."],
        ["Controlled pilot", "Limited validation state before full launch approval."],
    ]
    for d in DECISIONS:
        decision_rows = [
            ["Field", "Detail"],
            ["Decision ID", d.decision_id],
            ["Title", d.title],
            ["Current state", d.current_state],
            ["Risk", d.risk],
            ["Recommendation", d.recommendation],
            ["Owner needed", d.owner_needed],
            ["Tyler selected option", "TBD"],
            ["Approval / date", "TBD"],
            ["Follow-up issue", "TBD"],
            [],
            ["Options", "Description", "Pros", "Cons"],
        ]
        for opt in d.options:
            decision_rows.append([opt.key, opt.description, opt.pros, opt.cons])
        decision_rows.append([])
        decision_rows.append(["Evidence", "Detail"])
        for ev in d.evidence:
            decision_rows.append(["Evidence", ev])
        decision_rows.append([])
        decision_rows.append(["Follow-up actions", "Detail"])
        for action in d.followups:
            decision_rows.append(["Action", action])
        rows[d.decision_id] = decision_rows
    return rows


def write_workbook() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    rows_by_sheet = build_rows()
    widths = {1: 20, 2: 42, 3: 52, 4: 52, 5: 52, 6: 26, 7: 22, 8: 18, 9: 35}
    with zipfile.ZipFile(OUT, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", content_types())
        zf.writestr("_rels/.rels", root_rels())
        zf.writestr("xl/workbook.xml", workbook_xml())
        zf.writestr("xl/_rels/workbook.xml.rels", workbook_rels())
        zf.writestr("xl/styles.xml", styles_xml())
        for i, sheet in enumerate(SHEETS, start=1):
            zf.writestr(f"xl/worksheets/sheet{i}.xml", sheet_xml(rows_by_sheet[sheet], widths, "A2"))
    print(f"Wrote {OUT} ({OUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    write_workbook()
