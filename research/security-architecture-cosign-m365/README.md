# Security architecture co-sign evidence: M365 / Entra ID / SharePoint

## Executive summary

Security-review evidence supports treating the architecture draft concerns as STRIDE-relevant controls, not implementation niceties:

- GitHub Actions failures need observable notification paths because GitHub can notify triggering users and expose workflow statuses, while webhooks can emit completed workflow-run/job events for external monitoring.
- Audit drift detection is justified by Microsoft Entra and Microsoft Purview audit capabilities: changes to apps, groups, users, licenses, SharePoint sharing/permissions, and site administration are logged and can be searched/exported/API-collected.
- Entra app assignment controls should avoid implicit access. Microsoft documents that requiring assignment prevents unassigned users from signing in; direct app-role assignments are valid but should be visible as explicit bridge exceptions.
- SharePoint/M365 audit logging is mature enough to support review evidence for file/page, sharing/access-request, site-admin, and site-permission events, with known caveats about noise and system/app identities.
- MTO membership evaluation should be deferred until identity topology and provisioning intent are settled: Microsoft describes MTO as high-trust, immediately recognizing existing B2B collaboration member users as MTO users, and relying on provisioning/cross-tenant access settings.

Primary source set: Microsoft Learn, GitHub Docs, NIST SP 800-53 Rev. 5, and CISA SCuBA.
