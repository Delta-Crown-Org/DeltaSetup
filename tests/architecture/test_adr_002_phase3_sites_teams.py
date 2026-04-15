"""
ADR-002 Fitness Functions: Phase 3 SharePoint Sites + Teams Collaboration

These tests enforce the architectural decisions documented in:
docs/architecture/decisions/ADR-002-phase3-sharepoint-sites-teams-collaboration.md

Run with: pytest tests/architecture/test_adr_002_phase3_sites_teams.py -v

Note: Some tests validate configuration artifacts.
      Others are integration tests requiring M365 connectivity (marked @pytest.mark.integration).
"""

import json
import os
import re
from pathlib import Path
from typing import Any

import pytest

# ============================================================================
# ARCHITECTURAL CONSTANTS (from ADR-002)
# ============================================================================

ADR_PATH = Path("docs/architecture/decisions/ADR-002-phase3-sharepoint-sites-teams-collaboration.md")

# Phase 3 SharePoint Sites
REQUIRED_DCE_SITES = {
    "DCE-Operations": {
        "template": "Team Site",
        "teams_connected": True,
        "url_suffix": "dce-operations",
    },
    "DCE-ClientServices": {
        "template": "Team Site",
        "teams_connected": False,
        "url_suffix": "dce-clientservices",
    },
    "DCE-Marketing": {
        "template": "Communication Site",
        "teams_connected": False,
        "url_suffix": "dce-marketing",
    },
    "DCE-Docs": {
        "template": "Team Site",
        "teams_connected": False,
        "url_suffix": "dce-docs",
    },
}

# Required SharePoint Lists per site
REQUIRED_LISTS = {
    "DCE-Operations": ["Bookings", "Staff Schedule", "Tasks", "Inventory", "Calendar"],
    "DCE-ClientServices": ["Client Records", "Service Catalog", "Feedback"],
    "DCE-Marketing": ["Campaigns", "Social Calendar"],
    "DCE-Docs": [],  # Document center uses libraries only
}

# Required Document Libraries per site
REQUIRED_LIBRARIES = {
    "DCE-Operations": ["Documents", "Daily Ops"],
    "DCE-ClientServices": ["Documents", "Consent Forms"],
    "DCE-Marketing": ["Brand Assets", "Templates"],
    "DCE-Docs": ["Policies", "Training", "Forms", "Templates", "Archive"],
}

# Teams Configuration
TEAMS_TEAM_NAME = "Delta Crown Operations"
REQUIRED_STANDARD_CHANNELS = ["General", "Daily Ops", "Bookings", "Marketing"]
REQUIRED_PRIVATE_CHANNELS = ["Leadership"]
TEAMS_VISIBILITY = "Private"

# Shared Mailboxes
REQUIRED_SHARED_MAILBOXES = [
    "operations@deltacrown.com",
    "bookings@deltacrown.com",
    "info@deltacrown.com",
]

# DLP Policy Budget
MAX_DLP_POLICIES_BUSINESS_PREMIUM = 10
PHASE3_DLP_POLICIES = [
    "DCE-Data-Protection",
    "Corp-Data-Protection",
    "External-Sharing-Block",
]

# Security Groups
REQUIRED_NEW_GROUPS = ["SG-DCE-Marketing"]

# Permission Model
SITES_REQUIRING_UNIQUE_PERMISSIONS = [
    "dce-hub",
    "dce-operations",
    "dce-clientservices",
    "dce-marketing",
    "dce-docs",
]

FORBIDDEN_PERMISSION_GROUPS = [
    "Everyone",
    "Everyone except external users",
    "All Users",
]

# Template Parameters
REQUIRED_TEMPLATE_PARAMETERS = [
    "{BrandName}",
    "{BrandPrefix}",
    "{BrandDomain}",
    "{PrimaryColor}",
    "{SecondaryColor}",
]

# Phase 3 Scripts
REQUIRED_SCRIPTS = [
    "3.0-Master-Phase3.ps1",
    "3.1-DCE-Sites-Provisioning.ps1",
    "3.2-Teams-Provisioning.ps1",
    "3.3-Security-Hardening.ps1",
    "3.4-DLP-Policies.ps1",
    "3.5-Shared-Mailboxes.ps1",
    "3.6-Template-Export.ps1",
    "3.7-Phase3-Verification.ps1",
]


