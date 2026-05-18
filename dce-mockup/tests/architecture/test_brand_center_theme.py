"""
Fitness functions for the DCE SharePoint Brand Center theme.

These are architectural checks, not tenant calls. They prove that the
canonical DCE token source can deterministically produce a valid SharePoint
Brand Center / Add-SPOTheme palette before any quiet dev-site provisioning
runs.

Run with:
    pytest dce-mockup/tests/architecture/test_brand_center_theme.py -v
"""

import json
import re
from pathlib import Path

THIS_FILE = Path(__file__).resolve()
FIXTURE = THIS_FILE.parents[1] / "fixtures" / "sharepoint-theme-dce.golden.json"

# Minimal required palette keys accepted by SharePoint tenant themes. Keeping
# this list explicit is deliberately boring: if we later add semantic aliases,
# the core tenant-theme contract still cannot silently shrink.
REQUIRED_SHAREPOINT_THEME_KEYS = {
    "themePrimary",
    "themeLighterAlt",
    "themeLighter",
    "themeLight",
    "themeTertiary",
    "themeSecondary",
    "themeDarkAlt",
    "themeDark",
    "themeDarker",
    "neutralLighterAlt",
    "neutralLighter",
    "neutralLight",
    "neutralQuaternaryAlt",
    "neutralQuaternary",
    "neutralTertiaryAlt",
    "neutralTertiary",
    "neutralSecondary",
    "neutralPrimaryAlt",
    "neutralPrimary",
    "neutralDark",
    "black",
    "white",
    "primaryBackground",
    "primaryText",
    "accent",
}

HEX_COLOR = re.compile(r"^#[0-9A-F]{6}$")


def _find_tokens_file() -> Path:
    """Support both DeltaSetup and the seeded dce-sharepoint repo layout."""
    for parent in THIS_FILE.parents:
        candidates = [
            parent / "tokens" / "dce-tokens.json",
            parent / "docs" / "sharepoint-pnp-spec" / "reference" / "dce-tokens.json",
        ]
        for candidate in candidates:
            if candidate.exists():
                return candidate
    raise AssertionError("Could not find canonical dce-tokens.json")


def _token(tokens: dict, *path: str) -> str:
    node = tokens
    for key in path:
        node = node[key]
    value = node["value"]
    assert isinstance(value, str), f"Token {'.'.join(path)} must be a string"
    return value.upper()


def build_sharepoint_theme(tokens: dict) -> dict[str, str]:
    """Deterministic Style-Dictionary-equivalent map for SharePoint themes."""
    brand = tokens["color"]["brand"]
    surface = tokens["color"]["surface"]
    text = tokens["color"]["text"]

    return {
        "themePrimary": _token(tokens, "color", "brand", "teal"),
        "themeLighterAlt": "#F0FDFC",
        "themeLighter": "#C9F5F4",
        "themeLight": "#9FDED8",
        "themeTertiary": brand["teal-light"]["value"].upper(),
        "themeSecondary": brand["teal-on-dark"]["value"].upper(),
        "themeDarkAlt": "#005A50",
        "themeDark": brand["teal-dark"]["value"].upper(),
        "themeDarker": brand["teal-deeper"]["value"].upper(),
        "neutralLighterAlt": "#FAF9F6",
        "neutralLighter": "#F4F1EA",
        "neutralLight": "#E5E0D6",
        "neutralQuaternaryAlt": "#D7D1C4",
        "neutralQuaternary": "#C8C0B0",
        "neutralTertiaryAlt": "#AFA694",
        "neutralTertiary": "#7B725F",
        "neutralSecondary": text["secondary"]["value"].upper(),
        "neutralPrimaryAlt": "#332D24",
        "neutralPrimary": text["default"]["value"].upper(),
        "neutralDark": brand["teal-deeper"]["value"].upper(),
        "black": brand["teal-deeper"]["value"].upper(),
        "white": surface["card"]["value"].upper(),
        "primaryBackground": surface["default"]["value"].upper(),
        "primaryText": text["default"]["value"].upper(),
        "accent": brand["gold"]["value"].upper(),
    }


def test_brand_center_theme_schema_is_complete():
    tokens = json.loads(_find_tokens_file().read_text())
    theme = build_sharepoint_theme(tokens)

    missing = REQUIRED_SHAREPOINT_THEME_KEYS - set(theme)
    extra = set(theme) - REQUIRED_SHAREPOINT_THEME_KEYS

    assert not missing, f"SharePoint theme missing required keys: {sorted(missing)}"
    assert not extra, f"Unexpected theme keys; add intentionally via ADR/test: {sorted(extra)}"

    for key, value in theme.items():
        assert HEX_COLOR.match(value), f"{key} must be canonical #RRGGBB hex, got {value!r}"


def test_brand_center_theme_matches_golden_snapshot():
    tokens = json.loads(_find_tokens_file().read_text())
    actual = build_sharepoint_theme(tokens)
    expected = json.loads(FIXTURE.read_text())

    assert actual == expected


def test_brand_center_theme_round_trips_as_json():
    tokens = json.loads(_find_tokens_file().read_text())
    theme = build_sharepoint_theme(tokens)

    encoded = json.dumps(theme, sort_keys=True, indent=2)
    decoded = json.loads(encoded)

    assert decoded == theme
    assert encoded.endswith("}\n") is False  # json.dumps returns a string only; file writer owns newline policy
