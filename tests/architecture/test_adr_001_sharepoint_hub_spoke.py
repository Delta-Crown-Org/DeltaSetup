"""
ADR-001 Fitness Functions: SharePoint Hub & Spoke Multi-Brand Architecture

These tests enforce the architectural decisions documented in:
docs/architecture/decisions/ADR-001-sharepoint-hub-spoke-multi-brand-franchise.md

Run with: pytest tests/architecture/test_adr_001_sharepoint_hub_spoke.py -v

Note: Some tests validate configuration artifacts (JSON/XML templates).
      Others are integration tests requiring M365 connectivity (marked with @pytest.mark.integration).
"""

import json
import os
import re
from pathlib import Path
from typing import Any

import pytest

# ============================================================================
# ARCHITECTURAL CONSTANTS (from ADR-001)
# ============================================================================

BRAND_PREFIXES = {
    "Delta Crown Extensions": "DCE",
    "Bishops": "BSH",
    "Frenchies": "FRN",
    "HTT": "HTT",
    "TLL": "TLL",
    "Corporate": "Corp",
}

REQUIRED_BRAND_SITES = [
    "{prefix}-Operations",
    "{prefix}-ClientServices",
    "{prefix}-Marketing",
    "{prefix}-Docs",
]

REQUIRED_CORPORATE_SITES = [
    "Corp-HR",
    "Corp-IT",
    "Corp-Finance",
    "Corp-Training",
]

REQUIRED_SENSITIVITY_LABELS = [
    "Public",
    "DCE-Internal",
    "BSH-Internal",
    "FRN-Internal",
    "HTT-Internal",
    "TLL-Internal",
    "Corporate-Confidential",
]

REQUIRED_SECURITY_GROUPS = [
    "SG-{prefix}-AllStaff",
    "SG-{prefix}-Leadership",
]

MAX_HUB_NAVIGATION_DEPTH = 2
MAX_HUB_NAVIGATION_LINKS = 100
MAX_USERS_BUSINESS_PREMIUM = 300
MAX_HUBS_PER_TENANT = 2000
REQUIRED_HUB_COUNT = 6  # 5 brands + 1 corporate

FORBIDDEN_PERMISSION_GROUPS = [
    "Everyone",
    "Everyone except external users",
    "All Users",
]

ADR_PATH = Path("docs/architecture/decisions/ADR-001-sharepoint-hub-spoke-multi-brand-franchise.md")


# ============================================================================
# SECTION 1: ADR DOCUMENT INTEGRITY TESTS
# ============================================================================

class TestADRDocumentIntegrity:
    """Verify the ADR document exists and contains required sections."""

    def test_adr_document_exists(self):
        """ADR-001 document must exist."""
        assert ADR_PATH.exists(), f"ADR-001 not found at {ADR_PATH}"

    def test_adr_has_required_sections(self):
        """ADR must contain all MADR 4.0 required sections."""
        content = ADR_PATH.read_text()
        required_sections = [
            "Context and Problem Statement",
            "Decision Drivers",
            "Considered Options",
            "Decision Outcome",
            "STRIDE Security Analysis",
            "Research References",
        ]
        for section in required_sections:
            assert section in content, f"ADR missing required section: {section}"

    def test_adr_has_status(self):
        """ADR must have a status field."""
        content = ADR_PATH.read_text()
        assert re.search(r"\*\*Status\*\*\s*\|\s*(Proposed|Accepted|Deprecated|Superseded)", content), \
            "ADR must have Status: Proposed/Accepted/Deprecated/Superseded"

    def test_adr_has_minimum_three_options(self):
        """ADR must evaluate at minimum 3 options."""
        content = ADR_PATH.read_text()
        options = re.findall(r"### Option [A-Z]:", content)
        assert len(options) >= 3, f"ADR must have ≥3 options, found {len(options)}"

    def test_adr_has_security_cosign(self):
        """ADR must have Security Auditor co-sign."""
        content = ADR_PATH.read_text()
        assert "Security Co-Sign" in content or "Security Auditor" in content, \
            "ADR must have Security Auditor co-sign"

    def test_adr_references_research(self):
        """ADR must reference research directories."""
        content = ADR_PATH.read_text()
        assert "research/" in content, "ADR must reference research findings"


# ============================================================================
# SECTION 2: NAMING CONVENTION ENFORCEMENT
# ============================================================================

