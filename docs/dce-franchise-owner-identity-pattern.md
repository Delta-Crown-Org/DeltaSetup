# DCE Franchise Owner Identity Pattern

**Date:** 2026-06-10
**Author:** Richard (`code-puppy-30de1e`)
**Bead:** `DeltaSetup-dez`
**Status:** PROPOSAL — awaiting Tyler approval before any Entra write

---

## Problem

Delta Crown Extensions has (at least) one franchise owner whose authoritative identity lives
entirely outside the DCE tenant:

| Person | Center | DCE identity? | @deltacrown.com mailbox? | In franchise_owners@ DDG? |
|--------|--------|---------------|--------------------------|---------------------------|
| Jenna Bowden | Colorado Springs | HTT corp guest only | NO | NO |

Jamie Baer confirmed on 2026-06-09 that Jenna Bowden is the COS owner of record.
Lindy Sturgill is the on-site operator/Salon Manager, NOT the owner.

Because Jenna has no `@deltacrown.com` mailbox:
- She does NOT appear in the `franchise_owners@deltacrown.com` Dynamic Distribution Group.
- She does NOT appear in any of the Entra dynamic security groups (AllStaff, Managers, etc.)
  — this is by design per Tyler's May 19 decision (groups stay DCE-tenant only).
- Her ownership is NOT captured anywhere in the current Entra/Exchange state.

The only system that currently reflects Jenna as COS owner is the
`generated/dce-franchise-owners-report.csv` / `.md` produced by this repo.

---

## Proposed Pattern: `extensionAttribute1` on the HTT Guest Record

Set a managed attribute on Jenna's DCE cross-tenant guest object to make her
ownership visible in Entra without granting a license or a DCE mailbox:

```
extensionAttribute1 = "DCE Owner of Record | Center: Colorado Springs"
```

### Why `extensionAttribute1`?

- It is an on-premise extension attribute that survives cross-tenant guest object
  updates (not overwritten by sync cycles).
- It is searchable in Graph (`/users?$filter=extensionAttribute1 eq '...'`).
- It does not grant any license, mailbox, or group membership.
- It is the same pattern used in the pre-approved `Apply-DceMetadataPopulation.ps1`
  framework (which already writes `companyName`, `department`, `jobTitle`, `employeeType`).

### Scope

Apply this ONLY to DCE-specific ownership attributes. Do NOT modify any attribute
that is sourced from the HTT home tenant (those would be overwritten by SyncFabric).
`extensionAttribute1` is safe because it is set at the DCE-tenant guest object level
and is NOT a SyncFabric-managed attribute.

---

## Dry-Run Scaffold (do NOT execute without Tyler approval)

```powershell
# DRY-RUN — shows what WOULD be written, no changes made
# Target: Jenna Bowden's DCE cross-tenant guest object
# Object ID (DCE tenant): 26e9afa6-3e1b-4830-b0c6-68eceba42781
# UPN (DCE ext): Jenna.Bowden_httbrands.com#EXT#@deltacrown.onmicrosoft.com

$dryRun = $true   # flip to $false only after Tyler arms approval file

$objectId = "26e9afa6-3e1b-4830-b0c6-68eceba42781"
$patch = @{
    onPremisesExtensionAttributes = @{
        extensionAttribute1 = "DCE Owner of Record | Center: Colorado Springs"
    }
}

if ($dryRun) {
    Write-Host "[DRY-RUN] Would PATCH /users/$objectId"
    Write-Host ([System.Text.Json.JsonSerializer]::Serialize($patch))
} else {
    # Requires: Connect-MgGraph -Scopes "User.ReadWrite.All" -TenantId "ce62e17d-..."
    Update-MgUser -UserId $objectId -BodyParameter $patch
    Write-Host "Applied extensionAttribute1 to Jenna Bowden."
}
```

### Approval gate

Tyler must create a file `approvals/entra-jenna-bowden-extensionattribute1.txt` containing:

```
APPROVED: set extensionAttribute1 on Jenna.Bowden HTT guest (object 26e9afa6)
Date: YYYY-MM-DD
Tyler Granlund
```

Once that file exists, Richard can execute the live write.

---

## Extending the Pattern to Other HTT-Corp Owners

If future DCE centers are owned by HTT-corp identities (no @deltacrown.com mailbox),
apply the same pattern:

```
extensionAttribute1 = "DCE Owner of Record | Center: <center name>"
```

If an owner has both a DCE mailbox AND is an HTT employee (dual identity), prefer
populating the DCE-native record (`@deltacrown.com`) with `department=Franchisee`,
`jobTitle=Owner`, and `employeeType=Franchisee` — which puts them in the
`franchise_owners@` DDG automatically. The `extensionAttribute1` pattern is only
needed when there is NO DCE-native identity.

---

## Verification Query (after write)

```powershell
# Verify extensionAttribute1 was written
Connect-MgGraph -Scopes "User.Read.All" -TenantId "ce62e17d-2feb-4e67-a115-8ea4af68da30"

Get-MgUser -UserId "26e9afa6-3e1b-4830-b0c6-68eceba42781" `
    -Property "displayName,userPrincipalName,onPremisesExtensionAttributes" |
    Select-Object displayName, userPrincipalName,
        @{N="extensionAttribute1"; E={$_.AdditionalProperties.onPremisesExtensionAttributes.extensionAttribute1}}
```

Expected output after write:
```
displayName       userPrincipalName                                    extensionAttribute1
-----------       -----------------                                    --------------------
Jenna Bowden      Jenna.Bowden_httbrands.com#EXT#@deltacrown...       DCE Owner of Record | Center: Colorado Springs
```

---

## See Also

- `generated/dce-franchise-owners-report.md` — authoritative owners-of-record map
- `generated/dce-franchise-owners-report.csv` — Dustin's billing CSV
- `../visual-dashboard/Apply-DceMetadataPopulation.ps1` — pre-approved write pattern
- `DeltaSetup-dez` — bead tracking this work
- `DeltaSetup-de3` — parent Track 1 owner deliverable bead
