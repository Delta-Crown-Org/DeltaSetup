# Site-request intake form + process (DRAFT — Phase 4 prep)

**Status:** Draft. Will migrate to `Delta-Crown-Org/dce-sharepoint/docs/operators/site-request-intake.md` when the `dce-sharepoint` repo lands (gated on `DeltaSetup-emj`).
**Companion runbook:** [`jenna-runbook-DRAFT.md`](./jenna-runbook-DRAFT.md) § 4.
**Source bd:** `DeltaSetup-9b8` (P2, Phase 4, pillar-adaptation).

> **🔴 ADR-011 invariant:** This intake process creates a `bd` issue but does NOT send a notification to the requester or anyone else until the operator (Jenna) explicitly closes the bd. The form acknowledges the submission with an on-screen message only. No "we received your request" email goes out. This is intentional — see ADR-011.

---

## 1. What this is and isn't

**This IS:** A lightweight intake mechanism so that anyone in the DCE ecosystem (owners, managers, HTT corp) can request a new SharePoint spoke site without DM-ing Tyler.

**This IS NOT:** A self-service portal where the user provisions their own site. Every request is reviewed by an operator (Jenna per `jenna-runbook-DRAFT.md` § 4) before provisioning. There is no auto-approval path in v1.

---

## 2. The end-to-end flow

```
┌──────────────┐    ┌────────────────┐    ┌──────────────┐    ┌─────────────┐
│ User submits │    │ Power Automate │    │ bd issue     │    │ Operator    │
│ MS Form      │───▶│ flow           │───▶│ created in   │───▶│ triages per │
│ (anonymous   │    │ (token-auth    │    │ DeltaSetup   │    │ jenna-      │
│  to user)    │    │  to GitHub)    │    │ with pre-    │    │ runbook §4  │
│              │    │                │    │ populated    │    │             │
└──────────────┘    └────────────────┘    │ fields       │    └──────┬──────┘
                                          └──────────────┘           │
                                                                     ▼
                                          ┌──────────────────────────────────┐
                                          │ Spoke provisioned in scaffold    │
                                          │ mode; bd closes; launch comms    │
                                          │ scheduled separately if needed   │
                                          └──────────────────────────────────┘
```

Total time, happy path: **request → provisioned spoke in dev ≈ 1 business day**. Prod follows in next deploy cycle.

---

## 3. The Microsoft Form schema

Form lives at: `https://forms.office.com/r/<TBD>` (to be created in Phase 4).

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| **Your name** | Auto-populated from Forms identity | yes | — | NOT user-edited; comes from auth |
| **Your email** | Auto-populated from Forms identity | yes | — | NOT user-edited |
| **Your role** | Single-select | yes | One of: Owner, Manager, Staff, HTT Corp, Other | Used to validate against the role taxonomy in `02-identity-audience.md` |
| **Site purpose** | Long text | yes | Min 50 chars, max 1000 | "What is this site for? Who's it for? What kind of content?" |
| **Proposed site name** | Short text | yes | Regex `^[A-Z][A-Za-z0-9 ]{2,40}$` | Display name. Will be normalized to a mailNickname by the operator. |
| **Intended audience(s)** | Multi-select | yes | From the role taxonomy R1-R6 (+ "Other — describe below") | If "Other," this becomes an ADR-level question (see runbook § 4 step 3) |
| **Will this site have external (HTT) participants?** | Single-select | yes | Yes / No / Don't know | Routes to the cross-tenant guardrail discussion (`02-identity-audience.md` § Cross-tenant invitation policy guardrail) |
| **Approximate launch date** | Date | no | Future-dated within 90 days | Used by the operator to prioritize; not a guarantee |
| **Is anything time-sensitive?** | Long text | no | — | Helps triage urgency |
| **Anything else?** | Long text | no | — | Catchall for things the form didn't ask |

**Submission acknowledgement (on-screen only):**

> "Thanks! Your request has been logged as #DCE-INTAKE-{auto-id}. An operator will review within 1 business day. **You will not receive an email confirmation** — this is intentional (we batch all comms; see ADR-011 in our spec pack). If you need to add detail, reply on this form or DM Jenna."

This wording is critical: it sets the expectation that no email is coming, which prevents the user from spamming the form thinking it failed silently.

---

## 4. The Power Automate flow

**Trigger:** "When a new response is submitted" on the form above.

**Steps (sketch — finalize in Phase 4):**

1. **Get response details** — pull all form fields.
2. **Validate against role taxonomy** — call a lightweight Azure Function (or inline Power Automate expression) that loads `02-identity-audience.md` § "The role taxonomy" and confirms the selected audience IDs match. If a user picks "Other," skip this validation but flag the bd as `needs-adr`.
3. **Compose bd description** — markdown body, pre-populated with:
   - All form fields
   - The submitting user's email + Entra `userType` (via a Graph call — gives Jenna the cross-tenant context)
   - A timestamp + form response ID
4. **Create bd via GitHub API** — POST to `https://api.github.com/repos/Delta-Crown-Org/DeltaSetup/issues` with:
   - title: `Site request: <Proposed site name>`
   - labels: `site-request,phase-4,pillar-adaptation`
   - assignee: `tyler.granlund` (initially) or Jenna once she's the triage owner
   - body: the composed description
