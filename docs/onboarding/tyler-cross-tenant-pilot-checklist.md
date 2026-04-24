# Tyler Cross-Tenant Pilot Checklist

## Goal
Validate the **real first-hand end-user experience** for cross-tenant onboarding into the Delta Crown tenant using:

- **Source identity:** `tyler.granlund@httbrands.com`
- **Target tenant:** `deltacrown.com`
- **Pilot posture:** leadership + operations + one location (`DCE-LV`)

This checklist is designed to answer two practical questions:

1. **Does the technical access model work?**
2. **What does the experience actually feel like for Tyler?**

If the experience is clunky, confusing, or requires hidden admin heroics, then the onboarding model is not finished no matter how pretty the docs are.

---

## Pilot Target State

### Tyler's intended identity labels in DCE
| Attribute | Target value |
|---|---|
| `companyName` | `Delta Crown Extensions` |
| `department` | `Delta Crown Operations` |
| `jobTitle` | `Manager` |
| `officeLocation` | `DCE-LV` |
| `employeeType` | `TestUser` or `Partner` |
| `extensionAttribute1` | `Leadership` |
| `extensionAttribute2` | `DCE-LV` |
| `extensionAttribute3` | `DCE-CrossTenant-Test` |

### Tyler's expected groups
- `AllStaff`
- `Managers`
- `DCE-Leadership`
- `DCE-Operations`
- `DCE-Loc-LV`
- `DCE-CrossTenant-Pilot`

### Tyler's expected resource access
- DCE Hub visible
- DCE Docs visible
- DCE Operations team/site experience visible
- Leadership private channel visible
- `operations@deltacrown.com` mailbox access if assigned
- `info@deltacrown.com` mailbox access if assigned

### Tyler's expected denied access
- any non-pilot out-of-scope location resource
- any future client-services or marketing resource not intentionally granted
- any app not mapped to his pilot groups

---

## Phase 0 — Before You Start

### Admin prerequisites
- [ ] Cross-tenant access policy is configured per ADR-004
- [ ] Chosen model is confirmed:
  - [ ] B2B collaboration guest
  - [ ] Cross-tenant sync member (**recommended for this pilot if object persistence and group-based auth are the target**)
- [ ] `tyler.granlund@httbrands.com` has been approved as the pilot user
- [ ] The seeded matrices were reviewed:
  - [ ] `templates/dce-user-access-matrix-template.csv`
  - [ ] `templates/dce-group-resource-mapping-template.csv`
- [ ] The initial location code set is confirmed:
  - [ ] `DCE-LV`
  - [ ] any others relevant to testing

### Pilot evidence capture
Create a place to store screenshots / notes before starting.

Recommended capture list:
- sign-in screens
- first error screens if any
- SharePoint landing experience
- Teams access experience
- mailbox visibility in Outlook/OWA
- any confusing prompts or redirects

---

## Phase 1 — Admin-Side Identity Readiness

### 1. Confirm Tyler is in the source-side sync/allow list
- [ ] Tyler is in the HTT-side group that enables the chosen cross-tenant flow
- [ ] Source-side object has the expected source identity state

### 2. Confirm Tyler appears in DCE
In DCE tenant:
- [ ] Tyler can be found in Entra Users
- [ ] Tyler appears as the expected type:
  - [ ] `Member` if cross-tenant sync model is used
  - [ ] `Guest` if guest model is intentionally used
- [ ] Tyler's UPN / mail identity is what you expected
- [ ] There is no duplicate stale object for Tyler

### 3. Confirm DCE-side identity labels
- [ ] `companyName = Delta Crown Extensions`
- [ ] `department = Delta Crown Operations`
- [ ] `jobTitle = Manager`
- [ ] `officeLocation = DCE-LV`
- [ ] `employeeType = TestUser` or `Partner`
- [ ] `extensionAttribute1 = Leadership`
- [ ] `extensionAttribute2 = DCE-LV`
- [ ] `extensionAttribute3 = DCE-CrossTenant-Test`