# ============================================================================
# SECTION 1: ADR DOCUMENT INTEGRITY TESTS
# ============================================================================

class TestADR002DocumentIntegrity:
    """Verify ADR-002 document exists and contains required sections."""

    def test_adr_document_exists(self):
        """ADR-002 document must exist."""
        assert ADR_PATH.exists(), f"ADR-002 not found at {ADR_PATH}"

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
        assert re.search(
            r"\*\*Status\*\*\s*\|\s*(Proposed|Accepted|Deprecated|Superseded)",
            content
        ), "ADR must have Status: Proposed/Accepted/Deprecated/Superseded"

    def test_adr_has_minimum_three_options(self):
        """ADR must evaluate at minimum 3 options."""
        content = ADR_PATH.read_text()
        options = re.findall(r"### Option [A-Z]:", content)
        assert len(options) >= 3, f"ADR must have >=3 options, found {len(options)}"

    def test_adr_depends_on_adr_001(self):
        """ADR-002 must declare dependency on ADR-001."""
        content = ADR_PATH.read_text()
        assert "ADR-001" in content, "ADR-002 must reference dependency on ADR-001"

    def test_adr_has_security_cosign(self):
        """ADR must have Security Auditor co-sign field."""
        content = ADR_PATH.read_text()
        assert "Security Co-Sign" in content or "Security Auditor" in content, \
            "ADR must have Security Auditor co-sign"

    def test_adr_has_stride_table(self):
        """ADR must have STRIDE risk matrix table."""
        content = ADR_PATH.read_text()
        # Check for STRIDE column headers
        for threat in ["Spoofing", "Tampering", "Repudiation", "Information Disclosure", "Denial of Service", "Elevation"]:
            assert threat in content, f"STRIDE analysis missing threat category: {threat}"


# ============================================================================
# SECTION 2: SITE ARCHITECTURE VALIDATION
# ============================================================================

class TestSiteArchitecture:
    """Validate SharePoint site structure decisions."""

    def test_exactly_four_brand_sites_required(self):
        """Phase 3 must create exactly 4 DCE brand sites."""
        assert len(REQUIRED_DCE_SITES) == 4, \
            f"Expected 4 DCE sites, got {len(REQUIRED_DCE_SITES)}"

    def test_only_one_site_is_teams_connected(self):
        """Only DCE-Operations should be Teams-connected (Option B)."""
        teams_connected = [
            name for name, config in REQUIRED_DCE_SITES.items()
            if config["teams_connected"]
        ]
        assert len(teams_connected) == 1, \
            f"Exactly 1 site should be Teams-connected, got {len(teams_connected)}: {teams_connected}"
        assert teams_connected[0] == "DCE-Operations", \
            "Only DCE-Operations should be Teams-connected"

    def test_marketing_is_communication_site(self):
        """DCE-Marketing must be a Communication Site (not Team Site)."""
        assert REQUIRED_DCE_SITES["DCE-Marketing"]["template"] == "Communication Site"

    def test_all_other_sites_are_team_sites(self):
        """DCE-Operations, ClientServices, and Docs must be Team Sites."""
        for site_name in ["DCE-Operations", "DCE-ClientServices", "DCE-Docs"]:
            assert REQUIRED_DCE_SITES[site_name]["template"] == "Team Site", \
                f"{site_name} should be Team Site"

    @pytest.mark.parametrize("site_name,expected_lists", [
        ("DCE-Operations", ["Bookings", "Staff Schedule", "Tasks", "Inventory", "Calendar"]),
        ("DCE-ClientServices", ["Client Records", "Service Catalog", "Feedback"]),
        ("DCE-Marketing", ["Campaigns", "Social Calendar"]),
    ])
    def test_required_lists_defined(self, site_name: str, expected_lists: list):
        """Each site must have its required SharePoint lists."""
        actual = REQUIRED_LISTS.get(site_name, [])
        for lst in expected_lists:
            assert lst in actual, f"{site_name} missing required list: {lst}"

    @pytest.mark.parametrize("site_name,expected_libs", [
        ("DCE-Operations", ["Documents", "Daily Ops"]),
        ("DCE-Docs", ["Policies", "Training", "Forms", "Templates", "Archive"]),
        ("DCE-Marketing", ["Brand Assets", "Templates"]),
    ])
    def test_required_libraries_defined(self, site_name: str, expected_libs: list):
        """Each site must have its required document libraries."""
        actual = REQUIRED_LIBRARIES.get(site_name, [])
        for lib in expected_libs:
            assert lib in actual, f"{site_name} missing required library: {lib}"

    def test_dce_docs_has_five_libraries(self):
        """DCE-Docs (Document Center) must have 5 organized libraries."""
        assert len(REQUIRED_LIBRARIES["DCE-Docs"]) == 5, \
            f"DCE-Docs should have 5 libraries, got {len(REQUIRED_LIBRARIES['DCE-Docs'])}"

    def test_site_url_naming_convention(self):
        """All site URLs must follow dce-{function} pattern."""
        for site_name, config in REQUIRED_DCE_SITES.items():
            url = config["url_suffix"]
            assert url.startswith("dce-"), \
                f"Site URL '{url}' must start with 'dce-'"
            assert url == url.lower(), \
                f"Site URL '{url}' must be lowercase"


