# Duplicate Delta Crown Extensions Microsoft 365 Groups Review

## Audit status

Completed a read-only review of the two Microsoft 365 / Unified groups with display name `Delta Crown Extensions`.

Tenant:

```text
deltacrown.com / ce62e17d-2feb-4e67-a115-8ea4af68da30
```

Method:

```bash
python3 phase4-migration/scripts/review-delta-crown-duplicate-groups.py
```

Raw local outputs:

```text
.local/reports/tenant-inventory/duplicate-delta-crown-groups/duplicate-groups-summary.json
.local/reports/tenant-inventory/duplicate-delta-crown-groups/duplicate-groups.csv
.local/reports/tenant-inventory/duplicate-delta-crown-groups/*-members.csv
.local/reports/tenant-inventory/duplicate-delta-crown-groups/*-owners.csv
.local/reports/tenant-inventory/duplicate-delta-crown-groups/*-lists.csv
```

Raw outputs are local-only because they contain user/member/owner details.

No groups, Teams, sites, members, owners, or permissions were changed.

## Summary

Two Microsoft 365 groups share the same display name:

```text
Delta Crown Extensions
```

Both are:

- Microsoft 365 / Unified groups;
- mail-enabled;
- public;
- Teams-provisioned according to `resourceProvisioningOptions = Team`;
- connected to distinct SharePoint sites;
- populated with the same member and owner sets.

## Group comparison

| Group ID | Mail | Created | Visibility | Teams-provisioned | Members | Owners | SharePoint site |
|---|---|---:|---|---|---:|---:|---|
| `dca7a24a-00ed-49c0-be67-80a9c163492c` | `DeltaCrownExtensions@deltacrown.com` | 2026-03-05 18:56:23Z | Public | Yes | 86 | 4 | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions` |
| `1af8cb12-e2b4-4608-80e0-e4f60d2a2557` | `DeltaCrownExtensions379@deltacrown.com` | 2026-03-05 18:58:18Z | Public | Yes | 86 | 4 | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions379` |

## Overlap

| Comparison | Result |
|---|---:|
| Member overlap | 86 / 86 |
| Owner overlap | 4 / 4 |

Interpretation:

- The two groups currently have identical membership from Graph evidence.
- They appear to be near-simultaneous duplicate Teams/M365 group creations rather than distinct role groups.
- Because both are Teams-provisioned, direct Teams/channel dependency review is still required before deletion or archival.

## Member metadata shape

Both duplicate groups have the same member metadata distribution:

| Metadata area | Count / shape |
|---|---:|
| Total members | 86 |
| User type | 86 members |
| `companyName = Delta Crown Extensions` | 6 |
| Missing `companyName` | 80 |
| Job title populated | 44 |
| Disabled users | 0 |

Top department values in both groups:

| Department value | Count |
|---|---:|
| Missing | 41 |
| HTT Brands Corporate | 34 |
| Franchise Development | 2 |
| Franchisee | 2 |
| Corporate | 1 |
| Franchise Devlopment  | 1 |
| IT | 1 |
| Operations | 1 |

Yes, `Franchise Devlopment ` appears misspelled/space-suffixed in live metadata. Delightful little data gremlin.

## SharePoint dependency evidence

Distinct group-connected SharePoint sites exist:

| Mail | Site URL | Site created | Last modified |
|---|---|---:|---:|
| `DeltaCrownExtensions@deltacrown.com` | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions` | 2026-03-09 16:16:38Z | 2026-04-30 18:41:49Z |
| `DeltaCrownExtensions379@deltacrown.com` | `https://deltacrown.sharepoint.com/sites/DeltaCrownExtensions379` | 2026-04-02 14:17:52Z | 2026-04-30 18:41:48Z |

Each site currently has one visible document library from Graph list evidence.

PnP inventory already confirmed these are distinct group-connected sites and should not be deleted until Teams/M365 dependencies are reviewed.

## Risk assessment

| Risk | Why it matters | Severity |
|---|---|---|
| Duplicate display names | Owners/users/admins cannot reliably distinguish the two groups in Teams, SharePoint, Entra, or access reviews. | Medium |
| Both Teams-provisioned | A deletion may remove Team/channel data if the wrong group is selected. | High |
| Identical membership/owners | Suggests one is redundant, but does not prove one is unused. | Medium |
| Public visibility | Both may be discoverable/joinable depending tenant settings and Teams behavior. | Medium |
| Metadata gaps | Only 6/86 members have DCE company metadata, complicating access cleanup decisions. | Medium |

## Recommendation

Do **not** delete either group yet.

Recommended sequence:

1. Complete Teams/channel inventory once `DeltaSetup-151` provides licensed Teams-readable access or owner attestation.
2. Determine which group/team is canonical for the public showcase or production operating model.
3. Rename the non-canonical duplicate first, for example:

   ```text
   Delta Crown Extensions - Review Duplicate 2026-04
   ```

4. Leave the renamed duplicate in place through a short observation window.
5. Confirm no Teams, SharePoint, mail, app, or owner workflow depends on the renamed duplicate.
6. Only then decide whether to archive/delete the duplicate group/team/site.

This is boring. Boring is good. Boring prevents deleting the wrong Team and earning a tiny clown nose.

## Decision needed

Owner/admin decision required:

| Question | Recommendation |
|---|---|
| Which group is canonical? | Defer until Teams/channel inventory or owner attestation confirms active usage. |
| Should one be renamed now? | Yes, after owner approval, because duplicate display names create ongoing ambiguity. |
| Should one be deleted now? | No. Teams-provisioned dependency risk is too high without Teams visibility. |

## Safety notes

Do not perform any of these from this review alone:

- delete either Microsoft 365 group;
- delete either connected SharePoint site;
- archive either Team;
- remove members or owners;
- change visibility;
- rename without owner approval;
- migrate files between the two sites.

This review narrows the problem: the duplicates are real, heavily overlapping, and likely redundant, but Teams dependency evidence is still the gate.