5. **(NO email step.)** This is the ADR-011 invariant. The form's on-screen ack is the only confirmation.
6. **Audit log** — write the form response ID + bd issue number to a SharePoint list `Site-Request-Audit` for SOX retention.

**Token-auth note:** The Power Automate connection to GitHub uses a fine-grained PAT scoped to `issues:write` on `Delta-Crown-Org/DeltaSetup` only. The PAT is stored in the Power Automate connection itself (encrypted at rest, owner = the `dce-automation@deltacrown.com` service account). 90-day rotation.

---

## 5. The bd template (what gets auto-filled)

```markdown
# Site request: <Proposed site name>

**Submitted by:** <name> (<email>, userType=<Member|Guest>)
**Role (per submitter):** <Owner|Manager|Staff|HTT Corp|Other>
**Form response ID:** <auto-id>
**Submitted at:** <ISO8601 timestamp>

## Purpose
<long text from "Site purpose">

## Proposed
- **Display name:** <Proposed site name>
- **mailNickname:** <to be normalized by operator — usually camelCase or kebab-case>
- **Audiences:** <multi-select values>
- **External participants:** <Yes|No|Don't know>
- **Launch target:** <date or "no preference">

## Time-sensitive?
<long text or "no">

## Other context
<long text or "(none)">

---

## Operator triage (Jenna fills in)

- [ ] Audience IDs validated against `02-identity-audience.md` role taxonomy
- [ ] If external participants: AADSTS500213 guardrail considered (no policy change needed?)
- [ ] Name normalized to mailNickname (record below)
- [ ] PR opened: <PR URL>
- [ ] Provisioned in dev: <site URL>
- [ ] Provisioned in prod: <site URL>
- [ ] Launch comms scheduled (if user-facing): <link to launch-mode workflow run>

## Notes
(operator adds here as triage proceeds)
```

---

## 6. The triage workflow (operator-side)

See [`jenna-runbook-DRAFT.md`](./jenna-runbook-DRAFT.md) § 4. TL;DR:

1. Read the bd.
2. Verify name + audience against the spec pack.
3. Validate role taxonomy (the Power Automate validation already did this; eyes-on confirms).
4. If audience is "Other": escalate to Tyler as an ADR-level question.
5. If routine: scaffold the spoke per the runbook, PR, merge, deploy, close the bd.

**Time budget:** ~15 min for a routine request, ~1h for one that needs spec-pack discussion.

---

## 7. Acceptance criteria for closing bd `9b8`

Per the bd description: "a real fake request flows form → bd → approved → template provisioned in dev."

Concrete test plan:

1. Create the form per § 3.
2. Wire the Power Automate flow per § 4.
3. Submit a test response as `jenna+test@deltacrown.com` (or a real test account).
4. Confirm a bd is created in DeltaSetup with the auto-populated body.
5. Walk through the operator triage steps end-to-end.
6. Confirm a dev-tier spoke is provisioned.
7. Confirm zero user-facing notifications fired during the entire flow (check Message Trace for the test mailbox; should be empty).
8. Close `DeltaSetup-9b8` with the form URL + Power Automate flow URL + test bd issue ID in the closure notes.

---

## 8. Open questions

1. **Anonymous form vs auth-required.** The schema above assumes auth-required (we capture the user's email from Forms identity). Should HTT users be able to submit without DCE auth? If yes, add a captcha + manual email field with validation. Recommend: **no** — DCE-only auth — and HTT users go through Tyler/Jenna directly until the MTO question (a3d) resolves.
2. **PAT vs service principal.** A fine-grained PAT works for Phase 4 launch. Long-term, a service principal with GitHub App auth is cleaner (no human rotation cycle). Defer to Phase 5.
3. **Form versioning.** The form schema will evolve. Store schema versions in `docs/operators/site-request-intake-form-schema-vN.md` with the migration path each time fields change.
4. **Self-service for very small requests.** Could "request a new page on an existing site" skip the operator and go straight to a PR-stub? Probably yes, but file as a separate Phase 5 bd; don't conflate with site provisioning.

---

## 9. Failure modes + recovery

| Failure | Recovery |
|---|---|
| Form submits but no bd is created | Power Automate flow run failed. Check the flow run history. Most common: GitHub PAT expired. Rotate per the 90-day reminder. Backfill the bd manually from the form response. |
| bd is created but with garbled fields | Power Automate step 3 (compose description) has a bug. Tickle a bd manually; file a P1 against the flow. |
| User reports "I never got confirmation" | This is **expected** behavior, not a bug. Point them at the on-screen wording in § 3. If the on-screen ack itself didn't show, that's a Forms-render issue and probably a browser cache problem. |
| User submits 5 duplicate requests because no email | Add a "we got it" toast to the form acknowledgement that's more prominent. NOT an email. |
| Operator never picks up the bd | The bd has a 7-day SLA (file as a follow-on bd). After 7 days unassigned, Power Automate pings Tyler via Teams (one-shot, throttled). |
