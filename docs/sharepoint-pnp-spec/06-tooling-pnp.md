# 06 — PnP and SharePoint Tooling

## Toolchain summary

| Layer | Choice | Version | Why |
|---|---|---|---|
| Site provisioning | **PnP.PowerShell** | 3.x latest | Microsoft-supported; covers 95% of provisioning needs without SPFx. |
| Page authoring | PnP provisioning templates (XML or JSON) | n/a | Versioned, idempotent, diff-able. |
| Token pipeline | **Style Dictionary** | 5.3.3 | Already adopted by mega brief; generates CSS, SCSS, JSON, TS. |
| Component library | **Fluent UI v9** | `@fluentui/react-components` latest | Microsoft's design system; SharePoint-native. |
| SPFx | **1.22.2** (deferred) | n/a | Heavy tier; use only when Medium can't paint the picture. |
| SPFx runtime | Node 22 LTS, React 17.0.1, TypeScript 5.3.3 | exact pins | Per mega brief; deviation will break builds. |
| Testing — UI | **Playwright** | 1.58.x | Multi-browser; same as `deltacrown.com` test stack. |
| Testing — a11y | **axe-core** + **pa11y-ci** | 4.11 / 4.1 | WCAG 2.2 AA + AAA where named. |
| Visual regression | Playwright snapshots | (built-in) | Free; integrates with existing Playwright config. |
| CI | **GitHub Actions** | hosted runners | Same surface as other repos. |
| Deploy | PnP cmdlets run from CI with cert-based app-only auth | n/a | No interactive auth in CI. |

## PnP.PowerShell — required cmdlets we lean on

| Cmdlet | Use |
|---|---|
| `Connect-PnPOnline` | Auth (cert-based for CI; device-code for local) |
| `Get-PnPSite` / `Get-PnPWeb` | Inspection |
| `Get-PnPSiteTemplate` | Export current state as a template |
| `Invoke-PnPSiteTemplate` | Apply template (idempotent) |
| `Add-PnPPage` / `Set-PnPPage` | Page CRUD |
| `Add-PnPPageWebPart` | Add a web part to a page |
| `Set-PnPListPermission` | Library / list ACLs |
| `Set-PnPSiteGroup` | SharePoint group membership |
| `Get-PnPNavigationNode` / `Add-PnPNavigationNode` | Nav config |
| `Set-PnPWebTheme` | Apply tenant theme |
| `Set-PnPHubSite` | Hub site config |
| `Add-PnPHubSiteAssociation` | Associate spoke to hub |

## Authentication models

Three modes, used in three contexts.

### Mode A — Device code (developer local)

```powershell
Connect-PnPOnline -Url https://deltacrown.sharepoint.com/sites/dce-hub `
                  -Interactive `
                  -ClientId <app-id>
```

For exploration, debugging, manual fixes.

### Mode B — App-only with certificate (CI)

```powershell
Connect-PnPOnline -Url https://deltacrown.sharepoint.com/sites/dce-hub `
                  -ClientId <app-id> `
                  -Tenant deltacrown.onmicrosoft.com `
                  -CertificatePath ./cert.pfx `
                  -CertificatePassword (ConvertTo-SecureString -String $env:CERT_PASS -AsPlainText -Force)
```

For GitHub Actions deploys. Cert + password stored in repo secrets;
the public cert is uploaded to the Entra app registration.

### Mode C — Managed identity (Azure-hosted runner, future)

If we move CI to Azure DevOps pipelines or self-hosted Azure runner,
we use managed identity. Not in scope for v1.

## App registration spec

One Entra app registration in DCE tenant. Name:
`dce-sharepoint-deploy`.

| Permission (Microsoft Graph) | Type | Why |
|---|---|---|
| `Sites.FullControl.All` | Application | Provision sites, apply templates |
| `User.Read.All` | Application | Audience-targeting lookups |
| `Group.Read.All` | Application | Group membership queries |
| `Directory.Read.All` | Application | Cross-tenant user lookups |

