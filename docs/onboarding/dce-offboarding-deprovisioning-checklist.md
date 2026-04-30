# DCE Offboarding + Deprovisioning Checklist

## Purpose

This checklist defines the canonical Delta Crown Extensions offboarding flow for users, partners, test users, and future cross-tenant pilot users.

It complements the onboarding model:

```text
Identity labels → Entra groups → Microsoft 365 resources → verification evidence
```

Offboarding runs the same model in reverse:

```text
Disable or de-scope identity → remove groups/licenses/delegation → verify resource access is gone → retain/archive as approved
```

Do not treat this as approval to change tenant state by itself. Use it as the role-owner checklist for future change tickets, runbooks, and audits while named owner confirmation is still pending.

---

## Owner model

| Area | Accountable owner | Responsibilities |
|---|---|---|
| Offboarding trigger | People/Ops owner | Confirms person, date, reason category, urgency, and whether this is standard or high-risk offboarding. |
| Identity lifecycle | Microsoft 365 / Entra admin | Disables or updates the identity, removes group membership where needed, revokes sessions, and validates sign-in state. |
| SharePoint access | SharePoint/site owner | Confirms hub/spoke access is removed or reduced according to role/location ownership. |
| Teams access | Teams/workspace owner | Confirms team/channel membership is removed once Teams-readable context is available. |
| Exchange access | Mail owner | Removes mailbox delegation, Send As, shared mailbox access, and validates forwarding/auto-reply decisions. |
| Apps and licenses | Microsoft 365 / app owner | Removes app assignments, recovers licenses, and confirms no app-only exception remains. |
| Retention/archive | Content owner + compliance owner | Confirms what content is retained, transferred, archived, or held. |
| Evidence review | Ops owner + admin | Confirms checklist evidence is saved in the approved internal evidence location. |

If named individuals are not assigned yet, these role owners must be named before production launch. Do not let “the admin” become a mystical garbage bucket for every responsibility. That way lies pain.

---

## Offboarding types

| Type | Use when | Extra controls |
|---|---|---|
| Standard employee offboarding | Normal employee departure or role end. | Scheduled disablement, group cleanup, license review, mailbox decision. |
| Partner/vendor offboarding | External or partner access ends. | Remove guest/cross-tenant access, confirm no Teams/SharePoint residual access. |
| Cross-tenant pilot offboarding | Pilot user from an approved external tenant leaves the pilot. | Remove from `DCE-CrossTenant-Pilot`, clear pilot attributes, verify access denial. |
| High-risk offboarding | Immediate termination, suspected compromise, legal/security concern. | Immediate session revocation, password reset/disable, MFA/device review, priority evidence capture. |

---

## Required pre-checks

Before making changes, capture the current intended state:

1. user principal name / object ID;
2. user type: employee, partner, guest, test user, cross-tenant pilot;
3. manager or business owner;
4. role and location attributes;
5. group memberships;
6. SharePoint sites/libraries with direct or group-based access;
7. Teams/team/channel membership where readable;
8. shared mailbox permissions and Send As permissions;
9. app assignments;
10. license assignments;
11. retention, hold, archive, or mailbox-conversion requirements.

Raw evidence may contain personal data and permissions. Keep it in the approved internal/local evidence location, not the public repo.

---

## Standard offboarding checklist

### 1. Confirm business decision

- [ ] Confirm offboarding date/time.
- [ ] Confirm standard vs high-risk offboarding.
- [ ] Confirm replacement/ownership handoff.
- [ ] Confirm whether mailbox/data should be retained, delegated, converted, or archived.
- [ ] Confirm whether the person owns SharePoint, Teams, groups, apps, or shared mailbox workflows.

### 2. Lock or de-scope identity

For standard offboarding, schedule the action for the approved time. For high-risk offboarding, do it immediately.

- [ ] Disable the account or block sign-in as approved.
- [ ] Revoke active sessions/refresh tokens where applicable.
- [ ] Reset password if required by policy.
- [ ] Remove or update lifecycle-driving attributes:
  - `companyName`
  - `department`
  - `jobTitle`
  - `officeLocation`
  - `employeeType`
  - `extensionAttribute1`
  - `extensionAttribute2`
  - `extensionAttribute3`
