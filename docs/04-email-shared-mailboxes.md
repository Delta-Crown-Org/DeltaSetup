# Phase 4: Email — Shared Mailboxes & Send-As for @deltacrown.com

## Overview

Enable HTT Brands users to send email **from @deltacrown.com addresses** at zero additional cost. We use **shared mailboxes** (free, no license required) with **Send-As** permissions.

## Cost: $0
Shared mailboxes are included with Exchange Online at no additional license cost (up to 50 GB per mailbox).

## Prerequisites

- [ ] Cross-tenant sync complete (Phase 2) — users exist in DCE tenant
- [ ] Exchange Online active in DCE tenant
- [ ] Exchange Admin or Global Admin on DCE tenant

## How It Works

```
HTT Brands User (john@httbrands.com)
    │
    ├── Cross-Tenant Sync → Exists as Member in DCE tenant
    │
    ├── Granted "Full Access" → Shared mailbox auto-maps in Outlook
    │
    ├── Granted "Send As" → Can select @deltacrown.com in From field
    │
    └── Sends email as john@deltacrown.com ✅
        (No additional license needed)
```

## Step 1: Plan Shared Mailboxes

Populate [`config/mailbox-provisioning.csv`](../config/mailbox-provisioning.csv) with the mapping:

```csv
DisplayName,SharedMailboxEmail,SendAsUser,FullAccessUser
John Smith - DCE,john.smith@deltacrown.com,john.smith@httbrands.com,john.smith@httbrands.com
Jane Doe - DCE,jane.doe@deltacrown.com,jane.doe@httbrands.com,jane.doe@httbrands.com
DCE Info,info@deltacrown.com,john.smith@httbrands.com;jane.doe@httbrands.com,john.smith@httbrands.com;jane.doe@httbrands.com
DCE Support,support@deltacrown.com,john.smith@httbrands.com,john.smith@httbrands.com
```

## Step 2: Create Shared Mailboxes

> **Portal**: [Exchange Admin Center](https://admin.exchange.microsoft.com) → DCE tenant → Mailboxes

### Via Portal:
1. Go to **Recipients → Mailboxes → + Add a shared mailbox**
2. Display name: `John Smith - DCE`
3. Email: `john.smith@deltacrown.com`
4. Click **Create**
5. Repeat for each entry in the CSV

### Via PowerShell (Recommended — see `scripts/04-Create-SharedMailboxes.ps1`):
```powershell
Connect-ExchangeOnline -Organization deltacrown.com
New-Mailbox -Shared -Name "John Smith - DCE" -PrimarySmtpAddress "john.smith@deltacrown.com"
```

## Step 3: Grant Permissions

### Send-As Permission
Allows the user to send email **as** the shared mailbox address (recipients see `john.smith@deltacrown.com` as the sender):

```powershell
# The -Trustee is the synced user's identity in the DCE tenant
Add-RecipientPermission "john.smith@deltacrown.com" `
    -AccessRights SendAs `
    -Trustee "john.smith_httbrands.com#EXT#@deltacrownonmicrosoft.com" `
    -Confirm:$false
```

> **Note**: The synced user's UPN in the DCE tenant may follow the format `user_sourcedomain#EXT#@targetdomain.onmicrosoft.com`. Check the actual UPN in Entra ID → Users after sync.

### Full Access Permission
Allows the shared mailbox to **auto-map** into the user's Outlook:

```powershell
Add-MailboxPermission "john.smith@deltacrown.com" `
    -User "john.smith_httbrands.com#EXT#@deltacrownonmicrosoft.com" `
    -AccessRights FullAccess `
    -AutoMapping $true
```

## Step 4: User Experience

### In Outlook Desktop:
1. The shared mailbox appears automatically in the left folder pane (due to AutoMapping)
2. To send from @deltacrown.com:
   - Click **New Email**
   - Click **From** → **Other Email Address**
   - Select the shared mailbox address (e.g., `john.smith@deltacrown.com`)
   - Compose and send

### In Outlook Web (OWA):
1. Click **New mail**
2. Click **From** → Select the shared mailbox
3. If not visible, click **Other email address** and type the shared mailbox address

### In Outlook Mobile:
1. Go to **Settings → Add Account** (add the shared mailbox as a linked account)
2. When composing, tap **From** to switch sender

## Step 5: Verify Send-As Works

1. User sends a test email from `john.smith@deltacrown.com` to an external Gmail
2. In Gmail: Open email → Check sender shows `john.smith@deltacrown.com`
3. Click **Show original** → Verify headers (after DNS Phase 5):
   - `From: john.smith@deltacrown.com`
   - `Return-Path: john.smith@deltacrown.com`

## Important Notes

- **50 GB limit**: Shared mailboxes are free up to 50 GB. If exceeded, a license is required. Monitor usage.
- **No direct sign-in**: Users cannot sign into a shared mailbox directly — they access it via permissions
- **Litigation hold**: If you need retention/compliance holds on shared mailboxes, a license is required
- **Auto-mapping delay**: After granting Full Access, auto-mapping can take 30-60 minutes to appear in Outlook

## Validation Checklist

- [ ] All shared mailboxes created per `config/mailbox-provisioning.csv`
- [ ] Send-As permissions granted for each user
- [ ] Full Access permissions granted with AutoMapping
- [ ] User can see shared mailbox in Outlook
- [ ] User can send email from @deltacrown.com
- [ ] External recipient receives email with correct From address