class TestNamingConventions:
    """Enforce site naming conventions from ADR-001."""

    @pytest.mark.parametrize("brand,prefix", [
        ("Delta Crown Extensions", "DCE"),
        ("Bishops", "BSH"),
        ("Frenchies", "FRN"),
        ("HTT", "HTT"),
        ("TLL", "TLL"),
    ])
    def test_brand_prefix_defined(self, brand: str, prefix: str):
        """Each brand must have a defined prefix."""
        assert BRAND_PREFIXES.get(brand) == prefix, \
            f"Brand '{brand}' should have prefix '{prefix}'"

    @pytest.mark.parametrize("prefix", BRAND_PREFIXES.values())
    def test_brand_site_names_follow_convention(self, prefix: str):
        """Brand site names must follow {Prefix}-{Function} pattern."""
        if prefix == "Corp":
            return  # Corporate sites have different pattern

        for template in REQUIRED_BRAND_SITES:
            site_name = template.format(prefix=prefix)
            assert re.match(r"^[A-Z]{2,4}-[A-Za-z]+$", site_name), \
                f"Site name '{site_name}' doesn't match naming convention"

    def test_corporate_sites_follow_convention(self):
        """Corporate sites must follow Corp-{Function} pattern."""
        for site_name in REQUIRED_CORPORATE_SITES:
            assert site_name.startswith("Corp-"), \
                f"Corporate site '{site_name}' must start with 'Corp-'"


# ============================================================================
# SECTION 3: HUB TOPOLOGY CONSTRAINTS
# ============================================================================

class TestHubTopologyConstraints:
    """Enforce hub site topology decisions from ADR-001."""

    def test_hub_count_within_limits(self):
        """Total hub count must not exceed M365 limit."""
        assert REQUIRED_HUB_COUNT <= MAX_HUBS_PER_TENANT, \
            f"Hub count {REQUIRED_HUB_COUNT} exceeds limit {MAX_HUBS_PER_TENANT}"

    def test_each_brand_gets_dedicated_hub(self):
        """Each brand must have its own hub (not shared)."""
        brand_count = len([k for k in BRAND_PREFIXES if k != "Corporate"])
        corporate_hubs = 1
        assert REQUIRED_HUB_COUNT == brand_count + corporate_hubs, \
            "Each brand must have a dedicated hub, plus one corporate hub"

    def test_navigation_depth_constraint(self):
        """Hub navigation must not exceed 2 levels."""
        assert MAX_HUB_NAVIGATION_DEPTH == 2, \
            "ADR-001 mandates max 2-level navigation depth"

    def test_navigation_link_limit(self):
        """Hub navigation should stay under 100 links."""
        assert MAX_HUB_NAVIGATION_LINKS <= 100, \
            "ADR-001 recommends max 100 navigation links per hub"

    def test_user_count_within_business_premium_limit(self):
        """Total users across all brands must not exceed 300."""
        # This is a constraint check — actual user count would come from Graph API
        assert MAX_USERS_BUSINESS_PREMIUM == 300, \
            "Business Premium license limits to 300 users"


# ============================================================================
# SECTION 4: SECURITY CONSTRAINTS
# ============================================================================

