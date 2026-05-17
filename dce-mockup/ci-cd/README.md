# CI/CD pipeline reference

This folder contains the GitHub Actions workflows, deploy scripts, bootstrap,
audit script, and Teams provisioning config that together comprise the
**Medium-tier** CI/CD pipeline described in
`docs/sharepoint-pnp-spec/07-ci-cd-pipeline.md`.

When you stand up `Delta-Crown-Org/dce-sharepoint`, copy this entire folder
into the repo root (the `.github/workflows/` files go under `.github/workflows/`,
everything else under `scripts/` and `teams/`).

## Layout

```
ci-cd/
├── workflows/
│   ├── pr-validation.yml      ← runs on every PR to main
│   ├── deploy-prod.yml        ← runs on push to main, requires "prod" environment approval
│   ├── permission-audit.yml   ← weekly cron, drift-detection
│   └── provision-teams.yml    ← when teams/ config changes
├── scripts/
│   ├── bootstrap.sh           ← ONE-SHOT app reg + cert + secrets (idempotent)
│   ├── deploy-prod.ps1        ← PnP template + page application
│   ├── permission-audit.py    ← wraps sharepointagent audit lib
│   └── provision-teams.ps1    ← applies channelModerationSettings via Graph
└── teams/
    └── dce-channels.json      ← desired moderation state per channel
```

## Quick-start (fresh engineer, target ≤1 hour to first deploy)

```bash
# 1. Clone the repo + install toolchain
gh repo clone Delta-Crown-Org/dce-sharepoint
cd dce-sharepoint
nvm install 22 && nvm use 22
npm ci

# 2. Bootstrap the Entra app + cert + secrets (run once, idempotent)
./scripts/bootstrap.sh

# 3. Add the printed secrets to GitHub repo settings → Secrets
# (the script lists exactly what to paste)

# 4. Push a trivial change to a feature branch + open a PR
#    → pr-validation.yml runs
#    → reviewer approves + merges
#    → deploy-prod.yml runs (requires "prod" environment approval)

# Time-to-first-deploy goal: < 1 hour after secrets are populated.
```

## Secrets required (GitHub repo → Settings → Secrets)

| Secret | Source | Notes |
|---|---|---|
| `DCE_DEPLOY_CLIENT_ID` | `bootstrap.sh` output | Entra app id |
| `DCE_DEPLOY_PFX` | `bootstrap.sh` output (base64) | Cert private key |
| `DCE_DEPLOY_PFX_PASSWORD` | `bootstrap.sh` output | Generated random |
| `DCE_TENANT_DOMAIN` | static | `deltacrown.onmicrosoft.com` |
| `DCE_DEV_SITE_URL` | static | `https://deltacrown.sharepoint.com/sites/dce-hub-dev` |
| `DCE_DEV_USER` | service account | for Playwright smoke tests |
| `DCE_DEV_PASS` | service account | rotate quarterly |
| `TEAMS_DEPLOY_WEBHOOK` | Teams → Connectors | for deploy notifications |
| `SMTP_USER` / `SMTP_PASSWORD` | M365 service account | for audit failure alerts |

## Permission philosophy

Per `05-permissions-model.md`:
- **Inherit unless documented.** Breaks live in `reference/permission-breaks.csv`.
- `permission-audit.yml` runs weekly, cross-references actual state vs. that CSV.
- Drift = an item with `HasUniqueRoleAssignments=true` not in the CSV → Teams alert + email.

## Reuse map

- `bootstrap.sh` & `deploy-prod.ps1`: pattern adapted from
  `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/spfx/deploy-spfx.ps1`
- `permission-audit.py`: wraps
  `/Users/tygranlund/dev/01-htt-brands/sharepointagent/audit_folder_permissions.py`
- Cross-tenant ops: `/Users/tygranlund/dev/04-other-orgs/DeltaSetup/tools/connect-exo-cross-tenant.md`
  documents the EXO cross-tenant auth pattern reused here.

## Rollback

PnP templates are forward-only. To revert:
1. Pull the pre-deploy snapshot artifact from the failed/regressed run (90-day retention).
2. Re-apply the previous numbered template (e.g., revert 003 by reapplying 001+002).
3. Last resort: SharePoint recycle bin (93-day retention; only deleted items, not config).
