# Architecture Overview

## Tenant Relationship

```
┌─────────────────────────────────────────────────────┐
│              HEAD TO TOE BRANDS (Source)             │
│              httbrands.com                           │
│              Org ID: 0c0e35dc-...b407               │
│                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │   Users      │  │  M365 Biz    │  │  Exchange  │ │
│  │   (members)  │  │  Premium     │  │  Online    │ │
│  └──────┬───────┘  └──────────────┘  └────────────┘ │
│         │                                           │
└─────────┼───────────────────────────────────────────┘
          │
          │  Entra ID Cross-Tenant Sync
          │  (Member-type accounts, NOT guests)
          │
          ▼
┌─────────────────────────────────────────────────────┐
│           DELTA CROWN EXTENSIONS (Target)           │
│           deltacrown.com                            │
│           Org ID: ce62e17d-...da30                  │
│                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │  Synced      │  │  SharePoint  │  │  Shared    │ │
│  │  Users       │  │  + Teams     │  │  Mailboxes │ │
│  │  (members)   │  │              │  │  (free)    │ │
│  └─────────────┘  └──────────────┘  └────────────┘ │
│                                                     │
│  ┌─────────────────────────────────────────────────┐│
│  │  Azure Subscription: DCE-CORE                   ││
│  │  (Provisioned via Pax8 CSP)                     ││
│  └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Cross-Tenant Sync over B2B Guest Access
- **Decision**: Use Entra ID Cross-Tenant Synchronization to create **member-type** accounts in DCE
- **Rationale**: Members get full access to SharePoint, Teams, and other M365 services without the limitations of guest accounts (no "External" badges, full search, full Teams features)
- **Trade-off**: Synced users may need license assignment in DCE for full mailbox access. We mitigate this by using **shared mailboxes** (free) instead of licensed user mailboxes

### 2. Shared Mailboxes over Licensed Mailboxes
- **Decision**: Use shared mailboxes for @deltacrown.com email sending
- **Rationale**: Shared mailboxes are **free** (no license required, up to 50 GB). Users get Send-As permissions to send from @deltacrown.com addresses
- **Trade-off**: Users must select the "From" address manually in Outlook. Auto-mapping puts the shared mailbox in their Outlook automatically

### 3. Pax8 CSP for Procurement
- **Decision**: All Azure subscriptions and license changes go through Pax8 CSP
- **Rationale**: Existing CSP relationship; consolidated billing; CSP can manage subscription lifecycle
- **Action Required**: Submit the pre-written request in `templates/pax8-csp-request.md`

### 4. Zero Additional Per-User Cost
- **Decision**: No new per-user licenses for email sending capability
- **Rationale**: Business Premium is already paid for. Shared mailboxes + Send-As is included. Cross-tenant sync is included with Entra ID P1 (bundled in Business Premium)

## Security Architecture

- **MFA Trust**: DCE tenant trusts MFA claims from HTT Brands (no double-prompting)
- **Conditional Access**: Baseline policies applied in DCE tenant for synced users
- **SPF/DKIM/DMARC**: Full email authentication chain for deltacrown.com
- **No Secrets in Repo**: All scripts use interactive auth (`Connect-MgGraph`, `Connect-ExchangeOnline`)