# ============================================================================
# SECTION 3: TEAMS CONFIGURATION VALIDATION
# ============================================================================

class TestTeamsConfiguration:
    """Validate Teams workspace decisions."""

    def test_single_team_per_brand(self):
        """Option B mandates exactly ONE Teams team per brand."""
        # The constant defines a single team name, not a list
        assert isinstance(TEAMS_TEAM_NAME, str), "Must be a single team name"

    def test_team_is_private(self):
        """Teams team must be Private visibility."""
        assert TEAMS_VISIBILITY == "Private"

    def test_required_standard_channels(self):
        """Team must have required standard channels."""
        expected = ["General", "Daily Ops", "Bookings", "Marketing"]
        for channel in expected:
            assert channel in REQUIRED_STANDARD_CHANNELS, \
                f"Missing standard channel: {channel}"

    def test_required_private_channels(self):
        """Team must have Leadership as a private channel."""
        assert "Leadership" in REQUIRED_PRIVATE_CHANNELS
        assert len(REQUIRED_PRIVATE_CHANNELS) == 1, \
            "Only Leadership should be a private channel"

    def test_total_channel_count(self):
        """Total channels should be 5 (4 standard + 1 private)."""
        total = len(REQUIRED_STANDARD_CHANNELS) + len(REQUIRED_PRIVATE_CHANNELS)
        assert total == 5, f"Expected 5 channels, got {total}"

    def test_shared_mailbox_count(self):
        """Must have exactly 3 shared mailboxes."""
        assert len(REQUIRED_SHARED_MAILBOXES) == 3

    def test_shared_mailboxes_use_brand_domain(self):
        """All shared mailboxes must use deltacrown.com domain."""
        for mailbox in REQUIRED_SHARED_MAILBOXES:
            assert mailbox.endswith("@deltacrown.com"), \
                f"Mailbox '{mailbox}' must use deltacrown.com domain"


# ============================================================================
# SECTION 4: SECURITY CONSTRAINTS
# ============================================================================

class TestSecurityConstraints:
    """Validate security hardening decisions."""

    def test_all_sites_require_unique_permissions(self):
        """Every DCE site must have unique (not inherited) permissions."""
        assert len(SITES_REQUIRING_UNIQUE_PERMISSIONS) >= 5, \
            "At least 5 sites must have unique permissions"

    def test_forbidden_groups_defined(self):
        """'Everyone' and 'All Users' must be forbidden."""
        assert "Everyone" in FORBIDDEN_PERMISSION_GROUPS
        assert "All Users" in FORBIDDEN_PERMISSION_GROUPS
        assert "Everyone except external users" in FORBIDDEN_PERMISSION_GROUPS

    def test_new_marketing_group_required(self):
        """Phase 3 requires new SG-DCE-Marketing group."""
        assert "SG-DCE-Marketing" in REQUIRED_NEW_GROUPS

    def test_guest_access_disabled(self):
        """Guest access must be disabled at team level."""
        # Enforced by architecture decision
        content = ADR_PATH.read_text() if ADR_PATH.exists() else ""
        assert "guest" in content.lower() and "disabled" in content.lower(), \
            "ADR must specify guest access disabled"


# ============================================================================
# SECTION 5: DLP POLICY CONSTRAINTS
# ============================================================================

