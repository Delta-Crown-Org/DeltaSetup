# Crown Connection — Team Status Update

**Date:** 2026-05-15
**From:** Tyler Granlund
**Status:** **READY** — site is live, all currently-licensed HTT corporate + DCE owners are in.

---

## TL;DR (for the team)

Per Kristin's SharePoint-launch ask, Delta Crown Extensions now has its
own owner/corporate-collab SharePoint site, modeled after the same
pattern Bishops, Frenchies, and The Lash Lounge already use for their
brands.

- **Name:** Crown Connection
- **URL:** <https://deltacrown.sharepoint.com/sites/CrownConnection>
- **Group email:** `CrownConnection@deltacrown.com`
- **Visibility:** Private
- **Status:** Live, fully populated, ready to use

You should see Crown Connection in your Outlook → Groups list and as a
followed site on SharePoint. If you don't see it within an hour, ping
Tyler.

---

## What got built

1. A new Microsoft 365 Group called **Crown Connection** in the Delta
   Crown Extensions tenant.
2. The group automatically provisions a SharePoint team site at the URL
   above (private, owner-only-modifiable, all members can read and post).
3. All licensed HTT Brands corporate users plus the 5 current DCE
   franchise owners were added as members.
4. Three leaders are set as group owners (full admin rights — add/remove
   members, change settings, etc.).

## Who has access

**Group owners (3):**

- Tyler Granlund (admin)
- Kristin Kidd
- Jenna Bowden

**Group members (57 total):**

- 5 DCE Franchise Owners (Allynn Shepherd, Amit Shah, Jay Miller, Sarah
  Miller, Toni Careccia)
- 52 HTT Brands corporate / licensed staff — every active licensed
  `@httbrands.com` mailbox as of tonight

This means 100% coverage of the audience Tyler defined. The 7 HTT users
that weren't in the DCE directory at the start of the night were invited
mid-session and are now full members.

## What this site is FOR

- Owner-to-owner peer collaboration.
- Leadership-direct comms to the DCE owner cohort.
- A place for HTT corporate stakeholders (Kristin, Meg, Erica, Joe, Jenna,
  Kayla, Daniel, etc.) to share resources, announcements, and reference
  material with the Delta Crown brand.
- Storage for owner-specific docs that shouldn't live in the broader
  staff operational hub.

## What this site is NOT

- Not the operational manual / day-to-day "how do I do my job" hub. That
  surface is the separate **DCE Hub** (`/sites/dce-hub`) which serves all
  staff (owners, managers, lead extensionistas, concierges,
  extensionistas) and is still being shaped by Jamie's working session
  the week of 5/18.
- Not auto-populated by HR or a sync job. Membership today is a
  point-in-time snapshot of HTT licensed users; new HTT hires will need
  to be added going forward (see "Operational handoff" below).

## Cross-brand context

| Brand | Equivalent site |
|---|---|
| Bishops | `Connect` (`Connect@bishops.co`) |
| Frenchies | `Studio Connection` (`StudioConnection@frenchiesnails.com`) |
| The Lash Lounge | `TLL Owners Group` (`TLLOwnersGroup@thelashlounge.com`) |
| Delta Crown Extensions | **`Crown Connection`** (`CrownConnection@deltacrown.com`) |

The naming spec we wrote up for future brand launches lives at
`docs/naming-conventions/owners-connect-cross-brand.md` — open to
feedback from Kristin before we apply it retroactively.

## Operational handoff — what we still need

These are not blockers for the launch comms, but they need owners.

1. **Process for new HTT hires** — HTT and DCE are NOT in a
   cross-tenant sync / Multi-Tenant Org relationship. The 52 HTT members
   are present in DCE because of a manual B2B invite event in March
   2026, plus tonight's targeted invites for 7 stragglers. **Every new
   HTT licensed hire will need a B2B invite to DCE as part of HR /
   onboarding**, otherwise they won't see Crown Connection or any other
   DCE-hosted resource. Filed as `DeltaSetup-cwn` for assignment to
   whoever owns HTT onboarding.
2. **Content** — site is bare bones (default M365 Group team site). No
   custom pages, no logo, no pinned links yet. Next steps belong to
   Jenna + Kristin once they decide what they want there.
3. **Optional: alias** — adding `OwnerConnection@deltacrown.com` as a
   secondary address for cross-brand template parity. Tracked as
   `DeltaSetup-yz2`. Not urgent.
4. **Optional: cross-brand cleanup** — Bishops/Frenchies/TLL sites all
   pre-date the spec; whether we retro-conform them is Kristin's call.
   Tracked as `DeltaSetup-69v`.

## Evidence pack

State snapshots and the actual API calls/scripts used live in the
DeltaSetup repo:

- `tools/provision-crown-connection.sh` — idempotent provisioning playbook
- `tools/expand-crown-connection-htt-corp.py` — idempotent membership
  expansion (the tool Tyler will re-run when new HTT hires happen)
- `.local/reports/friday-sharepoint-hub-audit/20260515T*-crown-connection-*.json`
  — pre-launch, post-launch, and full-coverage snapshots

Tracked under bd: `DeltaSetup-of8` (closed), with follow-ups
`DeltaSetup-cwn`, `DeltaSetup-yz2`, `DeltaSetup-69v`.
