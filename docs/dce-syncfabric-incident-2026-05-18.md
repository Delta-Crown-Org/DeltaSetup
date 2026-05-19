# DCE SyncFabric admin guest deletion incident — 2026-05-18

## Summary

DCE audit logs showed multiple HTT-origin guest users were soft-deleted by
Microsoft sync infrastructure at `2026-05-18T20:45:04Z`.

Most critical impacted user:

```text
tyler.granlund-admin_httbrands.com#EXT#@deltacrown.onmicrosoft.com
```

The deleted Tyler admin object was restored and verified as Global
Administrator.

## Root cause evidence

DCE target-side audit:

```text
activity: Delete user
initiatedBy.app.displayName: Microsoft.Azure.SyncFabric
servicePrincipalId: 5898e41f-861b-4adf-a917-2f48653948d5
result: success
```

HTT source-side sync app:

```text
Display name: CTSync-HTT-to-DCE
Service principal ID: 1f074621-8bcd-4d9e-b27e-4470afeedba1
App ID: 9c8934a1-658d-4bab-b7a1-a1a11593a203
Template: Azure2Azure
Target CompanyId: ce62e17d-2feb-4e67-a115-8ea4af68da30
Schedule: PT40M
```

Sync scope:

```text
Group: SG-DCE-Sync-Users
Group ID: 6f5cc75e-b2ae-4ed2-992d-e56d4e3ef5f3
SyncAll: false
```

Critical membership finding:

```text
tyler.granlund@httbrands.com       IN  SG-DCE-Sync-Users
tyler.granlund-admin@httbrands.com OUT SG-DCE-Sync-Users
```

The admin account being out-of-scope explains why SyncFabric considered the DCE
admin guest unentitled and soft-deleted it.

## Actions completed

1. Authenticated to DCE as `tyler.granlund@httbrands.com`.
2. Verified that DCE guest has Global Administrator.
3. Restored deleted object:

   ```text
   Object ID: 13023522-0166-4e0d-b588-b89fa092aaca
   UPN: tyler.granlund-admin_httbrands.com#EXT#@deltacrown.onmicrosoft.com
   Mail: tyler.granlund-admin@httbrands.com
   ```

4. Verified restored admin guest:

   ```text
   accountEnabled: true
   userType: Member
   role: Global Administrator
   ```

5. Paused the dangerous HTT-to-DCE sync job:

   ```text
   CTSync-HTT-to-DCE
   schedule.state: Paused
   status: Paused
   ```

## Source-tenant remediation completed

Temporary bridge fix completed in HTT: directly assigned the HTT admin source
account to the sync application.

```text
User: tyler.granlund-admin@httbrands.com
Principal ID: e1dfb17f-b695-4dad-92c0-20e26ce069ab
Application: CTSync-HTT-to-DCE
Resource ID: 1f074621-8bcd-4d9e-b27e-4470afeedba1
App role: f6c6d802-6e08-48ef-89a8-79b4dd1c346e
Created: 2026-05-18T23:53:23.7393052Z
```

This bypasses the stale dynamic group evaluator while still making the account
explicitly entitled for the Azure2Azure sync app.

DCE target-side audit after the direct assignment showed SyncFabric restoring
the target user:

```text
2026-05-18T23:53:41.8769887Z
activity: Restore user
initiatedBy.app.displayName: Microsoft.Azure.SyncFabric
result: success
objectId: 13023522-0166-4e0d-b588-b89fa092aaca
```

A following `Update user` audit row reported
`Microsoft.Online.Workflows.EmailDomainValidationException`, but the object was
confirmed active afterward and Global Administrator membership remained intact.

Current sync state after bridge fix:

```text
CTSync-HTT-to-DCE schedule.state: Active
CTSync-HTT-to-DCE status: Active
```

## Other impacted users requiring owner decision

Same-second target-side DCE soft deletes also included:

```text
kristin.kidd-admin_httbrands.com#EXT#@deltacrown.onmicrosoft.com
dustin.boyd-admin_httbrands.com#EXT#@deltacrown.onmicrosoft.com
AccountsPayable_httbrands.com#EXT#@deltacrown.onmicrosoft.com
```

Do not restore or add these back to sync scope without owner approval.

## Prevention

- Keep break-glass/admin accounts explicitly in or explicitly out of sync scope.
- If they are out of scope, do not allow sync to manage/delete their target
  objects.
- Add a canary that checks privileged DCE guest existence and GA role assignment.
- Review delete-threshold settings. Current sync secret shows:

  ```json
  {"Enabled":false,"DeleteThresholdEnabled":true,"HumanResourcesLookaheadQueryEnabled":false,"DeleteThresholdValue":500}
  ```
