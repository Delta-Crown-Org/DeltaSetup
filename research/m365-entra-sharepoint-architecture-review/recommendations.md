# Recommendations

## Must-have review gates

1. **Alerting is evidence-backed, not aspirational.** Require screenshots/exports for GitHub failure alerts, Azure Monitor alert rules, action groups, test-fired alerts, and ownership/runbook links.
2. **Entra logs are streamed.** Require diagnostic settings for audit, sign-in, provisioning, risky user/risk detection, and service-principal/application-relevant logs to Log Analytics/Sentinel/Event Hub/storage.
3. **SharePoint audit queries are named.** Drafts should list the exact Purview operations monitored for anonymous links, sharing policy changes, site admins, group membership, permission inheritance, and hub join/unjoin.
4. **Enterprise app assignments are deterministic.** Require `appRoleAssignmentRequired` where supported, named groups for normal access, no nested-group assumptions, and direct assignments only by exception with expiry/review owner.
5. **MTO/cross-tenant sync is pre-inventoried.** Before enabling/changing MTO, export existing B2B members, inbound/outbound access settings, sync scopes, target `userType`, address-list behavior, and deprovisioning test evidence.
6. **Break-glass is explicit.** Maintain two emergency accounts, least-privilege admin roles for normal operations, and sign-in/audit alerts for emergency account use.

## Suggested acceptance checklist for architecture drafts

- [ ] GitHub: failing workflow produces an alert to named accountable recipient or shared operational channel; branch protection blocks failed required checks.
- [ ] GitHub: scheduled workflows have an accountable owner not tied to an inactive/departed user; cron owner behavior is documented.
- [ ] Entra: diagnostic setting exists; first rows verified in Log Analytics/Sentinel for audit, sign-in, and provisioning tables.
- [ ] Entra: alert rules exist for admin role changes, service principal credential changes, app consent/assignment changes, emergency account sign-in, risky sign-ins/users, and cross-tenant sync provisioning failures.
- [ ] Purview/SharePoint: Audit Standard/Premium retention claim matches license/configuration; export path exists for evidence beyond 180 days if required.
- [ ] SharePoint: saved audit searches/KQL cover anonymous link creation/use, secure link changes, sharing invitation events, site collection admin add/remove, SharePoint group add/remove, sharing policy changes, hub registration/join/unjoin.
- [ ] Enterprise apps: direct app assignments exported and reviewed; group-based app assignment uses direct group members only; nested groups are not counted for access.
- [ ] Enterprise apps: local/bypass credentials disabled or lifecycle-managed; provisioning disables/deletes app-local accounts when users leave scope.
- [ ] MTO: cross-tenant access settings explicitly configured per tenant pair; auto-redemption decision recorded; sync is one-way and scoped.
- [ ] MTO: people-search and Teams/Viva behavior documented; `userType=Member` and `showInAddressList` impacts approved by owner.

## Priority for DeltaSetup

- **P0:** Entra/Purview evidence and break-glass alerting for the production tenant.
- **P1:** Enterprise app direct-assignment review and SharePoint sharing/site-permission drift queries.
- **P2:** MTO/cross-tenant sync design guardrails before expanding HTT/DCE tenant relationships.
