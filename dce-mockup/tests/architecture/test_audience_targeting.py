"""
Fitness functions for the audience-targeting model.

These are NOT unit tests of the mockup's JS — they are architectural
constraints. They enforce decisions from:
  - docs/sharepoint-pnp-spec/02-identity-audience.md
  - solutions-architect-e9372f ADR-006 final (2026-05-16)

Run with: pytest tests/architecture/ -v

Add this folder to the dce-sharepoint repo when it's created. The
patterns are reusable across all brand spokes.
"""

import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
IDENTITY_JS = REPO_ROOT / "js" / "identity.js"
INDEX_HTML = REPO_ROOT / "index.html"
CROWN_HTML = REPO_ROOT / "crown-connection.html"
ADMIN_HTML = REPO_ROOT / "admin.html"

# The locked role taxonomy from 02-identity-audience.md
ROLE_GROUPS = {
    "R1": "Tenant Global Admins",
    "R2": "DCE-Franchisor-Leadership",
    "R3": "DCE-Franchise-Owners",
    "R4": "DCE-Managers",
    "R5": "DCE-AllStaff",
    "R6": "DCE-HTT-Corporate-Sync",   # See RATIONALE.md § 1.3 — name proposed by the mockup
}


# ─────────────────────────────────────────────────────────────────────
# Group taxonomy fitness
# ─────────────────────────────────────────────────────────────────────

class TestGroupTaxonomy:
    """Every audience reference in HTML must resolve to a known group."""

    def _extract_audience_groups(self, html_text: str) -> set[str]:
        groups = set()
        for match in re.finditer(r'data-audience="([^"]+)"', html_text):
            value = match.group(1)
            if value == "*":
                continue
            for g in value.split("|"):
                groups.add(g.strip())
        return groups

    def test_index_audience_groups_in_taxonomy(self):
        text = INDEX_HTML.read_text()
        groups = self._extract_audience_groups(text)
        known = set(ROLE_GROUPS.values()) | {"DCE-Site-Owners", "CrownConnection"}
        unknown = groups - known
        assert not unknown, f"index.html references unknown groups: {unknown}"

    def test_crown_audience_groups_in_taxonomy(self):
        text = CROWN_HTML.read_text()
        groups = self._extract_audience_groups(text)
        known = set(ROLE_GROUPS.values()) | {"DCE-Site-Owners", "CrownConnection"}
        unknown = groups - known
        assert not unknown, f"crown-connection.html references unknown groups: {unknown}"


# ─────────────────────────────────────────────────────────────────────
# Persona / membership fitness
# ─────────────────────────────────────────────────────────────────────

class TestPersonaModel:
    """identity.js must encode the cross-tenant facts correctly."""

    def test_cross_tenant_user_type_is_member(self):
        text = IDENTITY_JS.read_text()
        # The HTT corp persona is the canonical cross-tenant case
        assert "userType: 'Member'" in text, \
            "Cross-tenant synced users must be userType=Member, NOT Guest"

    def test_synced_upn_format(self):
        text = IDENTITY_JS.read_text()
        # The cross-tenant sync UPN follows the documented #EXT# form
        assert "_httbrands.com#EXT#@deltacrown.onmicrosoft.com" in text, \
            "Cross-tenant UPN must follow the <local>_<homedomain>#EXT#@<resourcetenant>.onmicrosoft.com form"

    def test_gate_group_named(self):
        text = IDENTITY_JS.read_text()
        assert "SG-DCE-Sync-Users" in text, \
            "Cross-tenant sync gate group must be referenced"

    def test_owners_not_in_allstaff(self):
        """
        R3 Owners are NOT in DCE-AllStaff (the R5 group). This is what
        keeps the Operations Alerts section hidden from owners on the
        Hub. Regression test for the bug found during initial verification.
        """
        text = IDENTITY_JS.read_text()
        # Find the r3 owner block; confirm it does NOT list DCE_ALLSTAFF
        owner_block = re.search(r"'r3-owner-allynn':\s*\{.*?\}", text, re.DOTALL)
        assert owner_block, "r3-owner-allynn persona missing"
        assert "DCE_ALLSTAFF" not in owner_block.group(0), \
            "R3 Owners must NOT be in DCE-AllStaff per 02-identity-audience.md role taxonomy"


