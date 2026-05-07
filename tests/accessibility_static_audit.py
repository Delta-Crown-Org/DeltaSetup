#!/usr/bin/env python3
"""Static accessibility smoke audit for the public DeltaSetup pages.

This is not a substitute for browser + screen-reader testing, but it catches
repeatable repo-level issues: broken local refs, broken anchors, duplicate IDs,
missing accessible names on controls, missing image alt text, heading jumps, and
known color-token contrast ratios against the project's main surfaces.
"""
from __future__ import annotations

from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
import re
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
PAGES = ["index.html", "operations.html", "msp.html"]
VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"}

HEX_COLORS = {
    "teal-deeper": "#0A1F1C",
    "surface-dark": "#0D2925",
    "surface": "#FAFAF7",
    "gold": "#D4A84B",
    "gold-light": "#E8C989",
    "gold-dark": "#6E4F0E",
    "teal-light": "#4A9B8E",
    "teal-on-dark": "#5DB7A9",
    "success": "#66BB6A",
    "danger": "#A51C16",
    "danger-on-dark": "#FF8A80",
    "neutral": "#B0BEC5",
    "white": "#FFFFFF",
    "text": "#1A2A3A",
    "text-secondary": "#465463",
    "sidebar-bg": "#0A1F1C",
}

CONTRAST_PAIRS = [
    ("white", "teal-deeper", "Primary white text on dark"),
    ("gold", "teal-deeper", "Gold labels on dark"),
    ("gold-light", "teal-deeper", "Gold-light labels on dark"),
    ("gold-dark", "surface", "Gold-dark text/focus on light"),
    ("teal-on-dark", "teal-deeper", "Teal-on-dark text on dark"),
    ("success", "teal-deeper", "Success text on dark"),
    ("danger-on-dark", "teal-deeper", "Danger-on-dark text on dark"),
    ("neutral", "teal-deeper", "Neutral/skipped text on dark"),
    ("text", "surface", "Primary text on light"),
    ("text-secondary", "surface", "Secondary text on light"),
]

ALPHA_PAIRS = [
    (0.92, "teal-deeper", "--text-on-dark"),
    (0.70, "teal-deeper", "--text-on-dark-muted"),
    (0.62, "teal-deeper", "--text-on-dark-subtle/sidebar/footer"),
    (0.78, "teal-deeper", ".status--pending"),
]

@dataclass
class Finding:
    level: str
    page: str
    message: str

class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.stack: list[tuple[str, tuple[int, int]]] = []
        self.errors: list[str] = []
        self.ids: dict[str, int] = {}
        self.hrefs: list[tuple[str, tuple[int, int]]] = []
        self.refs: list[tuple[str, tuple[int, int]]] = []
        self.images: list[tuple[dict[str, str], tuple[int, int]]] = []
        self.buttons: list[tuple[dict[str, str], tuple[int, int], str]] = []
        self._button_stack: list[tuple[dict[str, str], tuple[int, int], list[str]]] = []
        self.headings: list[tuple[int, tuple[int, int]]] = []
        self.landmarks: list[str] = []

    def handle_starttag(self, tag: str, attrs_list: list[tuple[str, str | None]]) -> None:
        attrs = {k: (v or "") for k, v in attrs_list}
        pos = self.getpos()
        if "id" in attrs:
            self.ids[attrs["id"]] = self.ids.get(attrs["id"], 0) + 1
        if tag == "a" and attrs.get("href"):
            self.hrefs.append((attrs["href"], pos))
        if tag == "link" and "stylesheet" in attrs.get("rel", "") and attrs.get("href"):
            self.refs.append((attrs["href"], pos))
        if tag == "script" and attrs.get("src"):
            self.refs.append((attrs["src"], pos))
        if tag == "img":
            self.images.append((attrs, pos))
        if tag == "button":
            self._button_stack.append((attrs, pos, []))
        if re.fullmatch(r"h[1-6]", tag):
            self.headings.append((int(tag[1]), pos))
        if tag in {"main", "nav", "header", "footer", "aside"}:
            self.landmarks.append(tag)
        if tag not in VOID:
            self.stack.append((tag, pos))

    def handle_endtag(self, tag: str) -> None:
        pos = self.getpos()
        if not self.stack:
            self.errors.append(f"extra closing </{tag}> at {pos}")
            return
        opened, opened_pos = self.stack.pop()
        if opened != tag:
            self.errors.append(f"mismatch: opened <{opened}> at {opened_pos}, closed </{tag}> at {pos}")
        if tag == "button" and self._button_stack:
            attrs, button_pos, chunks = self._button_stack.pop()
            self.buttons.append((attrs, button_pos, " ".join("".join(chunks).split())))

    def handle_data(self, data: str) -> None:
        if self._button_stack:
            self._button_stack[-1][2].append(data)


