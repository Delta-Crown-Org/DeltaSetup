#!/usr/bin/env python3
"""Browser smoke audit for public static pages.

Checks page load, console errors, horizontal overflow at core breakpoints, and
skip-link focus behavior. This complements tests/accessibility_static_audit.py;
it is not a full WCAG certification tool.
"""
from __future__ import annotations

from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
PAGES = ["index.html", "operations.html", "msp.html"]
VIEWPORTS = [
    (390, 844, "mobile"),
    (768, 1024, "tablet"),
    (1440, 1000, "desktop"),
]


def page_url(page: str) -> str:
    return "file://" + (ROOT / page).resolve().as_posix()


def main() -> int:
    failures: list[str] = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        for page_name in PAGES:
            for width, height, label in VIEWPORTS:
                page = browser.new_page(viewport={"width": width, "height": height})
                console_errors: list[str] = []
                page.on("console", lambda msg: console_errors.append(msg.text) if msg.type == "error" else None)
                page.goto(page_url(page_name), wait_until="load")
                title = page.title()
                overflow = page.evaluate("document.documentElement.scrollWidth - document.documentElement.clientWidth")
                if overflow > 2:
                    failures.append(f"{page_name} {label}: horizontal overflow {overflow}px")
                if console_errors:
                    failures.append(f"{page_name} {label}: console errors: {console_errors[:3]}")
                print(f"PASS {page_name:15} {label:7} title={title!r} overflow={overflow}px")
                page.close()

            page = browser.new_page(viewport={"width": 390, "height": 844})
            page.goto(page_url(page_name), wait_until="load")
            page.keyboard.press("Tab")
            focused_href = page.evaluate("document.activeElement && document.activeElement.getAttribute('href')")
            if focused_href != "#main-content":
                failures.append(f"{page_name}: first Tab did not focus skip link (got {focused_href!r})")
            else:
                page.keyboard.press("Enter")
                focused_id = page.evaluate("document.activeElement && document.activeElement.id")
                if focused_id != "main-content":
                    failures.append(f"{page_name}: skip link did not move focus to main-content (got {focused_id!r})")
                else:
                    print(f"PASS {page_name:15} skip-link focuses main-content")
            page.close()
        browser.close()

    if failures:
        print("\nFAILURES")
        for failure in failures:
            print(f"FAIL {failure}")
        return 1
    print("\nSummary: browser smoke audit passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