- [ ] Remove from static pilot/exception groups such as `DCE-CrossTenant-Pilot`.
- [ ] Confirm dynamic groups no longer include the user after rule processing.

### 3. Remove Microsoft 365 access

- [ ] Confirm `AllStaff` no longer grants baseline access.
- [ ] Confirm role groups such as `Managers`, `Marketing`, `Stylists`, and future `DCE-*` functional groups no longer include the user.
- [ ] Confirm location groups such as `DCE-Loc-*` no longer include the user if location access is no longer valid.
- [ ] Remove direct SharePoint permissions if any exist.
- [ ] Remove Teams/team/channel membership where readable.
- [ ] Remove shared mailbox Full Access permissions.
- [ ] Remove shared mailbox Send As permissions.
- [ ] Remove app assignments.
- [ ] Recover or reassign Microsoft 365 licenses as approved.

### 4. Transfer ownership

- [ ] Transfer ownership of documents, lists, Teams, SharePoint sites, groups, apps, bookings, or mailbox workflows.
- [ ] Confirm shared mailbox auto-reply/forwarding decisions with the business owner.
- [ ] Confirm no ownerless dynamic/security groups are created by the removal.
- [ ] Confirm no ownerless SharePoint/Teams resources remain.

### 5. Retention and archive

- [ ] Apply retention, archive, mailbox conversion, litigation hold, or deletion approach approved by content/compliance owner.
- [ ] Do not delete content merely because user access is removed.
- [ ] Keep audit evidence according to internal retention expectations.

### 6. Verification

Verify both positive cleanup and negative access:

- [ ] Account cannot sign in if disabled/block sign-in was required.
- [ ] User is absent from expected Entra groups.
- [ ] User cannot access DCE SharePoint hub/spoke resources.
- [ ] User cannot access DCE Teams/channel resources once Teams verification is available.
- [ ] User cannot open or send as shared mailboxes unless intentionally retained/delegated.
- [ ] User has no direct app assignment unless intentionally retained.
- [ ] Exceptions are documented with owner, reason, and expiration/review date.

---

## High-risk addendum

For urgent or security-sensitive exits:

1. block sign-in immediately;
2. revoke sessions immediately;
3. reset password if applicable;
4. remove MFA methods or review suspicious methods according to security policy;
5. remove group membership and mailbox delegation immediately;
6. preserve evidence before destructive cleanup;
7. coordinate retention/legal hold before deleting anything;
8. run verification twice: immediately and again after dynamic groups/processes settle.

---

## Cross-tenant pilot offboarding

For a pilot user admitted from HTT Brands or another tenant:

- [ ] Remove from `DCE-CrossTenant-Pilot`.
- [ ] Clear or update `extensionAttribute3 = DCE-CrossTenant-Test`.
- [ ] Confirm cross-tenant access policy no longer admits the user if the entire relationship is ending.
- [ ] Confirm the user no longer resolves into DCE baseline/role/location groups.
- [ ] Verify SharePoint access denial.
- [ ] Verify Teams access denial once Teams-readable context is available.
- [ ] Verify shared mailbox/app access denial if assigned.

---

## Evidence to retain internally

| Evidence | Public repo? | Notes |
|---|---|---|
| Completed checklist | No, unless sanitized | May include names and dates. |
| Group membership exports | No | Contains user and permission data. |
| SharePoint permission exports | No | Contains site/user/role assignments. |
| Teams membership exports | No | Blocked until Teams-readable context is provided. |
| Exchange permission exports | No | Contains mailbox trustees. |
| Public summary | Yes, sanitized | Use high-level status only. |

---

## Current limitations

- Teams/channel read verification is blocked until `DeltaSetup-151` provides a licensed Teams-readable context or owner attestation.
- Current metadata gaps mean dynamic groups are only as reliable as identity attributes.
- Named individual owners still need confirmation before production launch.

---

## Definition of done

Offboarding is complete when:

1. the business owner confirms the person should be removed or de-scoped;
2. identity sign-in and attributes are updated;
3. group, SharePoint, Teams, Exchange, app, and license access are removed or intentionally retained;
4. content retention/archive decisions are documented;
5. verification evidence is captured internally;
6. exceptions have an owner and review date.
