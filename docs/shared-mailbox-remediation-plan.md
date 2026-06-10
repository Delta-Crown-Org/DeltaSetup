# Shared Mailbox Compliance — DCE Remediation Plan

**Date:** 2026-06-10
**Prepared by:** Tyler Granlund (IT) + Richard (code-puppy-30de1e)
**Audience:** DCE Operations team, Dustin Boyd (licensing)
**Beads:** DeltaSetup-1ke, DeltaSetup-dez

---

## The Short Version

We found a licensed user mailbox that should be a shared mailbox.
Converting it takes less than five minutes.
It does not require any user action or workflow change.
If anything below is incorrect, just let us know.

---

## What We Found

The `deltacrown` Microsoft 365 tenant has a mailbox called:

> **`ColoradoSprings@deltacrown.com`**

This mailbox is currently configured as a **User Mailbox with an active Business Premium
license attached.** A Business Premium license costs roughly **$22/user/month**.

This is almost certainly not the intent. A center contact address like
`ColoradoSprings@deltacrown.com` is designed to be shared by multiple people
(the on-site manager, the owner, future staff). That is precisely what
Microsoft 365 **Shared Mailboxes** exist for.

---

## Why This Matters

| | User Mailbox (current) | Shared Mailbox (correct) |
|---|---|---|
| **License required** | Yes — Business Premium ($22/mo) | No — completely free |
| **Can multiple people access it** | No (designed for one person) | Yes — as many delegates as needed |
| **Can multiple people send FROM it** | No (only the licensed user) | Yes — any delegate with Send As |
| **Supported by Microsoft for shared access** | No — violates Microsoft terms for shared accounts | Yes — this is exactly what it is designed for |
| **Audit risk** | Individual-user licensing assigned to a shared address = licensing non-compliance | Clean, compliant, correct |

**In plain terms:** using a licensed user mailbox as a shared team inbox is the same
pattern we have seen cause problems at The Lash Lounge — where multiple "shared" accounts
are each burning a Business Premium license that should not exist. The right tool for
a shared team inbox is always a Shared Mailbox, full stop.

---

## What We Plan to Do

Convert `ColoradoSprings@deltacrown.com` from a User Mailbox to a Shared Mailbox.

**Steps:**
1. Identify who currently has access to `ColoradoSprings@deltacrown.com`
   (Full Access delegations — likely Lindy Sturgill and/or the center team).
2. Convert the mailbox type from `UserMailbox` to `SharedMailbox` via Exchange Online.
3. Remove the Business Premium license from the account (it is no longer needed).
4. Re-grant Full Access and Send As permissions to the same people as before
   (this is a one-time step; permissions survive the conversion).
5. Verify the mailbox is accessible from Outlook by the delegates.

**Time required:** Less than 10 minutes.
**User disruption:** None. Delegates lose access for approximately 30 seconds
during the conversion and regain it automatically.
**Billing impact:** One Business Premium license freed up (~$22/month).

---

## The Dry-Run Command (no changes yet)

```powershell
# DRY-RUN — shows current state, no changes
# Run to confirm before Tyler arms the approval file

Connect-ExchangeOnline -UserPrincipalName tyler.granlund-admin@httbrands.com `
    -DelegatedOrganization deltacrown.onmicrosoft.com

# Check current mailbox type
Get-Mailbox -Identity "ColoradoSprings@deltacrown.com" |
    Select-Object DisplayName, RecipientTypeDetails, UserPrincipalName

# Check who has access
Get-MailboxPermission -Identity "ColoradoSprings@deltacrown.com" |
    Where-Object { $_.AccessRights -eq "FullAccess" -and -not $_.IsInherited }

# Check send-as permissions
Get-RecipientPermission -Identity "ColoradoSprings@deltacrown.com" |
    Where-Object { $_.AccessRights -eq "SendAs" -and $_.Trustee -ne "NT AUTHORITY\SELF" }
```

Once Tyler reviews the output and confirms, Richard runs the live conversion:

```powershell
# LIVE — only runs after Tyler creates approvals/exchange-cos-mailbox-conversion.txt

Set-Mailbox -Identity "ColoradoSprings@deltacrown.com" -Type Shared
# Then remove license from the corresponding Entra account
```

---

## What We Need From the DCE Operations Team

Before we convert, please confirm:

1. **Who should have access to `ColoradoSprings@deltacrown.com`?**
   (Names or email addresses — we will grant them Full Access and Send As after conversion.)
   Our current assumption is: Lindy Sturgill and/or Jenna Bowden.

2. **Is `ColoradoSprings@deltacrown.com` actively used as a real inbox today,
   or is it dormant?**
   (If dormant, we may archive it instead of converting.)

3. **Are there any automated systems, Zenoti notifications, or booking confirmation
   emails that send TO or FROM `ColoradoSprings@deltacrown.com`?**
   (If yes, we need to verify those still work after conversion — they will, but we
   want to give you a heads-up.)

If everything above is correct as we have described it, simply reply "looks right, go ahead"
and we will run the conversion.

---

## The Lash Lounge Parallel — A Pattern to Watch

This is not unique to Delta Crown. The Lash Lounge currently has multiple accounts
in a similar configuration — shared-use addresses provisioned as licensed user mailboxes
rather than Shared Mailboxes. This is a common result of provisioning shortcuts taken
during initial tenant setup.

The fix is always the same:
- Identify the shared-use mailboxes.
- Convert them to Shared Mailboxes.
- Remove the unnecessary licenses.
- Grant the right team members Full Access + Send As.

We will flag the same pattern in any HTT brand tenant where we identify it.
The licensing savings and compliance improvement are straightforward wins.

---

## See Also

- `tools/provision-jenna-dce-mailbox.ps1` — Related: Jenna Bowden's
  `jenna.bowden@deltacrown.com` SharedMailbox provision + Send As grant
- `DeltaSetup-1ke` — Bead tracking this remediation
- `DeltaSetup-dez` — Bead tracking Jenna's mailbox provision
