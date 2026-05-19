# Official excerpts used

## GitHub Actions notification behavior

- GitHub: “If you enable email or web notifications for GitHub Actions, you'll receive a notification when any workflow runs that you've triggered have completed… You can also choose to receive a notification only when a workflow run has failed.”
- GitHub: “Notifications for scheduled workflows are sent to the user who initially created the workflow.” If cron syntax is changed, notifications go to that user; if disabled/re-enabled, notifications go to the user who re-enabled it.

Source: <https://docs.github.com/en/actions/concepts/workflows-and-actions/notifications-for-workflow-runs>

## Entra logs and routing

- Microsoft Entra monitoring: activity log types are audit logs (“history of every task performed in your tenant”), sign-in logs (“sign-in attempts of your users and client applications”), and provisioning logs (“users provisioned in your tenant through a third party service”).
- Microsoft: “Monitoring Microsoft Entra activity logs requires routing the log data to a monitoring and analysis solution. Endpoints include Azure Monitor logs, Microsoft Sentinel, or a third-party… SIEM tool.”
- Microsoft integration options: for troubleshooting without >30-day retention use portal/Graph; for >30 days export to storage; for regular querying/monitoring use Azure Monitor logs/SIEM.

Sources: <https://learn.microsoft.com/en-us/entra/identity/monitoring-health/overview-monitoring-health>, <https://learn.microsoft.com/en-us/entra/identity/monitoring-health/concept-log-monitoring-integration-options-considerations>

## Azure Monitor alerting

- Azure Monitor: alerts proactively notify when Azure Monitor data indicates a problem.
- Alert rule components: monitored resources, signal/data, and conditions.
- Alerts initiate associated action groups; action groups can include email/SMS/push, runbooks, Functions, ITSM, Logic Apps, secure webhooks/webhooks, and Event Hubs.
- Alerts can be stateful or stateless; activity log alerts are stateless.

Source: <https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview>

## Purview/M365 audit

- Purview: unified audit log captures, records, and retains thousands of user/admin operations across Microsoft services.
- Audit Standard: enabled by default for eligible subscriptions and retains records for 180 days; default changed from 90 to 180 days for logs generated on/after 2023-10-17.
- Audit Premium: supports retention policies, one-year default for Microsoft Entra ID/Exchange/OneDrive/SharePoint audit records, and optional 10-year retention add-on.

Source: <https://learn.microsoft.com/en-us/purview/audit-solutions-overview>

## SharePoint audit activity families

- Purview audit activities include SharePoint/OneDrive file/page activities, sharing/access request activities, site administration activities, and site permissions activities.
- Relevant operations include `AnonymousLinkCreated`, `AnonymousLinkUsed`, `SharingPolicyChanged`, `SiteCollectionAdminAdded`, `SiteCollectionAdminRemoved`, `AddedToGroup`, `RemovedFromGroup`, `SharingInheritanceBroken`, `SharingInheritanceReset`, `HubSiteJoined`, `HubSiteUnjoined`, `HubSiteRegistered`, `HubSiteUnregistered`.

Source: <https://learn.microsoft.com/en-us/purview/audit-log-activities>

## Enterprise Application assignment controls

- Microsoft: assigning a group to an application means “only users in the group have access”; assignment “doesn't cascade to nested groups.”
- Group-based assignment requires Microsoft Entra ID P1/P2; nested group memberships aren't currently supported.
- If user assignment is required, only assigned users directly or through group membership can sign in.
- If assignment isn't required, unassigned users can still sign in to the application itself or use User Access URL.
- Microsoft warns local credentials/backup auth can permit access after Entra assignment removal and might not appear in Entra logs.

Sources: <https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/assign-user-or-group-access-portal>, <https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/what-is-access-management>

## MTO / cross-tenant sync

- MTO defines a boundary around Microsoft Entra tenants the organization owns.
- Cross-tenant access settings govern B2B collaboration, B2B direct connect, and cross-tenant synchronization; tenant admins explicitly configure each tenant-to-tenant relationship.
- Cross-tenant synchronization is one-way and automates creating, updating, and deleting B2B collaboration users across tenants.
- B2B direct connect users aren't represented in the resource tenant directory; B2B collaboration users are represented in the directory.
- Existing B2B collaboration member users in tenants that are part of an MTO immediately become MTO members upon MTO creation.
- M365 people search generally requires B2B users to be shown in address lists and set to `userType=Member` for most M365 applications.

Source: <https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/overview>