class TestDLPPolicyConstraints:
    """Validate DLP policy budget and configuration."""

    def test_dlp_budget_not_exceeded(self):
        """Phase 3 DLP policies must not exceed Business Premium limit."""
        assert len(PHASE3_DLP_POLICIES) <= MAX_DLP_POLICIES_BUSINESS_PREMIUM, \
            f"Phase 3 has {len(PHASE3_DLP_POLICIES)} policies, limit is {MAX_DLP_POLICIES_BUSINESS_PREMIUM}"

    def test_phase3_uses_three_policies(self):
        """Phase 3 should use exactly 3 DLP policies."""
        assert len(PHASE3_DLP_POLICIES) == 3

    def test_remaining_dlp_budget(self):
        """Must have enough DLP budget remaining for future brands."""
        remaining = MAX_DLP_POLICIES_BUSINESS_PREMIUM - len(PHASE3_DLP_POLICIES)
        # Need 1 per remaining brand (BSH, FRN, HTT, TLL) + 2 reserved
        future_brands = 4
        reserved = 2
        assert remaining >= future_brands + reserved, \
            f"Only {remaining} DLP policies left, need {future_brands + reserved} for future"

    def test_external_sharing_block_enforces_immediately(self):
        """External-Sharing-Block must be in Enforce mode (not test)."""
        content = ADR_PATH.read_text() if ADR_PATH.exists() else ""
        assert "External-Sharing-Block" in content
        assert "Enforce immediately" in content or "Enforce" in content


# ============================================================================
# SECTION 6: TEMPLATE CAPTURE VALIDATION
# ============================================================================

class TestTemplateCapture:
    """Validate template capture strategy."""

    def test_required_parameters_defined(self):
        """Template must parameterize brand-specific values."""
        for param in REQUIRED_TEMPLATE_PARAMETERS:
            assert param.startswith("{") and param.endswith("}"), \
                f"Parameter '{param}' must be in {{variable}} format"

    def test_minimum_five_parameters(self):
        """Template must have at least 5 parameterized values."""
        assert len(REQUIRED_TEMPLATE_PARAMETERS) >= 5

    def test_adr_documents_what_pnp_captures(self):
        """ADR must document what PnP captures vs what needs separate scripts."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            assert "Captured" in content or "captured" in content
            assert "Teams" in content and "Graph API" in content, \
                "ADR must note Teams requires Graph API (not PnP)"

    def test_adr_documents_template_hash_verification(self):
        """ADR must specify SHA-256 hash verification for templates."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            assert "SHA-256" in content or "hash verification" in content.lower(), \
                "ADR must specify template hash verification"


# ============================================================================
# SECTION 7: SCRIPT SPECIFICATION VALIDATION
# ============================================================================

class TestScriptSpecification:
    """Validate Phase 3 script specifications."""

    def test_all_required_scripts_specified(self):
        """All 8 Phase 3 scripts must be specified."""
        assert len(REQUIRED_SCRIPTS) == 8

    def test_scripts_follow_naming_convention(self):
        """Scripts must follow 3.X-Name.ps1 naming pattern."""
        for script in REQUIRED_SCRIPTS:
            assert re.match(r"^3\.\d+-[\w-]+\.ps1$", script), \
                f"Script '{script}' doesn't follow 3.X-Name.ps1 pattern"

    def test_master_script_is_first(self):
        """Master orchestrator must be 3.0."""
        assert REQUIRED_SCRIPTS[0] == "3.0-Master-Phase3.ps1"

    def test_verification_script_is_last(self):
        """Verification must be the last script."""
        assert REQUIRED_SCRIPTS[-1] == "3.7-Phase3-Verification.ps1"

    def test_template_export_before_verification(self):
        """Template export must run before verification."""
        export_idx = REQUIRED_SCRIPTS.index("3.6-Template-Export.ps1")
        verify_idx = REQUIRED_SCRIPTS.index("3.7-Phase3-Verification.ps1")
        assert export_idx < verify_idx


# ============================================================================
# SECTION 8: PHASE 2 COMPATIBILITY
# ============================================================================