def srgb(hex_color: str) -> tuple[int, int, int]:
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def rel_lum(rgb: tuple[int, int, int]) -> float:
    def chan(c: int) -> float:
        v = c / 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (chan(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(fg: str, bg: str) -> float:
    l1, l2 = rel_lum(srgb(fg)), rel_lum(srgb(bg))
    hi, lo = max(l1, l2), min(l1, l2)
    return (hi + 0.05) / (lo + 0.05)


def blend_white(alpha: float, bg_hex: str) -> str:
    bg = srgb(bg_hex)
    rgb = tuple(round(255 * alpha + c * (1 - alpha)) for c in bg)
    return "#" + "".join(f"{c:02X}" for c in rgb)


def audit_page(page: str) -> list[Finding]:
    parser = PageParser()
    text = (ROOT / page).read_text(encoding="utf-8")
    parser.feed(text)
    findings: list[Finding] = []

    for err in parser.errors:
        findings.append(Finding("FAIL", page, err))
    if parser.stack:
        findings.append(Finding("FAIL", page, f"unclosed tags remain: {parser.stack[:5]}"))

    for id_value, count in parser.ids.items():
        if count > 1:
            findings.append(Finding("FAIL", page, f"duplicate id #{id_value} appears {count} times"))

    for href, pos in parser.hrefs:
        if href.startswith("#") and href != "#" and href[1:] not in parser.ids:
            findings.append(Finding("FAIL", page, f"broken same-page anchor {href} at {pos}"))
        if href.startswith("./") and "#" in href:
            target_file, target_id = href[2:].split("#", 1)
            target_path = ROOT / target_file
            if target_path.exists():
                target_parser = PageParser()
                target_parser.feed(target_path.read_text(encoding="utf-8"))
                if target_id not in target_parser.ids:
                    findings.append(Finding("FAIL", page, f"broken cross-page anchor {href} at {pos}"))

    for ref, pos in parser.refs:
        if ref.startswith("http"):
            continue
        if not (ROOT / ref.split("?", 1)[0]).exists():
            findings.append(Finding("FAIL", page, f"missing local ref {ref} at {pos}"))

    for attrs, pos in parser.images:
        if "alt" not in attrs:
            findings.append(Finding("FAIL", page, f"img missing alt at {pos}"))

    for attrs, pos, text in parser.buttons:
        if not (attrs.get("aria-label") or attrs.get("aria-labelledby") or attrs.get("title") or text):
            findings.append(Finding("FAIL", page, f"button missing accessible name at {pos}"))

    last = 0
    for level, pos in parser.headings:
        if last and level > last + 1:
            findings.append(Finding("WARN", page, f"heading jump h{last}->h{level} at {pos}"))
        last = level

    if "main" not in parser.landmarks:
        findings.append(Finding("FAIL", page, "missing <main> landmark"))
    return findings


def audit_contrast() -> list[Finding]:
    findings: list[Finding] = []
    for fg_name, bg_name, label in CONTRAST_PAIRS:
        ratio = contrast(HEX_COLORS[fg_name], HEX_COLORS[bg_name])
        level = "PASS" if ratio >= 7 else "WARN" if ratio >= 4.5 else "FAIL"
        findings.append(Finding(level, "contrast", f"{label}: {fg_name} on {bg_name} = {ratio:.2f}:1"))
    for alpha, bg_name, label in ALPHA_PAIRS:
        fg = blend_white(alpha, HEX_COLORS[bg_name])
        ratio = contrast(fg, HEX_COLORS[bg_name])
        level = "PASS" if ratio >= 7 else "WARN" if ratio >= 4.5 else "FAIL"
        findings.append(Finding(level, "contrast", f"{label}: rgba(255,255,255,{alpha}) over {bg_name} = {ratio:.2f}:1"))
    return findings


def main() -> int:
    findings = []
    for page in PAGES:
        findings.extend(audit_page(page))
    findings.extend(audit_contrast())

    for finding in findings:
        print(f"{finding.level:4} {finding.page:15} {finding.message}")
    fails = [f for f in findings if f.level == "FAIL"]
    warns = [f for f in findings if f.level == "WARN"]
    print(f"\nSummary: {len(fails)} FAIL, {len(warns)} WARN, {len(findings) - len(fails) - len(warns)} PASS")
    return 1 if fails else 0

if __name__ == "__main__":
    raise SystemExit(main())
