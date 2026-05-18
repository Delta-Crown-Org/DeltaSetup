# ADR recommendations

## Must-have ADR requirements

1. **Default-off notifications:** all provisioning scripts default to scaffold/silent mode; launch communications require separate launch workflow, explicit marker, and environment approval.
2. **Static suppression tests:** block `sendInvitationMessage: true`, `sendInvitation: true`, PnP send-invite flags, group welcome re-enable flags, and missing creation-time `WelcomeEmailDisabled` where applicable.
3. **GitHub human gate:** production launch workflow must bind jobs to a protected GitHub Environment with required reviewers and environment secrets; verify plan/repo visibility supports this before relying on it.
4. **OIDC-first authentication:** use GitHub OIDC/federated identity credentials for Entra/Azure access; avoid long-lived GitHub secrets for tenant credentials.
5. **Least-privilege app permissions:** document Graph/PnP permissions, admin consent owner, expiration/rotation plan, and rollback before launch.
6. **Audit readiness:** confirm Purview audit is enabled/searchable, retention policy and licensing support the required forensic window, and launch workflow emits correlation IDs/run IDs.
7. **Certificate/key lifecycle:** no launch if provisioning app cert/secret expires inside the defined safety window; enable Entra recommendations/alerts and record rotation owner.
8. **Human security review:** require named security/tenant owner co-sign for ASVS L2/CIS/security-risk acceptance. Proxy architecture review is advisory only.

## Concise ADR wording to add

> Launch mode is a privileged, human-approved production change. A proxy architecture review may validate architectural consistency, source citations, and testable controls, but it does not constitute security approval. Production launch requires named human security/tenant owner review of Graph/PnP permissions, GitHub environment protection, OIDC trust policy, Purview audit retention/licensing, certificate lifecycle, notification residual risks, and ASVS L2/CIS-mapped gaps.

## Priority checklist

- [ ] GitHub Environment `production-launch` exists with required reviewers and self-review prevention if available.
- [ ] Workflow uses `permissions: id-token: write` only where OIDC is needed and has no tenant client secrets.
- [ ] Entra federated credential `sub` is restricted to repo + environment/branch, not broad wildcard.
- [ ] Launch workflow produces audit artifact containing run id, actor, commit SHA, mode, target groups/sites, and intended notification surfaces.
- [ ] Purview audit retention verified for launch actors and affected users/guests.
- [ ] App registration owners, credentials, expiry dates, and rotation runbook verified.
- [ ] Explicit residual-risk note for guest group subscription and Teams/member-add notifications.
- [ ] Human security reviewer signs ASVS L2/CIS mapped acceptance before first launch.