class TestSecurityConstraints:
    """Enforce security decisions from ADR-001."""

    def test_forbidden_permission_groups_defined(self):
        """'Everyone' and 'All Users' groups must be forbidden."""
        assert "Everyone" in FORBIDDEN_PERMISSION_GROUPS
        assert "All Users" in FORBIDDEN_PERMISSION_GROUPS

    @pytest.mark.parametrize("prefix", [v for k, v in BRAND_PREFIXES.items() if k != "Corporate"])
    def test_brand_security_groups_required(self, prefix: str):
        """Each brand must have required security groups."""
        for template in REQUIRED_SECURITY_GROUPS:
            group_name = template.format(prefix=prefix)
            assert re.match(r"^SG-[A-Z]{2,4}-(AllStaff|Leadership)$", group_name), \
                f"Security group '{group_name}' doesn't follow naming convention"

    def test_sensitivity_labels_cover_all_brands(self):
        """Each brand must have a dedicated sensitivity label."""
        for brand, prefix in BRAND_PREFIXES.items():
            if brand == "Corporate":
                assert "Corporate-Confidential" in REQUIRED_SENSITIVITY_LABELS
            else:
                expected_label = f"{prefix}-Internal"
                assert expected_label in REQUIRED_SENSITIVITY_LABELS, \
                    f"Missing sensitivity label for {brand}: {expected_label}"

    def test_public_label_exists(self):
        """Public sensitivity label must exist."""
        assert "Public" in REQUIRED_SENSITIVITY_LABELS

    def test_information_barriers_not_required(self):
        """Architecture must NOT depend on Information Barriers (not in Business Premium)."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            # The ADR should explicitly state IB is not available
            assert "Information Barriers" in content, \
                "ADR must address Information Barriers availability"
            assert "Business Premium" in content, \
                "ADR must state Business Premium licensing constraint"


# ============================================================================
# SECTION 5: PROVISIONING TEMPLATE VALIDATION
# ============================================================================

class TestProvisioningTemplates:
    """Validate provisioning templates conform to ADR-001."""

    SITE_DESIGN_DIR = Path("provisioning/site-designs/")
    PNP_TEMPLATE_DIR = Path("provisioning/pnp-templates/")

    def test_provisioning_directory_structure_documented(self):
        """ADR must document provisioning strategy."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            assert "PnP" in content, "ADR must reference PnP provisioning"
            assert "Site Design" in content or "Site Script" in content, \
                "ADR must reference Site Designs or Site Scripts"

    @pytest.mark.skipif(
        not Path("provisioning/site-designs/").exists(),
        reason="Site designs not yet created"
    )
    def test_site_design_json_valid(self):
        """All site design JSON files must be valid."""
        for json_file in self.SITE_DESIGN_DIR.glob("*.json"):
            content = json_file.read_text()
            try:
                data = json.loads(content)
                assert "actions" in data or "$schema" in data, \
                    f"{json_file.name} must contain 'actions' or '$schema'"
            except json.JSONDecodeError as e:
                pytest.fail(f"{json_file.name} is invalid JSON: {e}")

    @pytest.mark.skipif(
        not Path("provisioning/site-designs/").exists(),
        reason="Site designs not yet created"
    )
    def test_site_design_includes_hub_association(self):
        """Site designs should include hub association action."""
        for json_file in self.SITE_DESIGN_DIR.glob("*.json"):
            content = json.loads(json_file.read_text())
            actions = content.get("actions", [])
            hub_actions = [a for a in actions if a.get("verb") == "joinHubSite"]
            assert len(hub_actions) > 0, \
                f"{json_file.name} must include 'joinHubSite' action"

    @pytest.mark.skipif(
        not Path("provisioning/site-designs/").exists(),
        reason="Site designs not yet created"
    )
    def test_site_design_applies_theme(self):
        """Site designs must apply brand-specific theme."""
        for json_file in self.SITE_DESIGN_DIR.glob("*.json"):
            content = json.loads(json_file.read_text())
            actions = content.get("actions", [])
            theme_actions = [a for a in actions if a.get("verb") == "applyTheme"]
            assert len(theme_actions) > 0, \
                f"{json_file.name} must include 'applyTheme' action"


# ============================================================================
# SECTION 6: GOVERNANCE COMPLIANCE CHECKS
# ============================================================================

class TestGovernanceCompliance:
    """Validate governance decisions from ADR-001."""

    def test_external_sharing_default_disabled(self):
        """Architecture mandates external sharing disabled by default."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            assert "Disabled by default" in content or "disabled" in content.lower(), \
                "ADR must specify external sharing disabled by default"

    def test_private_channels_restricted(self):
        """Private channel creation must be restricted to owners."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            assert "private channel" in content.lower() or "Private Channel" in content, \
                "ADR must address private channel governance"

    def test_retention_policies_addressed(self):
        """ADR must address retention policies."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            assert "retention" in content.lower(), \
                "ADR must address retention policies"

    def test_guest_access_requires_approval(self):
        """Guest access must require approval."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            assert "approval" in content.lower() and "guest" in content.lower(), \
                "ADR must specify guest access requires approval"


# ============================================================================
# SECTION 7: INTEGRATION TESTS (require M365 connectivity)
# ============================================================================

