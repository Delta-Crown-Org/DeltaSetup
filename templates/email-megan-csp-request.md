**Subject:** Delta Crown Extensions (DCE) Tenant Setup — Pax8 CSP + Licensing Needed

---

Hi Megan,

I wanted to give you a quick update on the Delta Crown Extensions (DCE) tenant setup and outline what we need from you to move forward.

### What's Done

The DCE Microsoft 365 tenant (deltacrown.com) has been created and configured:

- **Entra ID directory** is live at deltacrown.com
- **Cross-tenant sync** is running — all 260 HTT Brands users are syncing into the DCE directory as Member-type identities
- **Your admin access** is set up — you have Global Administrator rights in the DCE tenant. You can sign in at [entra.microsoft.com](https://entra.microsoft.com) and switch to "Delta Crown Extensions" from the tenant switcher
- **DNS records** (SPF, DKIM, DMARC) for deltacrown.com are live and verified

### What We Need

To finish the setup, we need three things through Pax8:

**1. Establish the CSP relationship for the DCE tenant**
Set up the Pax8 CSP (Cloud Solution Provider) partner relationship for the Delta Crown Extensions tenant (Tenant ID: `ce62e17d-2feb-4e67-a115-8ea4af68da30`, domain: deltacrown.com). This is the same type of relationship we have for HTT Brands.

**2. Create an Azure subscription called "DCE-CORE"**
Once the CSP relationship is established, we need an Azure subscription created for this tenant. If I'm able to do this myself once you establish the relationship, just let me know and I can handle it — otherwise please name it **DCE-CORE**.

**3. Provision one M365 Business license for Lindy Sturgill**
We need to set up **Lindy Sturgill** (lindy.sturgill@deltacrown.com) as the first native DCE user with a mailbox. For the license SKU:

- **M365 Business Basic** ($6/user/mo, going to $7 in July 2026) — email, Teams, and web apps. This is sufficient if Lindy only needs email and collaboration.
- **M365 Business Premium** ($22/user/mo, price unchanged in July) — includes everything in Basic plus desktop Office apps, Intune device management, and Defender for Office 365 P2. This is what we use for managers at the other brands.
- **M365 Copilot Business add-on** ($18/user/mo on top of a qualifying plan) — if we want to include Copilot AI features. Currently discounted to $18 from $21 through the end of March. Note: this is a separate add-on, not a standalone plan.

My recommendation: **Business Basic** for now to keep costs minimal, since the primary purpose of this user is to activate Exchange Online on the DCE tenant. We can always upgrade later. But if you want to match what we do for managers at the other brands, go with **Business Premium**.

### Why This Matters

Once Exchange Online is active on the DCE tenant (which happens as soon as we have one licensed mailbox user), I can set up **shared mailboxes** for any HTT Brands team member at @deltacrown.com — at no additional per-user cost. For example:

- Jenna Bowden will be able to send and receive email as **jenna.bowden@deltacrown.com** directly from her existing Outlook
- This works through shared mailbox delegation — Jenna's synced identity in DCE gets Send-As and Full Access permissions on her @deltacrown.com shared mailbox
- She just clicks "From" in Outlook and selects the @deltacrown.com address
- No extra licenses needed for the shared mailboxes — only Lindy's native user license is required to activate the service

This same setup scales to any corporate team member who needs to send from both @httbrands.com and @deltacrown.com.

### Timeline

Once the CSP relationship and Lindy's license are in place, I can have the shared mailboxes created and tested within the same day. Everything else is already configured and waiting.

Let me know if you have any questions or need anything from me to get started.

Thanks,
Tyler