| Permission (SharePoint) | Type | Why |
|---|---|---|
| `Sites.FullControl.All` | Application | PnP site/web operations |
| `TermStore.ReadWrite.All` | Application | Managed-metadata configuration (future) |

**Admin consent required.** Tyler grants once at registration time.

Cert config:

- Generate cert via OpenSSL (no Azure Key Vault dependency for v1).
- Upload public `.cer` to the app registration.
- Store `.pfx` + password in GitHub repo secrets (`DCE_DEPLOY_PFX`,
  `DCE_DEPLOY_PFX_PASSWORD`).
- Rotate annually.

## Style Dictionary configuration

The token pipeline lives in the new `dce-sharepoint` repo at
`tokens/`. Configuration:

```javascript
// style-dictionary.config.js
module.exports = {
  source: ['tokens/**/*.json'],
  platforms: {
    css: {
      transformGroup: 'css',
      buildPath: 'dist/css/',
      files: [{
        destination: 'dce-tokens.css',
        format: 'css/variables',
        options: { outputReferences: true }
      }]
    },
    fluent: {
      transformGroup: 'js',
      buildPath: 'dist/fluent/',
      files: [{
        destination: 'fluentui-theme-dce.json',
        format: 'json/fluentui-v9'  // custom format defined in tooling
      }]
    },
    sharepoint: {
      transformGroup: 'js',
      buildPath: 'dist/sharepoint/',
      files: [{
        destination: 'theme.json',
        format: 'json/sharepoint-theme'  // custom format
      }]
    }
  }
};
```

The custom formats (`json/fluentui-v9`, `json/sharepoint-theme`) live
in `tooling/style-dictionary-formats.js` and are unit tested.

## `sharepointagent/` reuse

The Python toolkit at `/Users/tygranlund/dev/01-htt-brands/sharepointagent/`
provides:

- `audit_folder_permissions.py` — recursive permission audit.
- `audit_recursive_deep.py` — full-site audit.
- `analyze_tll_site.py` — pattern for per-brand analysis.

We reuse these for:

1. The weekly permission-audit GitHub Action (see
   `05-permissions-model.md`).
2. The Phase-5 cross-brand audit (each brand gets a Python script
   modeled on `analyze_tll_site.py`).

We do NOT port these to PowerShell — Python is fine for read-only
audits.

## SharePoint-specific gotchas

### Gotcha 1: Page web-part GUIDs

When using `Add-PnPPageWebPart -DefaultWebPartType`, the cmdlet maps
common types to their GUIDs. Custom Microsoft web parts have known
GUIDs (e.g., the Hero web part is
`c4bd7b2f-7b6e-4599-8485-16504575f590`). Keep a reference list in
`reference/sharepoint-webpart-guids.md`.

### Gotcha 2: Hub theme propagation

Applying a theme to a hub site doesn't automatically update associated
sites that were created before the theme was set. Use
`Invoke-PnPHubSiteAssociation -Url <spoke> -HubSiteId <hub-id>` after
applying theme to force re-propagation.

### Gotcha 3: Cross-tenant Graph queries from PnP

PnP is single-tenant. For HTT user lookups during DCE audience
targeting, use Microsoft Graph directly (we have the `az` CLI flow
working).

### Gotcha 4: `Invoke-PnPSiteTemplate` is idempotent BUT...

It's "idempotent" in that re-applying a template doesn't create
duplicates. But it does NOT remove things that were present in a prior
template and removed from the current one. Removal requires explicit
cmdlets. We document this in `10-runbooks.md`.

## Versioning the templates

Each PnP template (XML or JSON) is committed to the repo. Schema:

```
dce-sharepoint/
└── templates/
    ├── hub/
    │   ├── 001-initial-provisioning.xml
    │   ├── 002-add-people-page.xml
    │   └── ...
    ├── crown-connection/
    │   └── 001-home-page.xml
    └── brand-center/
        └── 001-initial-provisioning.xml
```

Sequential numbering. Each template is the **delta** from the prior
state, not a full re-provisioning. This makes diffs trivial in PRs.

Templates 001 capture the "from scratch" state. Templates 002+ are
incremental.
