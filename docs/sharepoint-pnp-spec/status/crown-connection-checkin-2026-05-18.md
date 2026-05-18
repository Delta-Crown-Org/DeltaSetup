# Crown Connection check-in status — 2026-05-18

## Site URL

**Crown Connection:** <https://deltacrown.sharepoint.com/sites/CrownConnection>

Live SharePoint verification on 2026-05-18:

| Field | Value |
|---|---|
| Title | Crown Connection |
| URL | `https://deltacrown.sharepoint.com/sites/CrownConnection` |
| Web template | `GROUP` |
| Status | Active |

## Access state

Crown Connection is a private Microsoft 365 Group-backed SharePoint site.

Live Graph verification on 2026-05-18:

| Field | Value |
|---|---|
| Group display name | Crown Connection |
| Group ID | `11e4f2da-c468-4b81-9a18-46d883099a62` |
| Primary SMTP | `CrownConnection@deltacrown.com` |
| Visibility | Private |
| Group type | Unified / Microsoft 365 Group |
| Member count | 57 |

Current owners:

- Tyler Granlund - Admin — `tyler.granlund-admin@httbrands.com`
- Kristin Kidd — `Kristin.Kidd@httbrands.com`
- Jenna Bowden — `Jenna.Bowden@httbrands.com`
- Jamie Baer — `jamie.baer@httbrands.com`

Current access posture:

- Site exists and responds.
- Owners are assigned.
- Membership is populated for the current Crown Connection audience.
- Page/content build-out is not complete, but that is a content/design phase,
  not a blocker to sharing the URL.

## What is done

- Crown Connection site provisioned.
- Crown Connection Microsoft 365 Group exists and is private.
- Access expanded from initial DCE owner/franchisee launch set to broader HTT
  corporate-access set.
- Current live group member count is 57.
- DCE SharePoint repo exists and has quiet/scaffold provisioning tooling.
- DEV DCE Hub exists and has the DCE theme/logo path proven.
- No-secrets validation CI is active and green.

## Remaining setup work

Things we are competent to keep doing next:

1. **Crown Connection home page build** — tracked as `DeltaSetup-b59`.
   Content/page polish is still open, but the site URL/access exists now.
2. **DCE Hub home page build** — tracked as `DeltaSetup-8p5`.
3. **Brand/theme production rollout** — DEV is proven; production application is
   still intentionally gated.
4. **CI/CD hardening** — no-secrets validation is active; deploy/prod/launch
   workflows remain inactive until approval, secrets, and security gates are
   finished.
5. **ADR-011 security gates** — launch-mode stays blocked until security review,
   approval-gate fallback, retention mirror, credential lifecycle, and canaries
   are complete.
6. **Second-level access resilience** — deploy app now has Tyler + Dustin as
   owners; additional business-owner decisions can be added as needed.

## Boss-check-in one-liner

"Crown Connection is live at
`https://deltacrown.sharepoint.com/sites/CrownConnection`. Access is in place on
the private Microsoft 365 Group-backed site: 57 current members, with Tyler,
Kristin Kidd, Jenna Bowden, and Jamie Baer as owners. The page is not built out
yet, but the site and access are ready for use while we continue the branded
home page and pipeline hardening work."
