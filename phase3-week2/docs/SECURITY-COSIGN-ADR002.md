# Security Auditor Co-Sign: ADR-002 STRIDE Analysis

| Field | Value |
|-------|-------|
| **Status** | CONDITIONALLY APPROVED |
| **Date** | 2025-07-26 |
| **Reviewer** | security-auditor-96bb8e |
| **ADR** | ADR-002: Phase 3 SharePoint Sites + Teams Collaboration |
| **Risk Level** | Moderate — Acceptable with controls |
| **Re-audit** | Required at 30 days (DLP enforcement review) |

## Mandatory Pre-Implementation Conditions

| ID | Condition | Status |
|----|-----------|--------|
| SEC-002-1 | Reduce DLP test mode to 30 days (not 90) with enforcement review trigger | ⬜ |
| SEC-002-2 | Column-level encryption or field protection for allergy/medical data in Client Records | ⬜ |
| SEC-002-3 | Teams app governance policy (block sideloading, approval required) | ⬜ |
| SEC-002-4 | PnP template signed commits + build verification pipeline | ⬜ |
| SEC-002-5 | Document data residency confirmation (AU-only tenant) | ⬜ |
| SEC-002-6 | Daily DLP match monitoring during test period (not weekly) | ⬜ |
| SEC-002-7 | Privacy Impact Assessment for health data processing | ⬜ |

## Risk Rating Adjustments Accepted

| Component | Original | Adjusted | Reason |
|-----------|----------|----------|--------|
| DLP Policies (Tampering) | 🟡H | 🔴C | 90-day test mode = material control gap |
| SharePoint Lists (PII) | 🔴C | 🔴C + Regulatory | Health data triggers AU Privacy Act obligations |

## Additional Threats Identified

1. **Azure AD sync account compromise** — Elevation risk (🟡H)
2. **Malicious Teams app installation** — Elevation risk (🟡H)
3. **Data residency/sovereignty** — Info Disclosure regulatory risk (🟡H)

## Key Recommendation: Reduce DLP Test Period

The Security Auditor strongly recommends reducing DLP test mode from 90 days to 30 days with:
- Daily (not weekly) DLP match report review
- Automated alert on external sharing attempts
- Pre-defined triggers for immediate enforcement
- 30-day checkpoint review with business sign-off

## Health Data Protection Requirements

Client allergy/medical notes in SharePoint lists require:
1. Column-level encryption (MIP field-level protection)
2. Audit logging with alerting on bulk access
3. Data minimization review (is SharePoint the right location?)
4. Privacy Impact Assessment
5. Defined retention and disposal procedures
