# User Onboarding Checklist — HTT Brands → Delta Crown Extensions

## User Information
- **Full Name**: _______________
- **HTT Brands Email**: _______________@httbrands.com
- **DCE Shared Mailbox**: _______________@deltacrown.com
- **Date**: _______________
- **Onboarded By**: _______________

## Pre-Onboarding (IT Admin)
- [ ] User row added to `templates/dce-user-access-matrix-template.csv`
- [ ] Canonical role selected
- [ ] Canonical location code(s) selected
- [ ] User added to `SG-DCE-Sync-Users` security group in HTT Brands tenant (if cross-tenant)
- [ ] Cross-tenant sync cycle completed (check DCE tenant → Users)
- [ ] User appears in DCE tenant as **Member** type (NOT Guest) when sync is the chosen model
- [ ] Identity labels applied in DCE tenant:
  - [ ] `companyName`
  - [ ] `department`
  - [ ] `jobTitle`
  - [ ] `officeLocation`
  - [ ] role/access extension attributes as adopted
- [ ] Shared mailbox created or mapped if required: `_______________@deltacrown.com`
- [ ] Send-As permission granted on shared mailbox if required
- [ ] Full Access permission granted on shared mailbox (AutoMapping enabled) if required
- [ ] User added to appropriate M365 / Entra groups via the standard model:
  - [ ] AllStaff
  - [ ] Managers / Leadership
  - [ ] Functional group(s)
  - [ ] Location group(s)
  - [ ] Cross-tenant pilot group if applicable

## User Setup (With End User)
- [ ] User briefed on DCE tenant access
- [ ] User can sign into DCE SharePoint hub/site experience
- [ ] User can access the correct DCE Teams team/channel(s)
- [ ] User can access the correct apps for their role/location
- [ ] Shared mailbox appears in user's Outlook (may take 30-60 min) if applicable
- [ ] User can select @deltacrown.com in the "From" field if applicable
- [ ] Test email sent from @deltacrown.com to external recipient if applicable
- [ ] External recipient confirms email received (not in spam)
- [ ] Reply to @deltacrown.com arrives in shared mailbox
- [ ] User confirms they cannot see resources outside their role/location scope

## Post-Onboarding
- [ ] Welcome email sent (use `templates/user-welcome-email.html`)
- [ ] User confirmed all expected access working
- [ ] Negative test completed for out-of-scope resources
- [ ] Onboarding issue closed in GitHub

## Reference
- Model: `docs/onboarding/dce-role-location-onboarding-model.md`
- Attribute/group/resource matrix: `docs/onboarding/dce-attribute-group-resource-matrix.md`
- User access matrix: `templates/dce-user-access-matrix-template.csv`
- Group resource mapping matrix: `templates/dce-group-resource-mapping-template.csv`
- Pilot bootstrap notes: `docs/onboarding/dce-pilot-bootstrap-notes.md`

## Notes
_____________________________________________
_____________________________________________
