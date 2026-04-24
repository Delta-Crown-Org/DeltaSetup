# Recommendations for DeltaSetup

## Priority 1 — Avoid unnecessary cross-tenant patterns
Keep DeltaSetup collaboration **single-tenant by default** wherever organizationally possible. This aligns with the current ADR direction and avoids first-run cross-tenant policy failures, guest discoverability issues, and split operator troubleshooting paths.

## Priority 2 — Use the right external model for the right job
- **Need full SharePoint site / Team / M365 group access?** Use **B2B collaboration**.
- **Need only a Teams shared channel with no tenant switching?** Use **B2B Direct Connect**.
- **Need pre-provisioned identities and lifecycle sync across related tenants?** Use **cross-tenant synchronization**.

## Priority 3 — Design first-run access intentionally
For any cross-tenant pilot:
- configure cross-tenant access on **both sides**,
- enable **automatic redemption** on both sides where appropriate,
- avoid using **resource-tenant dynamic guest groups** as the primary first-run admission gate,
- include supporting Microsoft apps in any app allowlist.

## Priority 4 — Build an operator runbook
Document how support should verify:
1. invitation/redeemed state,
2. inbound/outbound cross-tenant settings,
3. correct collaboration model,
4. app allowlist completeness,
5. SharePoint external sharing settings,
6. Teams membership propagation delay,
7. whether the user should or should not exist as an Entra object in the resource tenant.

## Priority 5 — Pilot the uncertain edge cases
Before committing to a multi-tenant DeltaSetup operating model, run a lab for:
- first-run B2B access with app allowlists,
- shared channel access with guest access enabled/disabled,
- external member vs guest behavior in SharePoint navigation and people search,
- the specific AADSTS500213-style scenario suspected when resource-tenant policies rely on dynamic groups.
