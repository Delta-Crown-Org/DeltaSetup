# ADR-011 launch-readiness architecture security memo — 2026-05-18

**Reviewer:** `solutions-architect-ddca8e`  
**Requested by:** `code-puppy-73a4b6`  
**Scope:** Security-by-design review of ADR-011 launch-readiness gaps.  
**Non-scope:** This is **not** an ASVS L2 review, CIS Microsoft 365 Benchmark
attestation, tenant security attestation, legal/compliance approval, or
production launch risk acceptance.

## Bottom line

`DeltaSetup-v0i` **cannot be closed** by invoking Solutions Architect. The
issue explicitly requires a dedicated `security-auditor` agent or Tier-1 human
security review before production launch-mode invocation. A security-by-design
memo is useful evidence, but it is not independent security sign-off.

Production launch-mode remains **blocked**.

Development/scaffold work can continue while deploy/prod/launch workflows remain
inactive and no real-recipient notification path is exercised.

## Production launch-mode blockers

1. No dedicated security-auditor agent or named Tier-1 human reviewer has signed
   off.
2. GitHub required-reviewer environment protection is unsupported on the current
   plan; the existing `prod` environment is an unprotected placeholder and
   `launch` does not exist.
3. Runtime-constructed Graph/PnP/REST bodies are not fully constrained by tests.
4. Tenant empirical canaries for notification suppression have not run.
5. PnP/Graph dependency pinning and provenance/signature verification are not
   complete.
6. Certificate lifecycle controls are incomplete: rotation, alerting, and
   OIDC/HSM-backed storage strategy.
7. Audit/artifact retention is not pinned to actual DCE tenant SKU and GitHub
   plan limits.
8. Launch-mode blast-radius controls are incomplete: recipient cap, throttle,
   manifest SHA, and CI-only approval token/JWT.
9. Quarterly access digest workflow has not shipped.
10. Per-capability “detection-channel of last resort” requirement is not yet
    broadly enforced for new provisioning surfaces.

## Top five next controls, ranked

1. **Establish a real launch approval gate independent of the author.**
   Required reviewer environments are unavailable on the current plan, so either
   upgrade/change GitHub support or implement an equivalent external signed
   approval/ticket gate with audit trail and CI verification.
2. **Add runtime body defense for Graph/PnP/REST notification paths.** Calls to
   `/groups`, `/invitations`, `/invite`, and group membership paths must fail
   closed unless suppression literals or explicit reviewed waivers exist.
3. **Run empirical canaries in the actual tenant.** Prove guest invitation,
   group creation, member-add, and launch-mode behavior against controlled test
   recipients with retained evidence.
4. **Pin/verify Graph and PnP dependencies and harden credential lifecycle.**
   Block unpinned installs, document approved module versions, verify provenance
   where possible, and move toward OIDC/federated identity or a documented
   cert-rotation ceremony.
5. **Complete retention and evidence decisions.** Cite actual tenant SKU/Purview
   retention, GitHub artifact retention, and any off-platform mirror needed for
   launch manifests, approval evidence, and `provisioning-mode.log`.

## Recommended `DeltaSetup-v0i` status

Keep open until one of the following happens:

- a real security-auditor agent is added and performs the review, or
- a named Tier-1 human security reviewer / tenant security owner signs off with
  date, scope, findings, explicit launch-mode decision, and risk acceptance owner
  for unresolved gaps.

## Operational decision

- **Scaffold/no-email DEV work:** allowed to continue.
- **No-secrets validation CI:** allowed and already active.
- **Deploy/prod/launch workflows:** remain inactive.
- **Production launch-mode:** blocked.
