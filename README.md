# Delta Crown Extensions — Tenant Setup & Onboarding

> **Repository for tracking and automating the setup of the Delta Crown Extensions (DCE) Microsoft 365 tenant, Azure subscription, cross-tenant user onboarding, and email configuration.**

## 🏢 Tenant Overview

| Tenant | Domain | Org ID | Role |
|--------|--------|--------|------|
| **Head to Toe Brands** | `httbrands.com` | `0c0e35dc-188a-4eb3-b8ba-61752154b407` | Source (parent org) |
| **Delta Crown Extensions** | `deltacrown.com` | `ce62e17d-2feb-4e67-a115-8ea4af68da30` | Target (new tenant) |

## 🎯 Objectives

1. **Azure Subscription**: Establish the `DCE-CORE` Azure subscription under the DCE tenant via Pax8 CSP
2. **User Onboarding**: Sync users from HTT Brands → DCE using Entra ID Cross-Tenant Synchronization (member-type, not guest)
3. **Collaboration**: Set up SharePoint sites, Teams, and Microsoft 365 Groups for DCE
4. **Email**: Enable HTT Brands users to send from `@deltacrown.com` using shared mailboxes + Send-As (zero additional licensing cost)
5. **Security**: Configure SPF/DKIM/DMARC, Conditional Access policies, and MFA trust

## 📋 Phase Roadmap

| Phase | Description | Status | Docs |
|-------|-------------|--------|------|
| 1 | Pax8 CSP — Azure Subscription & Licensing | ⬜ Not Started | [docs/01-pax8-csp-subscription-setup.md](docs/01-pax8-csp-subscription-setup.md) |
| 2 | Cross-Tenant Sync Configuration | ⬜ Not Started | [docs/02-cross-tenant-sync-setup.md](docs/02-cross-tenant-sync-setup.md) |
| 3 | SharePoint, Teams & Groups | ⬜ Not Started | [docs/03-sharepoint-teams-groups.md](docs/03-sharepoint-teams-groups.md) |
| 4 | Email — Shared Mailboxes & Send-As | ⬜ Not Started | [docs/04-email-shared-mailboxes.md](docs/04-email-shared-mailboxes.md) |
| 5 | DNS — SPF/DKIM/DMARC | ✅ Live (hardening remaining) | [docs/05-dns-spf-dkim-dmarc.md](docs/05-dns-spf-dkim-dmarc.md) |
| 6 | Conditional Access & Security | ⬜ Not Started | [docs/06-conditional-access-security.md](docs/06-conditional-access-security.md) |
| 7 | Validation & UAT | ⬜ Not Started | [docs/07-validation-checklist.md](docs/07-validation-checklist.md) |

## 💰 Cost Strategy

| Item | Cost | Notes |
|------|------|-------|
| Cross-Tenant Sync | **$0** | Included with Entra ID (Business Premium includes P1) |
| Shared Mailboxes | **$0** | Free with Exchange Online, no license needed |
| Send-As Permissions | **$0** | Exchange Online built-in feature |
| SPF/DKIM/DMARC | **$0** | DNS record changes only |
| DCE-CORE Azure Sub | **Pay-as-you-go** | Only for Azure resources actually provisioned |

## 🛠️ Automation Scripts

All PowerShell scripts are in [`scripts/`](scripts/). See [`scripts/README.md`](scripts/README.md) for prerequisites and execution order.

## 📄 Templates

- [`templates/pax8-csp-request.md`](templates/pax8-csp-request.md) — Pre-written request for your Pax8 CSP
- [`templates/user-welcome-email.html`](templates/user-welcome-email.html) — Welcome email for onboarded users
- [`templates/user-onboarding-checklist.md`](templates/user-onboarding-checklist.md) — Per-user onboarding steps

## 📂 Config

- [`config/tenant-config.json`](config/tenant-config.json) — Tenant IDs, domains (no secrets)
- [`config/sync-attribute-mappings.json`](config/sync-attribute-mappings.json) — Cross-tenant sync attribute map
- [`config/mailbox-provisioning.csv`](config/mailbox-provisioning.csv) — User → shared mailbox mapping

## ⚠️ Important Notes

- **No secrets in this repo** — all credentials use interactive auth or Azure Key Vault
- **Business Premium licensing** is already in place — this plan avoids any additional per-user costs
- **Pax8 is the CSP** — all subscription and license procurement goes through them
- **Cross-tenant sync creates Member-type accounts** (not Guests) for full SharePoint/Teams access
