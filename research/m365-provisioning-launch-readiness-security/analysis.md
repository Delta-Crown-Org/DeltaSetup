# Multi-dimensional analysis

## Security

- Notification-generating operations must be treated as explicit launch communications, not provisioning side effects.
- Graph group `resourceBehaviorOptions` are creation-only, so ADR controls must require `WelcomeEmailDisabled` at creation and an Exchange remediation path for existing groups.
- Graph invitation defaults support suppression (`sendInvitationMessage: false`), but ADR should require explicit false to guard SDK/default drift.
- Guest subscription behavior creates residual risk: adding guests to M365 Groups can subscribe them even when internal auto-subscribe is disabled.
- GitHub environments and OIDC provide strong CI/CD controls, but only if branch, subject/audience claims, environment reviewers, and tenant-side federated credentials are tightly scoped.
- App credentials/certificates are a hard launch dependency; expiring credentials create availability and security risk.

## Cost and licensing

- Audit retention beyond 180 days requires E5/Audit Premium/add-ons for the relevant user/event population.
- GitHub required reviewers availability depends on repo visibility and plan; verify before making it a hard control.
- CIS benchmark access and assessment may require CIS WorkBench/current PDF review.

## Implementation complexity

- Static tests can enforce forbidden notification flags and launch markers.
- Human gate requires GitHub Environment configuration plus repository branch protection and workflow YAML `environment:` binding.
- OIDC implementation requires Microsoft Entra federated identity credentials with exact GitHub subject filters and Graph/PnP permissions scoped to provisioning tasks.

## Stability and maintenance

- Microsoft Learn pages have current update dates for key dependencies; ADR should pin source URLs and re-review before launch.
- Certificate rotation runbooks need recurring alerts, not one-time documentation.
- Audit evidence strategy must specify retention by license class, not a generic tenant-wide claim.

## Compatibility

- PnP PowerShell and Microsoft Graph overlap but do not expose identical notification controls; each cmdlet/API path needs an allow/deny matrix.
- Teams member-add in-product notifications remain a product-gap/residual-risk area; do not claim complete suppression.

## Maintenance / governance

- OWASP SAMM supports a required human security review and stakeholder risk acceptance before release/mass deployment.
- ASVS L2 should be used as a verification baseline for the launch workflow and any operator-facing web/API surface, but a proxy architect cannot self-certify ASVS conformance.

## What a proxy architecture review cannot approve

A proxy architecture review can recommend patterns and verify that an ADR cites authoritative sources. It cannot approve:

1. Production launch-mode invocation that intentionally sends notifications.
2. Security exception/risk acceptance for unresolved ASVS L2, SAMM, or CIS gaps.
3. Tenant-wide admin consent or Graph/PnP app permissions.
4. Audit retention adequacy without confirmed Purview licensing and retention policy state.
5. Certificate/key lifecycle readiness without verifying actual app registrations, owners, expirations, alerting, and rotation evidence.
6. CIS Microsoft 365 benchmark compliance without current benchmark assessment evidence.
7. External user/data exposure decisions, cross-tenant collaboration posture, or legal/compliance sign-off.
8. Claims that Teams/M365 notification suppression is complete where Microsoft documents a gap/exception.