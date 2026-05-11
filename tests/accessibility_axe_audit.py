#!/usr/bin/env python3
"""Automated axe-core accessibility regression for the public DeltaSetup pages.

Loads each published HTML page in headless Chromium via Playwright, injects a
vendored copy of axe-core (`tests/vendor/axe.min.js`), runs the WCAG 2.0/2.1/2.2
A, AA, and AAA rule sets, and reports any violations.

Why this exists
---------------
`tests/accessibility_static_audit.py` covers structural/contrast issues we can
reason about from raw HTML and design tokens. `tests/browser_smoke_audit.py`
covers layout/console/skip-link issues. Neither runs the axe rule engine. This
script closes that gap and is the third leg of the public-page quality gate.

Exit code is 0 only when there are no violations across all pages.

Run:
    python3 tests/accessibility_axe_audit.py [--page index.html ...] [--no-aaa]
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
AXE_PATH = Path(__file__).resolve().parent / "vendor" / "axe.min.js"
DEFAULT_PAGES = ("index.html", "operations.html", "msp.html")

# Tags from https://github.com/dequelabs/axe-core/blob/develop/doc/API.md#options-parameter
# We intentionally include AAA because this project is targeting WCAG 2.2 AAA.
TAGS_AA = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"]
TAGS_AAA = ["wcag2aaa", "wcag21aaa"]
# axe-core has no separate `wcag22aaa` tag yet; AAA rules from 2.0/2.1 cover it.


@dataclass
class PageResult:
    page: str
    url: str
    violations: list[dict]
    incomplete: list[dict]
    passes_count: int
    inapplicable_count: int

    @property
    def violation_count(self) -> int:
        return sum(len(v.get("nodes", [])) for v in self.violations)


def page_url(page: str) -> str:
    return "file://" + (ROOT / page).resolve().as_posix()


def run_axe(page, tags: list[str]) -> dict:
    """Inject axe-core and run it against the loaded page.

    Uses ``add_script_tag(path=...)`` so axe is read from disk and injected
    inline — works under ``file://`` without cross-origin headaches.
    """
    if not AXE_PATH.exists():
        raise RuntimeError(
            f"axe-core not vendored at {AXE_PATH}. "
            "Run: curl -sSL https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.10.2/axe.min.js -o tests/vendor/axe.min.js"
        )
    page.add_script_tag(path=str(AXE_PATH))
    # Run axe with explicit tag list. resultTypes trims payload size.
    js = """
        async (tags) => {
            const results = await window.axe.run(document, {
                runOnly: { type: 'tag', values: tags },
                resultTypes: ['violations', 'incomplete', 'passes', 'inapplicable'],
            });
            // Strip large fields we don't need to keep stdout sane.
            const trim = (rule) => ({
                id: rule.id,
                impact: rule.impact,
                help: rule.help,
                helpUrl: rule.helpUrl,
                tags: rule.tags,
                nodes: (rule.nodes || []).map(n => ({
                    target: n.target,
                    failureSummary: n.failureSummary,
                    html: (n.html || '').slice(0, 240),
                })),
            });
            return {
                violations: results.violations.map(trim),
                incomplete: results.incomplete.map(trim),
                passes_count: results.passes.length,
                inapplicable_count: results.inapplicable.length,
            };
        }
    """
    return page.evaluate(js, tags)


def audit_pages(pages: Iterable[str], tags: list[str]) -> list[PageResult]:
    results: list[PageResult] = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        try:
            for page_name in pages:
                ctx = browser.new_context(viewport={"width": 1440, "height": 1000})
                page = ctx.new_page()
                url = page_url(page_name)
                page.goto(url, wait_until="load")
                # Give any deferred render (focus indicators, IntersectionObserver, etc.) a tick.
                page.wait_for_timeout(150)
                raw = run_axe(page, tags)
                results.append(
                    PageResult(
                        page=page_name,
                        url=url,
                        violations=raw["violations"],
                        incomplete=raw["incomplete"],
                        passes_count=raw["passes_count"],
                        inapplicable_count=raw["inapplicable_count"],
                    )
                )
                ctx.close()
        finally:
            browser.close()
    return results


def format_human(results: list[PageResult]) -> str:
    lines: list[str] = []
    for r in results:
        header = (
            f"{r.page:18} violations={len(r.violations):>2} "
            f"nodes={r.violation_count:>3} incomplete={len(r.incomplete):>2} "
            f"passes={r.passes_count:>3}"
        )
        lines.append(header)
        for v in r.violations:
            lines.append(f"  FAIL [{v['impact'] or 'n/a'}] {v['id']}: {v['help']}")
            lines.append(f"       {v['helpUrl']}")
            for node in v["nodes"][:5]:
                target = " ".join(map(str, node["target"]))
                lines.append(f"         target: {target}")
                summary = (node.get("failureSummary") or "").replace("\n", " | ")
                if summary:
                    lines.append(f"         why:    {summary[:200]}")
            if len(v["nodes"]) > 5:
                lines.append(f"         ...and {len(v['nodes']) - 5} more node(s)")
        for inc in r.incomplete:
            lines.append(f"  WARN [{inc['impact'] or 'n/a'}] {inc['id']}: {inc['help']} (axe could not auto-determine)")
    return "\n".join(lines)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run axe-core against the public DeltaSetup pages.")
    parser.add_argument(
        "--page",
        action="append",
        dest="pages",
        help="Page filename relative to repo root. Repeatable. Defaults to all public pages.",
    )
    parser.add_argument(
        "--no-aaa",
        action="store_true",
        help="Skip WCAG AAA rules (run AA only).",
    )
    parser.add_argument(
        "--json",
        dest="json_out",
        help="Write full machine-readable results to this path.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    pages = tuple(args.pages) if args.pages else DEFAULT_PAGES
    tags = TAGS_AA + ([] if args.no_aaa else TAGS_AAA)

    print(f"axe-core audit · pages={list(pages)} · tags={tags}")
    results = audit_pages(pages, tags)
    print(format_human(results))

    if args.json_out:
        Path(args.json_out).write_text(
            json.dumps(
                [
                    {
                        "page": r.page,
                        "url": r.url,
                        "violations": r.violations,
                        "incomplete": r.incomplete,
                        "passes_count": r.passes_count,
                        "inapplicable_count": r.inapplicable_count,
                    }
                    for r in results
                ],
                indent=2,
            ),
            encoding="utf-8",
        )
        print(f"\nWrote machine-readable results: {args.json_out}")

    total_violations = sum(len(r.violations) for r in results)
    total_nodes = sum(r.violation_count for r in results)
    total_incomplete = sum(len(r.incomplete) for r in results)
    print(
        f"\nSummary: {total_violations} violation rule(s), {total_nodes} node(s), "
        f"{total_incomplete} incomplete across {len(results)} page(s)"
    )
    return 1 if total_violations else 0


if __name__ == "__main__":
    raise SystemExit(main())