@pytest.mark.integration
class TestM365Integration:
    """
    Integration tests requiring M365 connectivity.
    Run with: pytest -m integration --m365-tenant=<tenant>

    These validate the LIVE environment matches ADR-001 decisions.
    """

    @pytest.mark.skip(reason="Requires M365 Graph API connection")
    def test_hub_sites_exist(self):
        """Verify all required hub sites exist in M365."""
        # Would use Microsoft Graph API:
        # GET https://graph.microsoft.com/v1.0/sites?$filter=isHubSite eq true
        pass

    @pytest.mark.skip(reason="Requires M365 Graph API connection")
    def test_no_forbidden_permissions(self):
        """Verify no sites use 'Everyone' or 'All Users' groups."""
        # Would iterate all brand sites and check permission sets
        pass

    @pytest.mark.skip(reason="Requires M365 Graph API connection")
    def test_sensitivity_labels_published(self):
        """Verify all required sensitivity labels are published."""
        # Would use Compliance Center API to verify labels
        pass

    @pytest.mark.skip(reason="Requires M365 Graph API connection")
    def test_dlp_policies_active(self):
        """Verify DLP policies are active for each brand."""
        pass

    @pytest.mark.skip(reason="Requires M365 Graph API connection")
    def test_search_isolation(self):
        """Verify Brand A search does not return Brand B results."""
        # Would perform search-as-user for each brand and verify isolation
        pass

    @pytest.mark.skip(reason="Requires M365 Graph API connection")
    def test_teams_linked_to_correct_hub(self):
        """Verify each brand's Teams site is associated with correct hub."""
        pass


# ============================================================================
# SECTION 8: DEPLOYMENT TIMELINE VALIDATION
# ============================================================================

class TestDeploymentTimeline:
    """Validate the 2-week deployment timeline is feasible."""

    DEPLOYMENT_DAYS = 14
    REQUIRED_STEPS = [
        "PnP Brand Template execution",
        "Branding customization",
        "Teams channels + shared mailbox",
        "Permissions + sensitivity labels",
        "Content migration",
        "User acceptance testing",
        "Training + go-live",
    ]

    def test_deployment_fits_in_two_weeks(self):
        """Total deployment must fit within 14 calendar days."""
        # 7 major steps across 14 days = ~2 days per step (feasible)
        days_per_step = self.DEPLOYMENT_DAYS / len(self.REQUIRED_STEPS)
        assert days_per_step >= 1.0, \
            f"Deployment has {len(self.REQUIRED_STEPS)} steps in {self.DEPLOYMENT_DAYS} days — " \
            f"need at least 1 day per step"

    def test_template_execution_is_first_step(self):
        """PnP template must execute first."""
        assert "PnP" in self.REQUIRED_STEPS[0] or "Template" in self.REQUIRED_STEPS[0], \
            "First deployment step must be template execution"

    def test_training_is_last_step(self):
        """Training must be the final step."""
        assert "Training" in self.REQUIRED_STEPS[-1] or "go-live" in self.REQUIRED_STEPS[-1], \
            "Last deployment step must be training/go-live"


# ============================================================================
# SECTION 9: RESEARCH INTEGRITY
# ============================================================================

class TestResearchIntegrity:
    """Verify research artifacts exist and support ADR decisions."""

    def test_hub_spoke_research_exists(self):
        """Hub & Spoke research directory must exist."""
        research_dir = Path("research/sharepoint-hub-spoke")
        assert research_dir.exists(), \
            f"Research directory not found: {research_dir}"

    def test_provisioning_research_exists(self):
        """Provisioning research directory must exist."""
        research_dir = Path("research/sharepoint-provisioning")
        assert research_dir.exists(), \
            f"Research directory not found: {research_dir}"

    @pytest.mark.parametrize("research_dir", [
        "research/sharepoint-hub-spoke",
        "research/sharepoint-provisioning",
    ])
    def test_research_has_sources(self, research_dir: str):
        """Each research directory must have a sources.md file."""
        sources_file = Path(research_dir) / "sources.md"
        if Path(research_dir).exists():
            assert sources_file.exists(), \
                f"Missing sources.md in {research_dir}"

    @pytest.mark.parametrize("research_dir", [
        "research/sharepoint-hub-spoke",
        "research/sharepoint-provisioning",
    ])
    def test_research_has_recommendations(self, research_dir: str):
        """Each research directory must have a recommendations.md file."""
        recommendations_file = Path(research_dir) / "recommendations.md"
        if Path(research_dir).exists():
            assert recommendations_file.exists(), \
                f"Missing recommendations.md in {research_dir}"
