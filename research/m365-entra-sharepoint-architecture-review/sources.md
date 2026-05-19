# Sources and credibility assessment

All sources below are **Tier 1** primary vendor documentation unless noted otherwise.

| Source | Tier | Currency observed | Relevance | Credibility notes |
|---|---:|---|---|---|
| GitHub Docs — Notifications for workflow runs: <https://docs.github.com/en/actions/concepts/workflows-and-actions/notifications-for-workflow-runs> | 1 | Current GitHub Docs page; no page date shown in extracted content | GitHub Actions failure/scheduled workflow notification behavior | Official GitHub product documentation; primary source for notification behavior. |
| Microsoft Learn — What is Microsoft Entra monitoring and health?: <https://learn.microsoft.com/en-us/entra/identity/monitoring-health/overview-monitoring-health> | 1 | Last updated 2025-11-18 | Entra audit, sign-in, provisioning logs and monitoring architecture | Official Microsoft Learn; primary source for Entra log types and routing expectations. |
| Microsoft Learn — Integrate Microsoft Entra logs with Azure Monitor logs: <https://learn.microsoft.com/en-us/entra/identity/monitoring-health/howto-integrate-activity-logs-with-azure-monitor-logs> | 1 | Last updated 2026-01-06 | Diagnostic settings, Log Analytics prerequisites, Security Administrator role | Official Microsoft Learn; procedure source for streaming logs. |
| Microsoft Learn — Microsoft Entra activity log integration options: <https://learn.microsoft.com/en-us/entra/identity/monitoring-health/concept-log-monitoring-integration-options-considerations> | 1 | Last updated 2025-05-27 | Long-term retention, SIEM/Azure Monitor integration, cost considerations | Official Microsoft Learn; primary source for >30-day storage/analysis guidance. |
| Microsoft Learn — Azure Monitor alerts overview: <https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview> | 1 | Last updated 2026-04-24 | Alert rules, action groups, stateful/stateless behavior, RBAC | Official Microsoft Learn; primary source for alert acceptance criteria. |
| Microsoft Learn/Purview — Auditing solutions overview: <https://learn.microsoft.com/en-us/purview/audit-solutions-overview> | 1 | Last updated 2026-05-18 | Unified audit log, Standard/Premium retention, Management Activity API | Official Microsoft Learn; primary source for M365/Purview audit capabilities. |
| Microsoft Learn/Purview — Audit log activities: <https://learn.microsoft.com/en-us/purview/audit-log-activities> | 1 | Last updated 2026-04-02 | SharePoint/OneDrive sharing, site permissions, site admin, app/admin operations | Official Microsoft Learn; primary event taxonomy for evidence queries. |
| Microsoft Learn — Manage users and groups assignment to an application: <https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/assign-user-or-group-access-portal> | 1 | Last updated 2026-04-01 | Enterprise app user/group assignments, roles, Graph/PowerShell evidence | Official Microsoft Learn; primary procedural source for app assignment controls. |
| Microsoft Learn — Manage access to an application: <https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/what-is-access-management> | 1 | Last updated 2024-09-24 | Assignment required, local-account bypass, assignment models | Official Microsoft Learn; primary source for access-management behavior and bypass risks. |
| Microsoft Learn — Multitenant organization capabilities in Microsoft Entra ID: <https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/overview> | 1 | Last updated 2026-03-18 | MTO, B2B collaboration/direct connect, cross-tenant sync, people search | Official Microsoft Learn; primary source for MTO and cross-tenant sync semantics. |

## Validation and bias

- **Validation:** Findings cross-reference Microsoft Entra monitoring pages with Azure Monitor alerting, Purview audit retention/activity references, and Enterprise App assignment/access-management docs. MTO recommendations cross-reference Microsoft 365 collaboration caveats from the same Microsoft Learn MTO overview.
- **Bias:** Vendor documentation may understate operational complexity/cost. Cost cautions are explicit where Microsoft documents ingestion/storage/Sentinel/Event Hub charges.
- **Primary vs secondary:** No secondary/tutorial sources were used.