# ─────────────────────────────────────────────────────────────────────
# Group ownership gotcha fitness (solutions-architect-e9372f finding)
# ─────────────────────────────────────────────────────────────────────

class TestGroupOwnershipGotcha:
    """
    SharePoint audience targeting evaluates MEMBERSHIP, not OWNERSHIP.
    Every persona that has a `role` of R1/R2 (typically group owners)
    must also be in the group as a member.
    """

    def test_identity_js_documents_the_gotcha(self):
        text = IDENTITY_JS.read_text()
        assert "MEMBERSHIP, not" in text or "membership, not" in text.lower(), \
            "identity.js must document the Group Owners audience-targeting gotcha"

    def test_global_admin_has_full_membership(self):
        text = IDENTITY_JS.read_text()
        admin_block = re.search(r"'r1-ga-tyler':\s*\{.*?\n    \}", text, re.DOTALL)
        assert admin_block, "r1-ga-tyler persona missing"
        block_text = admin_block.group(0)
        # Tyler should be a Member of all role groups, not just an owner
        for group_const in ["DCE_SITE_OWNERS", "DCE_FRANCHISOR_LEADERSHIP",
                            "DCE_FRANCHISE_OWNERS", "DCE_MANAGERS", "DCE_ALLSTAFF"]:
            assert group_const in block_text, \
                f"R1 GA Tyler must be a MEMBER of {group_const} (not just owner)"


# ─────────────────────────────────────────────────────────────────────
# Teams moderation fitness (ADR-006 final correction)
# ─────────────────────────────────────────────────────────────────────

class TestTeamsModerationBetaOnly:
    """
    channelModerationSettings is BETA-only in Graph as of May 2026.
    Production scripts must target /beta and document the v1.0 monitor.
    """

    def test_provision_teams_uses_beta_endpoint(self):
        script = REPO_ROOT / "ci-cd" / "scripts" / "provision-teams.ps1"
        text = script.read_text()
        # MUST hit /beta, NOT /v1.0
        assert "/beta/teams/" in text, \
            "provision-teams.ps1 must target /beta — channelModerationSettings is beta-only"

    def test_provision_teams_avoids_v1_endpoint(self):
        script = REPO_ROOT / "ci-cd" / "scripts" / "provision-teams.ps1"
        text = script.read_text()
        # The v1.0 endpoint exists but lacks moderation; calling it loses moderation silently
        lines_calling_v1 = [
            line for line in text.splitlines()
            if "/v1.0/teams/" in line and "PATCH" in line.upper() and not line.lstrip().startswith("#")
        ]
        assert not lines_calling_v1, \
            "Do NOT call /v1.0/teams/{id}/channels/{id} for moderation — endpoint silently ignores moderationSettings"

    def test_channel_config_has_beta_warning(self):
        config = REPO_ROOT / "ci-cd" / "teams" / "dce-channels.json"
        text = config.read_text()
        data = json.loads(text)
        meta = data.get("_meta", {})
        beta_keys = [k for k in meta if "BETA" in k]
        assert beta_keys, "dce-channels.json _meta must document the BETA-only constraint"


# ─────────────────────────────────────────────────────────────────────
# Token faithfulness fitness
# ─────────────────────────────────────────────────────────────────────

class TestTokenFaithfulness:
    """No hex colors outside :root token blocks."""

    def test_no_raw_hex_outside_tokens(self):
        css_dir = REPO_ROOT / "css"
        for f in css_dir.glob("*.css"):
            if f.name == "tokens.css":
                continue
            text = f.read_text()
            # Strip comments
            stripped = re.sub(r"/\*[\s\S]*?\*/", "", text)
            raw_hex = re.findall(r"#[0-9A-Fa-f]{3,8}\b", stripped)
            # Exclude rgba(...) / hsla(...) / hsl(...) and url(#…) anchors
            real_hex = [h for h in raw_hex if not re.search(rf"href=.{{0,2}}{re.escape(h)}", stripped)]
            assert not real_hex, f"{f.name}: raw hex found {real_hex}"
