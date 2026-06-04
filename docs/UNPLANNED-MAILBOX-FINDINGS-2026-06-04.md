# Unplanned Mailbox Findings — Delta Crown Extensions

> **Date:** 2026-06-04  
> **Auditor:** code-puppy-c70339 (Richard)  
> **Method:** Live Exchange Online audit via delegated admin auth  
> **Status:** Documented for future alignment with DCE team. **No action taken.**

---

## Summary

Three mailboxes and one transport rule were discovered during the 2026-06-04 fresh inventory that were not in the original DCE deployment plan, any prior documentation, or our session prep. Based on the creation patterns, forwarding logic, and associated transport rule, these were created by a user with admin access to the tenant in the last 3 days (June 1–4, 2026).

**Decision:** Document and defer. These will be reviewed with the Delta Crown team once the planned email/Freshdesk infrastructure is complete.

---

## Item 1: careers@deltacrown.com

| Property | Value |
|---|---|
| **Display Name** | Delta Crown Careers |
| **Type** | SharedMailbox |
| **Created** | 2026-06-04 09:28:49 CT |
| **Modified** | 2026-06-04 09:29:51 CT |
| **Hidden from GAL** | No |
| **Size** | 14.56 KB |
| **Items** | 4 |
| **Forwarding** | `smtp:Help@deltacrown.com` |
| **Forward + Deliver** | Yes (keeps copy, also forwards) |
| **Auto-Reply** | Disabled |
| **Send-As** | None granted |
| **Full Access** | None granted |

### Interpretation
Someone created a careers intake mailbox and immediately configured it to forward to `help@deltacrown.com`. This is functionally aligned with our support model — job applications land in the same queue as support tickets. The person who created this understood the forwarding pattern.

### Question for DCE team alignment
- Is `careers@` the permanent careers intake, or should it route to a specific HR contact instead of the general help desk?
- Should it have an auto-reply acknowledging receipt of application?
- Who should have Full Access / Send-As?

---

## Item 2: noreply@deltacrown.com

| Property | Value |
|---|---|
| **Display Name** | No Reply - DCE |
| **Type** | SharedMailbox |
| **Created** | 2026-06-03 16:13:35 CT |
| **Modified** | 2026-06-03 16:14:01 CT |
| **Hidden from GAL** | No |
| **Size** | 16.56 KB |
| **Items** | 4 |
| **Forwarding** | None |
| **Auto-Reply** | Disabled |
| **Send-As** | None granted |
| **Full Access** | None granted |

### Associated Transport Rule

| Property | Value |
|---|---|
| **Name** | No Reply Mailbox Blocker |
| **State** | **Disabled** |
| **Priority** | 0 (highest) |
| **Description** | If message is sent to `noreply@deltacrown.com`, reject with status `5.7.1` and text: "This mailbox does not receive messages." |
| **When Changed** | 2026-06-03 16:22:46 CT |

### Interpretation
The mailbox and transport rule were created together on June 3. The rule was created 9 minutes after the mailbox (4:13 PM → 4:22 PM). The intent is clear: `noreply@` is for outbound system emails only, and any replies to it should be rejected. **The rule is currently DISABLED** — so replies to noreply@ are NOT being blocked right now.

### Question for DCE team alignment
- Should the blocking rule be enabled?
- Is `noreply@` actively used by any system (MindBody, website, marketing automation)?
- Should it be hidden from the GAL?

---

## Item 3: ColoradoSprings@deltacrown.com

| Property | Value |
|---|---|
| **Display Name** | Delta Crown Colorado Springs |
| **Type** | UserMailbox |
| **Created** | 2026-06-01 13:54:20 CT |
| **Modified** | 2026-06-01 13:58:49 CT |
| **Hidden from GAL** | No |
| **Size** | 180.5 KB |
| **Items** | 6 |
| **Last Logon** | 2026-06-01 19:18:03 CT (same day) |
| **Forwarding** | None |
| **Auto-Reply** | Disabled |

### Interpretation
This is a **UserMailbox** (not SharedMailbox), meaning it consumes a license and represents a real person or service account. It was created on June 1 and someone logged in 5.5 hours later. The name suggests it's tied to a Colorado Springs studio/location. It has actual email content (180 KB, 6 items), so it's actively used.

### Question for DCE team alignment
- Is this a real person (e.g., Colorado Springs studio manager) or a service account?
- Should it be a SharedMailbox instead (if it's a role, not a person)?
- Does the Colorado Springs location need its own email, or should it use a shared regional mailbox?
- Is this user part of the `ColoradoSprings` location that appeared in the mailbox name?

---

## Cross-Timeline

| Time (CT) | Event |
|---|---|
| 2026-06-01 13:54 | `ColoradoSprings@` created |
| 2026-06-01 19:18 | `ColoradoSprings@` logged in |
| 2026-06-03 16:13 | `noreply@` created |
| 2026-06-03 16:22 | "No Reply Mailbox Blocker" rule created (disabled) |
| 2026-06-04 09:28 | `careers@` created |
| 2026-06-04 09:29 | `careers@` forwarding to `help@` configured |
| 2026-06-04 15:53 | Our `bookings@` → `help@` migration executed |
| 2026-06-04 15:54 | `help@` converted to SharedMailbox |

---

## Recommendations (for future DCE team review)

1. **careers@** — Decide if this stays as-is, gets dedicated HR routing, or merges into `help@` permanently.
2. **noreply@** — Decide if the blocking rule should be enabled, and whether the mailbox should be hidden from GAL.
3. **ColoradoSprings@** — Determine if this is a person or a role; if it's a role, convert to SharedMailbox and free the license.
4. **General** — Establish a change-control process for mailbox creation in the DCE tenant (who can create, who approves, who documents).

---

*Documented, not modified. These items remain as discovered. Revisit with the DCE team after planned email/Freshdesk infrastructure is complete.*
