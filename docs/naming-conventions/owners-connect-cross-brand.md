# Owners-Connect Group/Site Cross-Brand Naming Convention

**Status:** Draft — adopted for Delta Crown Extensions launch 2026-05-15;
needs Kristin / leadership sign-off before retroactive rename of TLL / Bishops /
Frenchies sites.

**Author:** Tyler Granlund / code-puppy-1bc20e
**Last updated:** 2026-05-15

---

## 1. Why this exists

Each HTT brand currently has a Microsoft 365 Group + SharePoint site that
serves as the "place where franchise owners / managers connect," but the
groups were created in three different years by three different people and
have **three different naming patterns**:

| Brand | Display name | mailNickname (internal) | Primary SMTP | SharePoint URL | Visibility | Created |
|---|---|---|---|---|---|---|
| Frenchies | Studio Connection | `OwnerConnection` | `StudioConnection@frenchiesnails.com` | `/sites/StudioConnection` | Private | 2025-07-25 |
| Bishops | Connect | `Connect` | `Connect@bishops.co` | `/sites/ConnectNow` | Public | 2022-06-15 |
| The Lash Lounge | TLL Owners Group | `TLLOwnersGroup` | `TLLOwnersGroup@TheLashLounge.com` | `/sites/TLLOwnersGroup` | Private | 2020-04-29 |

Problems with the current state:

1. **No predictable address.** Cross-brand transport rules and templates
   can't programmatically route to "the owner-connect group of brand X."
2. **Internal vs external naming drift.** Frenchies's mailNickname is
   `OwnerConnection` but the display + primary is `StudioConnection`. That's
   the result of a rename, not a deliberate design. Maintenance reads have
   to know both names.
3. **Inconsistent membership semantics.** TLL is owner-only (11 members);
   Frenchies and Bishops are franchisees-+-staff (119 / 134 members).
   "Owners-connect site" means different things in different brands today.
4. **Inconsistent visibility / Team-enablement.** Public vs Private varies;
   one is Team-enabled, two are not.
5. **No alias for cross-brand parity.** If we want one address shape that
   resolves in every brand (e.g. `OwnerConnection@<brand-domain>`), only
   Frenchies has it today.

## 2. Canonical pattern (the spec)

For every HTT brand that has franchise owners, the brand tenant SHALL host
exactly one Microsoft 365 Group that:

| Concern | Standard |
|---|---|
| **Object type** | Microsoft 365 Group (Unified). Not Team-enabled at provision time. Team-enable on demand if/when the brand needs Teams chat surface. |
| **Visibility** | `Private`. Discovery should require explicit invite. (Bishops's Public state is a legacy outlier and should be reviewed for cleanup.) |
| **Display name** | `<Brand Word> Connection` where `<Brand Word>` is the brand's everyday short noun (Crown, Studio, etc.). |
| **mailNickname (internal alias)** | `<BrandWord>Connection` (PascalCase, no spaces). |
| **Primary SMTP** | `<BrandWord>Connection@<brand-domain>` |
| **Required alias** | `OwnerConnection@<brand-domain>` so any cross-brand template can mail-route to the owners-connect surface uniformly. |
| **Tenant-routing alias** | `OwnerConnection@<brand>.onmicrosoft.com` for service-routing / Exchange Online identity hygiene. |
| **Site URL** | `https://<brand>.sharepoint.com/sites/<BrandWord>Connection` |
| **Description** | `The place for <Brand>'s owners to connect.` (consistent voice across brands; replaces the four current variants.) |
| **Membership scope at launch** | Franchise owners only (Owner-titled users). Managers, lead extensionistas, corporate, etc. live in a different group. |
| **Owners (of the group)** | The brand's IT admin + one operations leader (e.g. Tyler + Kristin for HTT brands). Owners can manage membership without needing tenant-wide privileges. |
| **Sensitivity label** | None for now. Revisit when Purview labels are deployed. |
| **External sharing** | Disabled. Owners-connect is internal/franchisee-only. |
| **Naming policy** | If the tenant has a `PrefixSuffixNamingRequirement` policy, this group is in scope (or gets an exemption via `groupSettings`, depending on what policy the tenant has). |

## 3. Applied to Delta Crown Extensions (launched 2026-05-15)

| Field | Value |
|---|---|
| Group id | `11e4f2da-c468-4b81-9a18-46d883099a62` |
| Display name | Crown Connection |
| mailNickname | `CrownConnection` |
| Primary SMTP | `CrownConnection@deltacrown.com` |
| Required alias | `OwnerConnection@deltacrown.com` |
| Tenant-routing alias | `OwnerConnection@deltacrown.onmicrosoft.com` |
| Site URL | `https://deltacrown.sharepoint.com/sites/CrownConnection` |
| Visibility | Private |
| Description | The place for Crown Extension Studio Owners to connect. |
| Owners | Tyler Granlund - Admin (DCE guest) |
| Members at launch | Sarah Miller, Jay Miller, Allynn Shepherd, Amit Shah, Toni Careccia |

## 4. Retroactive cleanup for existing brands

Tracked separately — see follow-up bd issue. Each brand needs:

### 4.1 Frenchies (FN)

- Add `OwnerConnection@frenchiesnails.com` as **primary** (already exists as
  alias). Demote `StudioConnection@frenchiesnails.com` to alias OR keep as
  the human-friendly display. **Decision needed:** does Frenchies want to be
  the model exception (display = "Studio Connection") or does it conform to
  the spec (display = "Studio Connection", primary = `OwnerConnection@`)?
- Confirm visibility is Private (already is).
- Membership reconciliation: scope is broader than owners-only. Either (a)
  rename group to acknowledge that ("Studio Network" / "Studio Connection"
  + spec-exception note), or (b) split owners off into a tighter group.

### 4.2 Bishops (BCC)

- **Visibility:** Currently `Public`. Confirm whether that's deliberate
  (Connect = "Franchisees and staff" social channel) or whether it should
  go Private.
- **Primary SMTP:** `Connect@bishops.co` — too generic. Recommend rename to
  `OwnerConnection@bishops.co` OR add the alias and leave the display alone.
- **Site URL:** `/sites/ConnectNow` doesn't match the display name. Could
  rename SP URL to `/sites/Connect` for parity, but that breaks any existing
  bookmarks — handle as part of a coordinated migration.

### 4.3 TLL

- Add `OwnerConnection@TheLashLounge.com` as alias on `TLLOwnersGroup`.
- Display name already matches the spec spirit ("TLL Owners Group"). Could
  rename to "TLL Connection" for cross-brand parallel but that's cosmetic.
- Membership scope (owner-only) already matches the spec.

### 4.4 HTT corporate

HTT corporate doesn't have franchisees, so no owners-connect group. The
corporate equivalents (executive distros, etc.) are governed by a different
spec (TBD) and are out of scope here.

## 5. Open questions

1. Does Kristin want the retroactive cleanup of Frenchies / Bishops / TLL
   to happen, or are the legacy names sticky enough to leave alone? If
   we're only enforcing the spec going forward, that's fine but it should
   be a deliberate choice.
2. Should the "managers" tier get its own parallel group/site
   (`<BrandWord>Managers` / `ManagerConnection@<brand>`)? Current state:
   no consistent pattern; managers either live in the owners-connect site
   (Frenchies) or get no dedicated surface (TLL, DCE, BCC).
3. Should the owners-connect site auto-Team-enable when membership crosses
   some threshold (e.g. >20 owners)? Frenchies and Bishops did not
   Team-enable; TLL did (`Private team`).

## 6. References

- Existing brand patterns observed in
  `~/dev/groups-audit/scripts/output/2026-05-06_161042/groups-summary.csv`.
- Audit/architecture docs:
  `~/dev/groups-audit/docs/architecture/groups-audit-architecture.md`,
  `~/dev/groups-audit/docs/adr/0002-remove-legacy-sender-allowlists-franchisee-lists.md`.
- DCE launch evidence:
  `.local/reports/friday-sharepoint-hub-audit/20260515T2143*-crown-connection-*.json`.
