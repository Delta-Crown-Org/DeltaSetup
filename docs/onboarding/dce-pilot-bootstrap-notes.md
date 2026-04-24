# DCE Pilot Bootstrap Notes

## Purpose
This note explains the assumptions used to pre-fill the onboarding matrices so Tyler can start from a concrete dataset instead of a blank spreadsheet-shaped void.

## Seeded users
The first-pass user matrix includes:
- Tyler Granlund (`tyler.granlund@httbrands.com`) — cross-tenant pilot
- Lindy Sturgill (`lindy.sturgill@deltacrown.com`)
- Allynn Shepherd (`allynn.shepherd@deltacrown.com`)
- Jay Miller (`jay.miller@deltacrown.com`)
- Sarah Miller (`sarah.miller@deltacrown.com`)

These four native DCE users came from `phase3-week2/EXCHANGE-QUICKSTART.md`.

## Seeded location codes
The matrices are pre-filled using these initial codes:
- `DCE-LV`
- `DCE-PHX`
- `DCE-DAL`

These are starter codes only. Replace or expand them to match the actual DCE operating footprint.

## Assumption policy
Some user role/department/location values were not explicitly present in the repo.
Where that happened, the matrices use **first-pass assumptions** based on:
- current SharePoint site architecture
- current Teams/channel structure
- current Exchange group/mailbox model
- the need to validate at least one leadership pilot path and one non-leadership path

## What must be confirmed before production use
Before using the matrix as authoritative truth, confirm for each user:
- actual job title
- actual functional role
- actual primary location
- actual owned locations
- whether leadership access is really intended
- whether mailbox/app assignments are correct

## Recommended first pilot
Use Tyler as the first pilot with:
- `officeLocation = DCE-LV`
- `extensionAttribute1 = Leadership`
- `extensionAttribute2 = DCE-LV`
- `extensionAttribute3 = DCE-CrossTenant-Test`

That gives a good test of:
- cross-tenant admission
- synced object existence
- baseline group assignment
- leadership access
- location access
- positive and negative access validation
