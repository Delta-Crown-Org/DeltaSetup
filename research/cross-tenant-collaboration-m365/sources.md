# Sources: Cross-Tenant Collaboration in Microsoft 365

## Tier 1 — Microsoft Learn

1. **Cross-tenant access overview**
   - URL: https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview
   - Why it matters: baseline behavior for B2B collaboration, direct connect, sync, trust, and partner-specific settings.

2. **Cross-tenant access settings for B2B collaboration**
   - URL: https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-collaboration
   - Why it matters: partner policy behavior, inbound/outbound controls, application scoping, automatic redemption.

3. **B2B Direct Connect overview**
   - URL: https://learn.microsoft.com/en-us/entra/external-id/b2b-direct-connect-overview
   - Why it matters: confirms this pattern is for Teams shared channels, not general SharePoint site access.

4. **Cross-tenant synchronization overview**
   - URL: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-overview
   - Why it matters: provisioning behavior, use cases, prerequisites, lifecycle implications.

5. **Configure cross-tenant synchronization**
   - URL: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/cross-tenant-synchronization-configure
   - Why it matters: sequencing, mappings, sync scopes, and prerequisites.

6. **Multi-tenant organization overview**
   - URL: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview
   - Why it matters: when MTO matters and when it is unnecessary overhead.

7. **SharePoint external sharing overview**
   - URL: https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview
   - Why it matters: resource-layer sharing controls and tenant/site external access constraints.

8. **Microsoft Entra B2B user properties**
   - URL: https://learn.microsoft.com/en-us/entra/external-id/user-properties
   - Why it matters: guest/member semantics, directory state, and user object expectations.

9. **Microsoft identity platform error codes**
   - URL: https://learn.microsoft.com/en-us/entra/identity-platform/reference-error-codes
   - Why it matters: troubleshooting and classifying sign-in failures like `AADSTS500213`.

## Tier 2 — Existing Research in This Repo

1. `research/sharepoint-franchise-portal/raw-findings/entra-b2b-collaboration.md`
2. `research/sharepoint-franchise-portal/raw-findings/multi-tenant-limitations.md`
3. `research/sharepoint-hub-spoke/analysis.md`
4. `research/sharepoint-provisioning/analysis.md`
5. `research/phase3-sharepoint-teams/README.md`

## Tier 2 — Internal HTT Project Evidence

1. `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/AADSTS500213-ROOT-CAUSE-AND-FIX.md`
   - Why it matters: direct evidence of the chicken-and-egg failure caused by scoping inbound B2B collaboration to resource-tenant dynamic groups.

2. `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/CROSS-TENANT-DIRECT-ACCESS-INVESTIGATION.md`
   - Why it matters: confirms B2B Direct Connect limits, partner-policy realities, and first-run behavior tradeoffs.

3. `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/COMPREHENSIVE-ACCESS-AUDIT-20260409.md`
   - Why it matters: shows how identity policy, group membership, and SharePoint binding interact in a live rollout.

4. `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/GROUP_CONVERSION_SUMMARY.md`
   - Why it matters: documents domain-based dynamic-group usage and where that pattern helped versus hurt.

5. `/Users/tygranlund/dev/03-personal/Cross-Tenant-Utility/HTT-CROSS-TENANT-IDENTITY-ANALYSIS.md`
   - Why it matters: broader operating model across HTT brands, including deny-by-default posture, MTO asymmetry, sync, and policy governance.

6. `/Users/tygranlund/dev/03-personal/Cross-Tenant-Utility/README.md`
   - Why it matters: operational framing for auditing cross-tenant sync, B2B collaboration, direct connect, and identity governance.

## Confidence Notes
- Microsoft Learn sources are authoritative for product behavior.
- Internal HTT repo evidence is highly valuable for real-world sequencing, failure modes, and operational gotchas.
- Where Microsoft documentation and field behavior diverge in feel, prefer Microsoft for capability boundaries and use internal evidence for rollout sequencing and troubleshooting nuance.
