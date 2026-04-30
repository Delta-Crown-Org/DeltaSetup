# Delta Crown Security Policy Singleton Confirmation

## Audit status

Completed a read-only Microsoft Graph PowerShell confirmation pass for security policy objects that were not readable through the earlier Azure CLI Graph token inventory.

Tenant:

```text
deltacrown.com / ce62e17d-2feb-4e67-a115-8ea4af68da30
```

Method:

```powershell
pwsh -NoProfile -File phase4-migration/scripts/confirm-delta-crown-security-policy-singletons.ps1
```

Requested delegated read scopes:

```text
Policy.Read.All
Directory.Read.All
Organization.Read.All
```

Raw local outputs:

```text
.local/reports/tenant-inventory/security-policy-confirmation/identitySecurityDefaults.json
.local/reports/tenant-inventory/security-policy-confirmation/authenticationMethodsPolicy.json
.local/reports/tenant-inventory/security-policy-confirmation/adminConsentRequestPolicy.json
.local/reports/tenant-inventory/security-policy-confirmation/policy-confirmation-summary.json
```

Raw outputs are local-only because they contain full policy JSON.

No security defaults, authentication methods, admin consent settings, users, apps, or tenant settings were changed.

## Results

| Policy object | Readable | Finding |
|---|---|---|
| Security defaults enforcement policy | Yes | Security defaults are disabled. |
| Authentication methods policy | Yes | Policy version `1.5`; method states listed below. |
| Admin consent request policy | Yes | Admin consent request workflow is disabled. |

## Security defaults

```text
isEnabled = false
```

Interpretation:

- Security defaults are not enforcing baseline defaults.
- Conditional Access exists separately and should be treated as the primary visible enforcement layer from the current inventory.

## Authentication methods

| Method | State |
|---|---|
| Fido2 | disabled |
| MicrosoftAuthenticator | enabled |
| Sms | enabled |
| TemporaryAccessPass | disabled |
| SoftwareOath | enabled |
| Voice | disabled |
| Email | enabled |
| X509Certificate | disabled |
| QRCodePin | disabled |

Policy version:

```text
1.5
```

## Admin consent request policy

| Setting | Value |
|---|---:|
| Admin consent request enabled | false |
| Notify reviewers | false |
| Reminders enabled | false |
| Request duration in days | 0 |

Interpretation:

- End-user admin consent request workflow is not enabled from this policy object.
- App consent should continue to be reviewed through app registrations, enterprise apps, and OAuth2 permission grant evidence.

## Readiness implications

1. The earlier access gaps from the Graph inventory are now resolved for these singleton policy objects.
2. Security defaults are disabled; Conditional Access policies are therefore especially important.
3. Authentication methods are readable and show Microsoft Authenticator, SMS, Software OATH, and Email enabled.
4. Admin consent request workflow is disabled, so app consent governance should be explicitly reviewed before production cleanup/readiness claims.

## Safety notes

Do not perform any of these from this confirmation alone:

- enable or disable security defaults;
- change authentication method states;
- enable admin consent requests;
- grant or revoke application consent;
- change Conditional Access policies.

This closes the read-evidence gap. It is not a license to go poking auth policy buttons like a caffeinated intern.
