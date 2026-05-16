# 07 — CI/CD Pipeline (Medium tier — PnP + GitHub Actions)

## Architecture

```
Developer pushes to feature branch
         │
         ▼
   GitHub PR opens
         │
         ▼
  GitHub Actions: PR validation
   ├── style-dictionary build (token sanity)
   ├── PnP template syntax check
   ├── Playwright smoke test (against dev site)
   ├── axe-core a11y audit
   └── Visual regression diff
         │
         ▼ (pass)
   Reviewer approves + merges to main
         │
         ▼
   GitHub Actions: main deploy
   ├── style-dictionary build → publish artifacts
   ├── Apply PnP templates to PROD via cert-auth
   ├── Run post-deploy smoke
   └── Notify Teams channel
```

## Repository structure (recommended)

A new repo `Delta-Crown-Org/dce-sharepoint` with this layout:

```
dce-sharepoint/
├── .github/
│   └── workflows/
│       ├── pr-validation.yml     ← runs on every PR
│       ├── deploy-prod.yml       ← runs on push to main
│       ├── deploy-dev.yml        ← manual + on push to develop
│       ├── permission-audit.yml  ← weekly cron
│       └── token-build.yml       ← runs on tokens/ changes
├── README.md
├── AGENTS.md                     ← copy from DeltaSetup
├── tokens/                       ← Style Dictionary source
│   ├── dce-tokens.json
│   ├── global.json
│   └── components.json
├── templates/                    ← PnP provisioning templates
│   ├── hub/
│   ├── crown-connection/
│   └── brand-center/
├── pages/                        ← Page content as JSON/XML
│   ├── hub-home.json
│   ├── hub-about.json
│   └── crown-connection-home.json
├── webparts/                     ← (future) SPFx web parts
├── tooling/
│   ├── style-dictionary-formats.js
│   ├── pnp-helpers.ps1
│   └── theme-generator.js
├── tests/
│   ├── playwright/
│   │   └── smoke.spec.ts
│   ├── accessibility/
│   │   └── axe.config.js
│   └── visual/
│       └── snapshots/
├── scripts/
│   ├── bootstrap.sh              ← one-shot dev setup
│   ├── deploy-dev.ps1
│   ├── deploy-prod.ps1
│   └── permission-audit.py
├── docs/
│   └── (link back to DeltaSetup spec pack)
├── package.json
├── style-dictionary.config.js
└── .gitignore
```

## GitHub Actions workflows

### Workflow 1 — PR validation (`.github/workflows/pr-validation.yml`)

```yaml
name: PR validation

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm ci

      - name: Build tokens
        run: npx style-dictionary build

      - name: Validate PnP template syntax
        shell: pwsh
        run: |
          Install-Module PnP.PowerShell -Force -SkipPublisherCheck
          Get-ChildItem templates -Recurse -Filter *.xml | ForEach-Object {
            Test-PnPSiteTemplate -Path $_.FullName
          }

      - name: Playwright smoke test (dev site)
        env:
          DEV_SITE_URL: ${{ secrets.DCE_DEV_SITE_URL }}
          DEV_USER: ${{ secrets.DCE_DEV_USER }}
          DEV_PASS: ${{ secrets.DCE_DEV_PASS }}
        run: |
          npx playwright install --with-deps
          npx playwright test --project=chromium tests/playwright/smoke.spec.ts

      - name: Accessibility audit
        run: npx pa11y-ci --config tests/accessibility/pa11y-ci.json

      - name: Visual regression
        run: npx playwright test tests/visual --update-snapshots=false
```

### Workflow 2 — Deploy to PROD (`.github/workflows/deploy-prod.yml`)

```yaml
name: Deploy to PROD

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: deploy-prod
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm ci

      - name: Build tokens
        run: npx style-dictionary build

      - name: Restore deployment cert
        shell: pwsh
        run: |
          $bytes = [Convert]::FromBase64String($env:DCE_DEPLOY_PFX)
          [IO.File]::WriteAllBytes('./cert.pfx', $bytes)
        env:
          DCE_DEPLOY_PFX: ${{ secrets.DCE_DEPLOY_PFX }}

      - name: Connect and apply templates
        shell: pwsh
        env:
          CLIENT_ID:    ${{ secrets.DCE_DEPLOY_CLIENT_ID }}
          TENANT:       ${{ secrets.DCE_TENANT_DOMAIN }}
          CERT_PASS:    ${{ secrets.DCE_DEPLOY_PFX_PASSWORD }}
        run: |
          Install-Module PnP.PowerShell -Force -SkipPublisherCheck
          ./scripts/deploy-prod.ps1

      - name: Post-deploy smoke
        env:
          PROD_SITE_URL: https://deltacrown.sharepoint.com/sites/dce-hub
        run: npx playwright test --project=chromium tests/playwright/smoke.spec.ts

      - name: Notify Teams
        uses: aliencube/microsoft-teams-actions@v0.8.0
        if: always()
        with:
          webhook_uri: ${{ secrets.TEAMS_DEPLOY_WEBHOOK }}
          title: "DCE SharePoint deploy ${{ job.status }}"
          summary: "main → PROD deploy completed: ${{ job.status }}"
```

