# Raw evidence excerpts

- OWASP ASVS: provides a basis for testing web application technical security controls and secure development requirements; latest stable 5.0.0.
- OWASP SAMM Security Testing: automated tools can never replace expert manual review; prior to release or mass deployment, stakeholders review security test results and accept risks from failing tests; continuous security tests should improve the lifecycle.
- Microsoft Graph invitation: `sendInvitationMessage` controls whether email is sent and defaults to false; redemption URL can be sent by other means.
- Microsoft Graph group options: `resourceBehaviorOptions` can be set only on group creation; `WelcomeEmailDisabled` means welcome emails are not sent to new members; `HideGroupInOutlook` hides group in Outlook.
- Exchange `Set-UnifiedGroup`: `AutoSubscribeNewMembers` applies only to internal members; guest accounts are always subscribed when added as a member.
- Microsoft Purview audit retention: Audit Standard logs generated on/after 2023-10-17 retained 180 days; Audit Premium default retains Exchange/SharePoint/OneDrive/Entra records one year for E5/add-on users; non-E5/guest records retained 180 days; 10-year requires add-on.
- GitHub environments: environment secrets only available after configured rules such as required reviewers pass; required reviewers can include up to six people/teams; required reviewer availability is constrained by plan/repository visibility.
- GitHub OIDC: replaces duplicated long-lived cloud secrets with short-lived cloud tokens valid for a single job, controlled by provider authN/authZ and token claims.
- Microsoft Entra recommendation: `applicationCredentialExpiry` appears for app registration credentials expiring within 30 days; rotate cert/secret, validate sign-in logs, remove old credential.
- CIS Microsoft 365 benchmark: use as control taxonomy for MFA/conditional access, admin roles, audit logging, external sharing/collaboration, app consent, data protection; do not claim compliance without current benchmark assessment.