### 4. Confirm required groups exist
- [ ] `AllStaff`
- [ ] `Managers`
- [ ] `DCE-Leadership`
- [ ] `DCE-Operations`
- [ ] `DCE-Loc-LV`
- [ ] `DCE-CrossTenant-Pilot`

### 5. Confirm Tyler resolves into expected groups
- [ ] Tyler is a member of `AllStaff`
- [ ] Tyler is a member of `Managers`
- [ ] Tyler is a member of `DCE-Leadership`
- [ ] Tyler is a member of `DCE-Operations`
- [ ] Tyler is a member of `DCE-Loc-LV`
- [ ] Tyler is a member of `DCE-CrossTenant-Pilot`

### 6. Run automation checks
Suggested commands:

```powershell
pwsh -File ./phase2-week1/scripts/2.3-AzureAD-DynamicGroups.ps1 `
  -LocationCodes @("DCE-LV") `
  -CreatePilotGroup

pwsh -File ./phase3-week2/scripts/3.3-Security-Hardening.ps1 `
  -LocationCodes @("DCE-LV")

pwsh -File ./phase3-week2/scripts/3.7-Phase3-Verification.ps1 `
  -ExpectedLocationCodes @("DCE-LV")
```

- [ ] Dynamic groups script completed successfully
- [ ] Security hardening script completed successfully
- [ ] Verification script completed successfully
- [ ] Any warnings/errors captured below

Notes:
_____________________________________________
_____________________________________________

---

## Phase 2 — Tyler's Real User Experience: First Access

### 1. Fresh-session test
Use a clean browser state so cached identity junk does not cosplay as success.

- [ ] Open a fresh InPrivate/Incognito browser window
- [ ] Sign in as `tyler.granlund@httbrands.com`
- [ ] Start from the intended entry point:
  - [ ] SharePoint URL
  - [ ] Teams app/web
  - [ ] Outlook/OWA if mailbox testing is in scope

### 2. Capture the sign-in experience
Observe exactly what Tyler sees.

- [ ] Was tenant selection clear?
- [ ] Was there a consent or redemption prompt?
- [ ] Was the redirect path obvious?
- [ ] Did Tyler understand which org/resource he was entering?
- [ ] Were there any scary or misleading prompts?

Rate the sign-in experience:
- [ ] Smooth
- [ ] Acceptable but clunky
- [ ] Confusing
- [ ] Broken

Notes:
_____________________________________________
_____________________________________________

### 3. Confirm first successful landing
- [ ] Tyler reaches the intended landing page without admin intervention
- [ ] No `AADSTS500213` or similar admission-layer failure occurs
- [ ] No blank/looping redirect behavior occurs
- [ ] No unexpected access denied screen appears before resource evaluation

---

## Phase 3 — SharePoint Experience Validation

### 1. DCE hub experience
- [ ] Tyler can open the DCE hub
- [ ] Hub branding looks correct
- [ ] Navigation is visible
- [ ] Tyler can identify where to go next without guessing

### 2. Intended site access
- [ ] Tyler can open `/sites/dce-hub`
- [ ] Tyler can open `/sites/dce-docs`
- [ ] Tyler can reach the DCE operations-connected SharePoint experience if applicable

### 3. Content interaction checks
- [ ] Tyler can open documents he should be able to read
- [ ] Tyler can upload/edit where his pilot role should allow it
- [ ] Tyler does **not** get random permission prompts for in-scope resources

### 4. UX notes
Answer these honestly:
- [ ] Navigation felt intuitive
- [ ] It was obvious which resources belonged to DCE
- [ ] There was no confusing mix of HTT vs DCE identity cues
- [ ] Tyler could tell whether he was in the right tenant/workspace

SharePoint notes:
_____________________________________________
_____________________________________________

---

## Phase 4 — Teams Experience Validation

