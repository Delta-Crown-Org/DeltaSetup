"""
ADR-004 Fitness Functions: Cross-Tenant Collaboration and SharePoint Access Overlay

These tests enforce the architectural decisions documented in:
docs/architecture/decisions/ADR-004-cross-tenant-collaboration-sharepoint-access.md

Run with: pytest tests/architecture/test_adr_004_cross_tenant_access.py -v

These are documentation fitness functions. They validate that the ADR keeps
critical anti-patterns, sequencing rules, and collaboration-pattern guidance
explicit in the repository.
"""

import re
from pathlib import Path

ADR_PATH = Path(
    "docs/architecture/decisions/ADR-004-cross-tenant-collaboration-sharepoint-access.md"
)

REQUIRED_SECTIONS = [
    "Context and Problem Statement",
    "Decision Drivers",
    "Considered Options",
    "Decision Outcome",
    "STRIDE Security Analysis",
    "Research References",
]

REQUIRED_DEPENDENCIES = ["ADR-001", "ADR-002"]

REQUIRED_PATTERNS = [
    "single-tenant baseline",
    "cross-tenant collaboration overlay",
    "B2B collaboration guests",
    "Cross-Tenant Sync",
    "B2B Direct Connect",
    "Layer 1 — Admission",
    "Layer 2 — Authorization",
]

REQUIRED_ANTI_PATTERN_TEXT = [
    "Scoping inbound B2B collaboration `usersAndGroups` to dynamic groups in the resource tenant",
    "resource-tenant dynamic groups",
    "AADSTS500213",
]

REQUIRED_ORDER_OF_OPERATIONS = [
    "add partner organization",
    "configure inbound B2B collaboration",
    "enable bilateral automatic redemption",
    "enable cross-tenant sync prerequisites",
    "decide `userType` and attribute mappings before production onboarding",
    "onboard pilot users first",
    "verify target object creation",
    "verify dynamic-group resolution at the authorization layer",
]

REQUIRED_DIRECT_CONNECT_LIMITS = [
    "Teams shared-channel",
    "not the standard mechanism for normal SharePoint site access",
    "Do Not Use B2B Direct Connect As",
    "default SharePoint portal strategy",
]

REQUIRED_GUEST_VS_SYNC_GUIDANCE = [
    "Use B2B Collaboration Guests When",
    "Use Cross-Tenant Sync When",
    "invitation churn is too costly",
    "guest lifecycle management is acceptable",
]

REQUIRED_GUARDRAILS = [
    "Default to Single-Tenant Unless There Is a Real Cross-Tenant Requirement",
    "Separate Admission From Authorization",
    "Keep Dynamic Groups at the Authorization Layer",
    "Treat Attribute Mapping as Architecture, Not Plumbing",
    "Pilot Before Broad Rollout",
]

STRIDE_THREATS = [
    "Spoofing",
    "Tampering",
    "Repudiation",
    "Information Disclosure",
    "Denial of Service",
    "Elevation of Privilege",
]


def _read_adr() -> str:
    return ADR_PATH.read_text()


class TestADR004DocumentIntegrity:
    """Verify ADR-004 exists and follows repository ADR norms."""

    def test_adr_document_exists(self):
        assert ADR_PATH.exists(), f"ADR-004 not found at {ADR_PATH}"

    def test_adr_has_required_sections(self):
        content = _read_adr()
        for section in REQUIRED_SECTIONS:
            assert section in content, f"ADR-004 missing required section: {section}"

    def test_adr_has_status_field(self):
        content = _read_adr()
        assert re.search(
            r"\*\*Status\*\*\s*\|\s*(Proposed|Accepted|Deprecated|Superseded)",
            content,
        ), "ADR-004 must have a valid status field"

    def test_adr_has_minimum_three_options(self):
        content = _read_adr()
        options = re.findall(r"### Option [A-Z]:", content)
        assert len(options) >= 3, f"ADR-004 must have >=3 options, found {len(options)}"

    def test_adr_declares_dependencies_on_prior_adrs(self):
        content = _read_adr()
        for dependency in REQUIRED_DEPENDENCIES:
            assert dependency in content, f"ADR-004 must reference dependency on {dependency}"

    def test_adr_has_security_cosign_field(self):
        content = _read_adr()
        assert "Security Co-Sign" in content or "Security Auditor" in content, \
            "ADR-004 must include a security co-sign field"

    def test_adr_has_stride_categories(self):
        content = _read_adr()
        for threat in STRIDE_THREATS:
            assert threat in content, f"ADR-004 STRIDE section missing threat: {threat}"


class TestADR004ArchitectureGuidance:
    """Validate cross-tenant architecture decisions remain explicit."""

    def test_adr_distinguishes_single_tenant_baseline_from_overlay(self):
        content = _read_adr()
        for phrase in ["single-tenant baseline", "cross-tenant collaboration overlay"]:
            assert phrase in content, f"ADR-004 must explicitly document: {phrase}"

    def test_adr_includes_required_cross_tenant_patterns(self):
        content = _read_adr()
        for phrase in REQUIRED_PATTERNS:
            assert phrase in content, f"ADR-004 missing required pattern language: {phrase}"

    def test_adr_separates_admission_from_authorization(self):
        content = _read_adr()
        assert "Can this external identity enter the tenant at all?" in content, \
            "ADR-004 must define the admission-layer question"
        assert "Now that the identity object exists in the resource tenant, what may this user access?" in content, \
            "ADR-004 must define the authorization-layer question"

    def test_adr_bans_resource_tenant_dynamic_group_inbound_gating(self):
        content = _read_adr()
        for phrase in REQUIRED_ANTI_PATTERN_TEXT:
            assert phrase in content, f"ADR-004 must preserve anti-pattern warning: {phrase}"

    def test_adr_states_dynamic_groups_belong_at_authorization_layer(self):
        content = _read_adr()
        assert "Dynamic groups are valid and encouraged here" in content, \
            "ADR-004 must affirm dynamic groups at the authorization layer"
        assert "Keep Dynamic Groups at the Authorization Layer" in content, \
            "ADR-004 must preserve authorization-layer guardrail"

    def test_adr_documents_direct_connect_limitations(self):
        content = _read_adr()
        for phrase in REQUIRED_DIRECT_CONNECT_LIMITS:
            assert phrase in content, \
                f"ADR-004 must preserve Direct Connect limitation guidance: {phrase}"

    def test_adr_documents_guest_vs_sync_decision_guidance(self):
        content = _read_adr()
        for phrase in REQUIRED_GUEST_VS_SYNC_GUIDANCE:
            assert phrase in content, \
                f"ADR-004 must preserve guest-vs-sync guidance: {phrase}"

    def test_adr_documents_order_of_operations(self):
        content = _read_adr()
        for phrase in REQUIRED_ORDER_OF_OPERATIONS:
            assert phrase in content, \
                f"ADR-004 must preserve order-of-operations step: {phrase}"

    def test_adr_includes_guardrails_for_future_work(self):
        content = _read_adr()
        for phrase in REQUIRED_GUARDRAILS:
            assert phrase in content, f"ADR-004 missing design guardrail: {phrase}"

    def test_adr_mentions_attribute_mapping_as_architecture(self):
        content = _read_adr()
        for phrase in ["department", "companyName", "jobTitle", "Attribute Mapping"]:
            assert phrase in content, \
                f"ADR-004 must explicitly connect sync attributes to authorization design: {phrase}"
