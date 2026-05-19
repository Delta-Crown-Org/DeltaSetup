# Recommendations

1. **Require evidence of CI/CD failure visibility**: architecture drafts should name the workflow failure signal, owner, and escalation path. Evidence can be GitHub notifications, status badges, and/or webhook-based monitoring.
2. **Treat drift detection as a control objective**: require periodic review evidence for Entra applications/groups/users/licenses and SharePoint sharing/site-permission changes.
3. **Document direct app assignments as exceptions/bridges**: require owner, reason, expiry/review date, and compensating monitoring for every direct Entra app assignment that bypasses group/dynamic-group intent.
4. **Use Purview/M365 audit as the evidence plane**: cite the relevant audit event families for SharePoint files/pages, sharing/access requests, site administration, and site permissions.
5. **Defer MTO membership evaluation**: do not co-sign MTO until cross-tenant topology, trusted tenants, userType/showInAddressList strategy, provisioning ownership, and exit/removal behavior are explicitly reviewed.