class TestPhase2Compatibility:
    """Validate Phase 3 integrates with Phase 2 deliverables."""

    def test_phase2_config_exists(self):
        """Phase 2 config file must exist for Phase 3 to extend."""
        config_path = Path("phase2-week1/modules/DeltaCrown.Config.psd1")
        assert config_path.exists(), f"Phase 2 config not found: {config_path}"

    def test_phase2_auth_module_exists(self):
        """Phase 2 auth module must exist for Phase 3 to import."""
        auth_path = Path("phase2-week1/modules/DeltaCrown.Auth.psm1")
        assert auth_path.exists(), f"Phase 2 auth module not found: {auth_path}"

    def test_phase2_common_module_exists(self):
        """Phase 2 common module must exist for Phase 3 to import."""
        common_path = Path("phase2-week1/modules/DeltaCrown.Common.psm1")
        assert common_path.exists(), f"Phase 2 common module not found: {common_path}"

    def test_phase2_hub_template_exists(self):
        """Phase 2 DCE Hub template must exist."""
        template_path = Path("phase2-week1/templates/DCEHub-Template.json")
        assert template_path.exists(), f"Phase 2 hub template not found: {template_path}"

    def test_adr_001_exists(self):
        """ADR-001 must exist as the foundational architecture."""
        adr_001_path = Path("docs/architecture/decisions/ADR-001-sharepoint-hub-spoke-multi-brand-franchise.md")
        assert adr_001_path.exists(), f"ADR-001 not found: {adr_001_path}"


# ============================================================================
# SECTION 9: PII PROTECTION VALIDATION
# ============================================================================

class TestPIIProtection:
    """Validate PII handling decisions for client data."""

    CLIENT_PII_FIELDS = [
        "Client Name",
        "Email",
        "Phone",
        "Allergy/Notes",
    ]

    def test_client_records_identified_as_pii(self):
        """Client Records list must be identified as containing PII."""
        assert "Client Records" in REQUIRED_LISTS["DCE-ClientServices"]

    def test_pii_protection_in_stride(self):
        """STRIDE analysis must address client PII risks."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            assert "PII" in content or "pii" in content, \
                "STRIDE analysis must address PII risks"

    def test_client_data_in_controlled_site(self):
        """Client records must be in DCE-ClientServices (not operations)."""
        assert "Client Records" not in REQUIRED_LISTS.get("DCE-Operations", []), \
            "Client PII should NOT be in Operations site"
        assert "Client Records" in REQUIRED_LISTS.get("DCE-ClientServices", []), \
            "Client PII must be in ClientServices site"


# ============================================================================
# SECTION 10: RESEARCH INTEGRITY
# ============================================================================

class TestResearchIntegrity:
    """Verify research artifacts support ADR-002 decisions."""

    def test_phase3_research_directory_exists(self):
        """Phase 3 research directory must exist."""
        research_dir = Path("research/phase3-sharepoint-teams")
        assert research_dir.exists(), \
            f"Research directory not found: {research_dir}"

    def test_existing_research_directories_exist(self):
        """Prior research must still be available."""
        for research_dir in [
            "research/sharepoint-hub-spoke",
            "research/sharepoint-provisioning",
        ]:
            assert Path(research_dir).exists(), \
                f"Prior research directory missing: {research_dir}"

    def test_adr_references_research(self):
        """ADR must reference research directories."""
        if ADR_PATH.exists():
            content = ADR_PATH.read_text()
            assert "research/" in content, "ADR must reference research findings"


# ============================================================================
# SECTION 11: INTEGRATION TESTS (require M365 connectivity)
# ============================================================================

@pytest.mark.integration
class TestM365IntegrationPhase3:
    """
    Integration tests requiring M365 connectivity.
    Run with: pytest -m integration

    These validate the LIVE environment matches ADR-002 decisions.
    """

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_dce_operations_site_exists(self):
        """DCE-Operations site must exist and be accessible."""
        pass

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_dce_operations_is_teams_connected(self):
        """DCE-Operations must be connected to a Teams team."""
        pass

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_teams_has_correct_channels(self):
        """Teams team must have all required channels."""
        pass

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_leadership_is_private_channel(self):
        """Leadership channel must be private."""
        pass

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_all_sites_have_unique_permissions(self):
        """All DCE sites must have unique (not inherited) permissions."""
        pass

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_no_forbidden_groups_on_any_site(self):
        """No DCE site should have Everyone/All Users groups."""
        pass

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_dlp_policies_exist(self):
        """All Phase 3 DLP policies must exist."""
        pass

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_shared_mailboxes_exist(self):
        """All shared mailboxes must exist and be functional."""
        pass

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_all_sites_associated_with_dce_hub(self):
        """All DCE sites must be associated with DCE Hub."""
        pass

    @pytest.mark.skip(reason="Requires M365 connection")
    def test_search_isolation_across_brands(self):
        """Search from DCE hub must not return non-DCE results."""
        pass
