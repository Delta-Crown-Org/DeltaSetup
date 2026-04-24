# Analysis

## Security
- Cross-tenant access settings are the primary control plane for B2B collaboration and B2B Direct Connect between Entra tenants.
- Default posture is asymmetric: **B2B collaboration allowed by default**, **B2B Direct Connect blocked by default**.
- Trusting MFA/device claims improves UX, but mis-scoped policies can block first access.
- App allowlists are security-useful but operationally dangerous if My Apps / My Sign-ins / App Access Panel are omitted.

## Implementation complexity
- **B2B collaboration**: lowest complexity for broad access.
- **B2B Direct Connect**: medium complexity because both orgs must coordinate mutual trust; narrow benefit.
- **Cross-tenant sync**: highest complexity due to provisioning setup, licensing, scoping, and lifecycle design.

## Stability / maturity
- B2B collaboration is the most established and broadest feature.
- B2B Direct Connect remains intentionally narrow and tied to Teams shared channels.
- Cross-tenant sync is real and useful, but Microsoft still documents many “same as B2B collaboration” M365 experiences today.

## Optimization / UX
- Automatic redemption is a major UX improvement but requires bilateral configuration.
- Pre-created synced objects reduce first-run surprises.
- Shared channels minimize tenant switching, but only for channel-scoped collaboration.

## Compatibility with DeltaSetup
- DeltaSetup’s current repo architecture is fundamentally **single-tenant SharePoint/Teams hub-spoke**.
- Therefore, cross-tenant identity patterns should be treated as **exception paths**, not baseline architecture.
- If some franchise/partner scenarios become cross-tenant later, choose the collaboration model per scenario instead of trying to force one universal external model.

## Maintenance / supportability
- Support teams need a runbook that distinguishes:
  - guest in team/site,
  - synced external member/guest,
  - shared-channel participant with no guest object.
- Troubleshooting is significantly easier if DeltaSetup standardizes naming, support scripts, and known-good app allowlists.
