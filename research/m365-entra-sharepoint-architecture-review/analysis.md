# Analysis for DeltaSetup architecture review

## Controls and alerting acceptance criteria

- **GitHub Actions:** Do not rely solely on personal GitHub notification preferences. GitHub only documents notifications for workflow runs a user triggers and scheduled workflow notifications tied to creator/cron updater/re-enabler. Acceptance evidence should include: repo Actions tab run URL, failing-run notification proof for the accountable user or shared mailbox, and branch protection/status checks preventing failed deployments.
- **Entra monitoring:** Native portal/Graph views are suitable for near-term investigation, but Microsoft recommends routing logs to Azure Monitor/Sentinel/SIEM/storage for monitoring and longer retention. Acceptance evidence should include diagnostic setting screenshots/export JSON, selected categories, destination workspace/Event Hub/storage, and first ingested rows from `AuditLogs`, `SigninLogs`, and provisioning logs.
- **Azure Monitor alerts:** Every critical drift condition should have an alert rule, a condition/query, an action group, owner(s), test evidence, and documented suppression rules. Use stateful log alerts where repeated noise would hide real incidents; use explicit action groups for on-call/shared operational ownership.
- **Purview/M365 audit:** Audit Standard default 180-day retention is a review boundary, not a compliance archive. If drafts claim year-long or long-term evidence, require Audit Premium retention policies or export through Management Activity API/SIEM/storage.

## Drift risks

- **SharePoint:** High drift areas are anonymous links, company links, guest sharing, site collection admins, SharePoint groups, hub associations, permission inheritance, and tenant sharing policy changes. Purview audit activities provide event names for all of these; architecture drafts should map each control to an evidence query.
- **Enterprise apps:** Direct assignments drift quickly and nested-group assumptions are invalid for group-based app assignment. Require direct assignment inventory and group membership export in the evidence pack.
- **MTO/cross-tenant sync:** Cross-tenant synchronization can automatically create, update, and delete B2B collaboration users, but scoping and `userType` decisions directly affect visibility in Outlook/M365 apps. Existing B2B member users can become MTO members immediately upon MTO creation, so pre-join inventory is mandatory.

## Least privilege and break-glass

- Prefer Cloud Application Administrator/Application Administrator/User Administrator/service-principal owner for app assignment work rather than Global Administrator.
- Prefer Security Administrator for configuring Entra log streaming; grant Log Analytics access separately via Azure RBAC.
- Maintain two cloud-only emergency accounts with documented exclusions, strong credentials/FIDO where applicable, and sign-in alerting. Break-glass should be monitored, not hidden.

## Evidence links/patterns to require in drafts

- GitHub workflow run URLs and failed-run notification proof.
- Entra diagnostic setting ID/JSON and Log Analytics query results.
- Azure Monitor alert rule IDs/JSON, action group IDs, and test-fired alert instance links.
- Purview audit search links/exports for SharePoint sharing, site admin, and permission events.
- Graph/PowerShell exports for Enterprise Application `appRoleAssignedTo` and app property `appRoleAssignmentRequired`.
- Cross-tenant access settings, cross-tenant sync configuration, provisioning logs, and target user inventory showing `userType`, `showInAddressList`, source tenant, and deprovisioning tests.

## Cost/complexity/maintenance notes

- Entra diagnostic streaming to Log Analytics/Sentinel/Event Hub/storage has variable ingestion/storage costs; Microsoft notes sign-in events average larger than audit events and recommends sampling or a 1-2 day integration to estimate cost.
- Azure Monitor alert sprawl creates maintenance overhead; use workspace-centric log alerts where possible and document ownership.
- MTO/M365 people search can create user-experience benefits but increases identity-lifecycle coupling between tenants; quarterly evidence reviews are necessary.
