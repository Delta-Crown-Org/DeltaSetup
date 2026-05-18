# M365/SharePoint provisioning launch-readiness security evidence

Research date: 2026-05-18  
Agent: web-puppy-846895

## Executive findings

1. **Keep notification suppression as default.** Microsoft Graph `resourceBehaviorOptions` can disable M365 Group welcome email only at group creation; Graph B2B invitations default `sendInvitationMessage` to `false`; guest group conversation subscription has a documented exception that guests are always subscribed when added as members.
2. **Launch mode must be human-gated.** OWASP SAMM expects stakeholder risk review before release/mass deployment, and GitHub environments support required reviewers / deployment protection rules, subject to plan and repository visibility limitations.
3. **Prefer GitHub OIDC over stored tenant secrets.** GitHub documents OIDC as eliminating long-lived cloud secrets by exchanging workflow identity for short-lived cloud tokens.
4. **Audit evidence retention is license-sensitive.** Audit Standard is 180 days for records generated on/after 2023-10-17; Audit Premium can retain core workloads for one year for E5/add-on users, and up to 10 years with the 10-year add-on.
5. **Certificate lifecycle must be a release dependency.** Microsoft Entra recommendation `applicationCredentialExpiry` flags app credentials expiring within 30 days and requires rotation, validation in sign-in logs, and old credential removal.
6. **Proxy architecture review cannot approve production security.** A proxy reviewer can validate architecture invariants and source alignment, but cannot sign off ASVS L2/CIS compliance, tenant license posture, least-privilege consent, human risk acceptance, or operational launch readiness without authorized security/tenant owner review.

See `sources.md`, `analysis.md`, and `recommendations.md` for concise evidence and ADR language.