### Workflow 3 — Permission audit (`.github/workflows/permission-audit.yml`)

```yaml
name: Permission audit

on:
  schedule:
    - cron: '0 6 * * 1'   # Mondays 06:00 UTC
  workflow_dispatch:

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install requests msal

      - name: Run permission audit
        env:
          DCE_DEPLOY_CLIENT_ID:    ${{ secrets.DCE_DEPLOY_CLIENT_ID }}
          DCE_DEPLOY_CLIENT_CERT:  ${{ secrets.DCE_DEPLOY_PFX }}
          DCE_TENANT_DOMAIN:       ${{ secrets.DCE_TENANT_DOMAIN }}
        run: python scripts/permission-audit.py

      - name: Upload audit artifact
        uses: actions/upload-artifact@v4
        with:
          name: permission-audit-${{ github.run_id }}
          path: out/permission-audit-*.csv

      - name: Post to Teams if drift detected
        if: hashFiles('out/drift-detected.txt') != ''
        run: ./scripts/notify-drift.sh
```

## Environment model

Two environments (Dev / Prod) to start. Optionally add UAT later.

| Env | Site URL | Source branch | Deploy trigger | Audience |
|---|---|---|---|---|
| Dev | `https://deltacrown.sharepoint.com/sites/dce-hub-dev` | `develop` | Push to develop | Tyler, Jamie, Jenna (build squad) |
| Prod | `https://deltacrown.sharepoint.com/sites/dce-hub` | `main` | Push to main, manual approval | All R1-R6 |

Dev site is a separate site collection at `/sites/dce-hub-dev`. Same
template, same theme, different content. We provision it via the same
pipeline with a `target=dev` flag.

## Secrets inventory

Repo secrets to populate (one-time, by Tyler):

| Secret | Value | Source |
|---|---|---|
| `DCE_DEPLOY_CLIENT_ID` | Entra app ID | Created in 09-deployment |
| `DCE_DEPLOY_PFX` | Base64-encoded `.pfx` cert | Generated by `scripts/bootstrap.sh` |
| `DCE_DEPLOY_PFX_PASSWORD` | Cert password | Generated; printed once |
| `DCE_TENANT_DOMAIN` | `deltacrown.onmicrosoft.com` | Static |
| `DCE_DEV_SITE_URL` | `https://deltacrown.sharepoint.com/sites/dce-hub-dev` | Static |
| `DCE_DEV_USER` | Service account UPN (for browser auth in tests) | Created |
| `DCE_DEV_PASS` | Service account password | Created |
| `TEAMS_DEPLOY_WEBHOOK` | Incoming webhook URL | Configured in Teams |

## Rollback strategy

PnP templates are forward-only (no automatic "undo"). Rollback options:

1. **Re-apply previous template.** Each template numbered 001, 002,
   003... Re-applying 001+002 after a bad 003 reverts most state.
2. **Site backup.** Before every PROD deploy, the workflow exports
   `Get-PnPSiteTemplate -Out ./backups/<timestamp>.xml`. Stored as
   workflow artifact for 90 days.
3. **Last resort: SharePoint built-in recycle bin.** 93 days
   retention; only covers deleted items, not config changes.

Document the rollback runbook in `10-runbooks.md`.

## Build artifacts

After every successful main build:

- `dist/css/dce-tokens.css` — CSS variables
- `dist/fluent/fluentui-theme-dce.json` — Fluent UI theme
- `dist/sharepoint/theme.json` — SharePoint Admin Center theme
- `backups/<timestamp>.xml` — pre-deploy site snapshot
- `out/permission-audit-<timestamp>.csv` — weekly audit output

All artifacts retained for 90 days.

## Observability

- **Build status badge** in `dce-sharepoint/README.md`.
- **Deploy dashboard** on the Hub Admin page (R1/R2 only) showing
  last deploy timestamp + status.
- **Teams notifications** on every deploy (success or fail).
- **Email alerts** on consecutive failures (3+ failures = email Tyler).
