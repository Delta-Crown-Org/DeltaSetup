# Phase 1: Pax8 CSP — Azure Subscription & Licensing

## Overview

Delta Crown Extensions needs an Azure subscription (`DCE-CORE`) associated with the DCE tenant. Since we use **Pax8** as our Cloud Solution Provider (CSP), all subscription provisioning and license management goes through them.

## Prerequisites

- [ ] Global Admin access on the DCE tenant (`deltacrown.com`)
- [ ] Active Pax8 CSP relationship with your organization
- [ ] Pax8 partner portal access (or contact email for your Pax8 account manager)

## Step 1: Submit CSP Request to Pax8

Use the pre-written template at [`templates/pax8-csp-request.md`](../templates/pax8-csp-request.md).

This request covers:
1. **Azure Subscription Creation**: Named `DCE-CORE`, linked to the DCE tenant
2. **License Verification**: Confirm existing Business Premium license pool and allocation
3. **Billing Alignment**: Ensure the subscription is billed through the existing CSP agreement

## Step 2: Accept CSP Relationship in DCE Tenant

After Pax8 processes the request:

1. Sign into [Azure Portal](https://portal.azure.com) as DCE Global Admin
2. You may receive an **admin consent link** from Pax8 — accept the CSP relationship
3. Navigate to **Subscriptions** → Verify `DCE-CORE` appears
4. Navigate to **Cost Management + Billing** → Verify billing is through Pax8/CSP

## Step 3: Configure Subscription Basics

Once `DCE-CORE` is active:

1. **Create initial Resource Group**:
   ```powershell
   Connect-AzAccount -TenantId "ce62e17d-2feb-4e67-a115-8ea4af68da30"
   Set-AzContext -SubscriptionName "DCE-CORE"
   New-AzResourceGroup -Name "rg-dce-core-001" -Location "centralus"
   ```

2. **Set up Cost Management alerts**:
   - Navigate to **Cost Management → Budgets → + Add**
   - Budget name: `DCE-CORE-Monthly`
   - Amount: Set an appropriate threshold (e.g., $100/month to start)
   - Alert at: 50%, 80%, 100%
   - Notify: Your admin email

3. **Apply resource tags**:
   ```powershell
   $tags = @{
       "Environment" = "Production"
       "CostCenter"  = "DeltaCrown"
       "ManagedBy"   = "t-granlund"
   }
   Set-AzResourceGroup -Name "rg-dce-core-001" -Tag $tags
   ```

## Step 4: Verify License Allocation

While working with Pax8, confirm:

| License | Tenant | Quantity | Notes |
|---------|--------|----------|-------|
| Microsoft 365 Business Premium | HTT Brands | Current count | Primary user licenses |
| Microsoft 365 Business Premium | DCE | As needed | For users needing full DCE mailbox (optional) |

**Key Point**: For the shared mailbox approach (Phase 4), synced users do **NOT** need a separate license in DCE. Only request DCE licenses if specific users need a dedicated @deltacrown.com user mailbox.

## Validation Checklist

- [ ] `DCE-CORE` subscription visible in Azure Portal under DCE tenant
- [ ] Resource group `rg-dce-core-001` created successfully
- [ ] Budget alert configured
- [ ] Pax8 billing confirmed on existing CSP agreement
- [ ] License allocation reviewed and documented
