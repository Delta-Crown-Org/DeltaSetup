# Raw findings: cross-tenant access overview

Key excerpts captured from Microsoft Learn:
- B2B collaboration is enabled by default with other Entra tenants; B2B Direct Connect is blocked by default.
- Inbound and outbound settings can be scoped to specific users, groups, and applications.
- Automatic redemption applies to cross-tenant sync, B2B collaboration, and B2B Direct Connect.
- Consent prompt suppression only happens if both source/outbound and target/inbound settings enable it.
- Microsoft warns app allowlists can break My Apps, MFA registration, or Terms of Use flows unless supporting apps are explicitly allowed.