### 1. Team visibility
- [ ] Tyler can access the `Delta Crown Operations` Team
- [ ] Standard channels expected for pilot are visible

### 2. Leadership access
- [ ] Tyler can access the `Leadership` private channel
- [ ] Leadership private channel behaves like a real authorized space
- [ ] No weird partial-access behavior occurs

### 3. Teams UX notes
- [ ] Team/channel membership looked correct immediately
- [ ] No multi-tenant confusion in Teams shell
- [ ] Channel/file access worked consistently

Teams notes:
_____________________________________________
_____________________________________________

---

## Phase 5 — Mailbox / Outlook Validation

Only do this if mailbox permissions were intentionally assigned for Tyler.

### 1. Mailbox appearance
- [ ] `operations@deltacrown.com` appears in Outlook/OWA if assigned
- [ ] `info@deltacrown.com` appears in Outlook/OWA if assigned
- [ ] Auto-mapping worked, or lack of auto-mapping is understood

### 2. Send-as / access tests
- [ ] Tyler can open the shared mailbox
- [ ] Tyler can compose using the shared mailbox address if intended
- [ ] Tyler can read expected mailbox content
- [ ] Any delay or confusion is documented

### 3. Mail UX notes
- [ ] Shared mailbox behavior was intuitive
- [ ] Address selection was obvious
- [ ] No unexplained permission denied behavior occurred

Mailbox notes:
_____________________________________________
_____________________________________________

---

## Phase 6 — App Validation

Only test apps actually mapped to Tyler's pilot groups.

For each assigned app:
- [ ] App launches successfully
- [ ] Tyler lands in the correct tenant/context
- [ ] Tyler can perform the intended pilot action
- [ ] Tyler does not get over-privileged access

App notes:
_____________________________________________
_____________________________________________

---

## Phase 7 — Negative Access Tests

This part matters. A lot.
If Tyler can see everything, you did not succeed. You just made a shiny security bug.

### 1. Out-of-scope SharePoint checks
- [ ] Tyler cannot access marketing-only resources unless intentionally granted
- [ ] Tyler cannot access client-services-only resources unless intentionally granted
- [ ] Tyler cannot access non-LV location-specific resources unless intentionally granted

### 2. Out-of-scope Teams checks
- [ ] Tyler cannot access non-pilot restricted Teams/channel spaces
- [ ] Tyler does not see unexpected private channels

### 3. Out-of-scope app checks
- [ ] Tyler cannot launch apps not mapped to his groups

Negative-test notes:
_____________________________________________
_____________________________________________

---

## Phase 8 — Experience Scoring

### Technical success
- [ ] Identity admission worked
- [ ] Identity object state was correct
- [ ] Labels were correct
- [ ] Groups resolved correctly
- [ ] Intended resources worked
- [ ] Denied resources were actually denied

### Human experience success
Rate each from 1-5:

| Category | Score | Notes |
|---|---:|---|
| Sign-in clarity |  |  |
| Tenant context clarity |  |  |
| SharePoint usability |  |  |
| Teams usability |  |  |
| Mailbox usability |  |  |
| Overall confidence |  |  |

### Final call
- [ ] Pilot is ready to repeat for another user
- [ ] Pilot technically works but UX needs cleanup
- [ ] Pilot failed and needs architecture or config changes

---

## Evidence Summary

### What worked well
- 
- 
- 

### What was confusing
- 
- 
- 

### What broke
- 
- 
- 

### Changes to make before scaling
- 
- 
- 

---

## Recommended Follow-Up Artifacts
After completing this pilot, update:
- `templates/dce-user-access-matrix-template.csv`
- `templates/dce-group-resource-mapping-template.csv`
- `docs/onboarding/dce-pilot-bootstrap-notes.md`

If the pilot uncovers real friction, file follow-up issues for:
- sign-in flow confusion
- group-resolution delay
- mailbox usability problems
- SharePoint navigation clarity
- Teams tenant-context confusion
