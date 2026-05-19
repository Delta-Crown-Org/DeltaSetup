# Jamie content input packet — DCE SharePoint pages

**Status:** Draft — input request, not approval evidence  
**Tracking bead:** `DeltaSetup-2dq`  
**Audience:** Jamie Baer, Tyler Granlund, supporting content owners

## Purpose

Use this packet to collect final content inputs without changing production SharePoint pages. This keeps the build moving while approvals, Teams inventory, and promotion gates remain in progress.

## How to use this

For each section, provide:

1. final or draft copy;
2. destination link or source document;
3. content owner;
4. intended audience;
5. whether it is approved for production.

If an answer is unknown, mark `TBD`. Unknown is better than fake certainty wearing a little hat.

## Content input table

| Page/section | Copy needed | Destination/source | Owner | Audience | Approved? | Notes |
|---|---|---|---|---|---|---|
| DCE Hub hero | Final headline/subtitle | n/a | Jamie/Tyler | Staff | No | Decide “DCE Hub” vs “Operations Hub” |
| Quick link: Brand Resources | Label + destination | TBD | TBD | Staff/owners? | No | Confirm Brand Center/source |
| Quick link: Operations | Label + destination | TBD | TBD | Staff | No | Confirm current operations library/site |
| Quick link: Training | Label + destination | TBD | TBD | Staff/owners? | No | Confirm LMS/training source |
| Quick link: Submit Request | Label + destination | TBD | TBD | Staff | No | Confirm intake route |
| Quick link: People/Directory | Label + destination | TBD | TBD | Staff | No | Teams/Graph inventory may affect this |
| Crown Connection CTA | Label + destination | Crown Connection | Tyler/Jamie | Owners/franchisor | No | Audience/approval-gated |
| Operations card | Description + link | TBD | TBD | Staff | No | |
| Marketing/Brand card | Description + link | TBD | TBD | Staff/owners? | No | |
| Training card | Description + link | TBD | TBD | Staff/owners? | No | |
| Corporate Services card | Description + link | TBD | TBD | Staff | No | HR/IT/Finance support paths |
| News/announcement 1 | Title + summary | TBD | TBD | Staff | No | Recommend neutral launch/update item |
| Events | Event source | TBD | TBD | Staff/owners? | No | Calendar source required |
| Owner spotlight | Featured person + copy | TBD | TBD | Owners/staff? | No | Approval required before publishing |

## Page-level decisions

### 1. Primary SharePoint location

Choose one:

- [ ] DCE is primary; HTT only links/lands as needed.
- [ ] HTT needs a separate Delta Crown hub.
- [ ] Hybrid: DCE source of truth + HTT landing/collaboration surface.

Recommended default: DCE is primary.

### 2. Crown Connection visibility

Choose one:

- [ ] visible link for all DCE Hub visitors;
- [ ] audience-targeted link for owners/franchisor only;
- [ ] hidden until Crown Connection promotion is approved.

Recommended default: audience-targeted or hidden until approval.

### 3. KPI tiles

Choose one:

- [ ] include real KPI tiles now;
- [ ] include placeholder/demo KPI tiles only in dev/mockup;
- [ ] defer KPI tiles until data source is approved.

Recommended default: defer KPI tiles.

### 4. Owner spotlight

Choose one:

- [ ] include after featured person approves;
- [ ] replace with neutral “Community updates” section;
- [ ] defer entirely.

Recommended default: defer unless there is approved spotlight copy.

### 5. Support/intake route

Choose one:

- [ ] Microsoft Forms;
- [ ] SharePoint list;
- [ ] Teams channel;
- [ ] email/shared mailbox;
- [ ] Freshdesk or other ticketing;
- [ ] TBD.

## Copy prompts

### Hero

What should the DCE Hub promise users?

Example draft:

> Your home base for Delta Crown resources.

Alternative:

> Find the brand materials, operating resources, training links, and support paths you need in one place.

### Operations

What should users expect to find here?

Prompt:

> Operations should include ______, ______, and ______. The owner for keeping this current is ______.

### Brand resources

Prompt:

> Brand Resources should link to ______. The materials are approved by ______. The audience is ______.

### Training

Prompt:

> Training should link to ______. The source of truth is ______. Franchise owners should / should not see this from Crown Connection.

### Corporate services

Prompt:

> HR questions go to ______. IT questions go to ______. Finance questions go to ______. General requests go to ______.

## Production approval

This packet does not approve production promotion.

Before anything goes live:

- final copy must be approved;
- destinations must be tested;
- audiences/permissions must be validated;
- rollback must be ready;
- Class 3 DCE SyncFabric bridge drift alerting must be live;
- approval must be captured in `bd`.
