# 04 — Content Architecture (IA, Pages, Navigation)

## Information architecture principle

> **One audience question per page. One primary CTA per section.**

Pages that try to serve every audience simultaneously become the HTT
Brands Headquarters cluster. We use audience targeting (`02-`) to keep
each page focused.

## DCE Hub — pages

The Hub is provisioned as a Communication site at `/sites/dce-hub`. It
needs the following pages:

### Page: Home (`/sites/dce-hub/SitePages/Home.aspx`)

Sections (top to bottom):

1. **Hero** — `dce-hero` component. Headline: "Delta Crown Extensions
   Operations Hub". Subhead: "Everything you need to run your day."
   Primary CTA: "View today's priorities" (anchor to KPI section).
   Audience: all.
2. **Quick links strip** — `dce-quicklink-strip`. 6 links: My Schedule
   / Submit Ticket / Brand Assets / Calendar / People / Help. Audience:
   all.
3. **KPI tiles** — `dce-kpi-tile` × 4. Stats like "Active owners",
   "Today's appointments", "Open tickets", "This week's NPS". Audience:
   R1, R2, R3, R4 (no front-line staff or HTT corp).
4. **Latest news** — `dce-news-feed`. Pulls from associated sites
   tagged `news`. Audience: all.
5. **Owner spotlight** — `dce-people-spotlight`. Monthly rotation,
   curated by Jenna. Audience: all.
6. **Upcoming events** — `dce-event-list`. Audience: all.
7. **Operations alerts** — `dce-news-feed` filtered to category =
   "Operations". Audience: R4, R5 (managers + staff only).
8. **Brand resources tile** — `dce-card-grid` with 3 cards: Brand
   Center / Logo Pack / Style Guide. Audience: all.
9. **Footer** — `dce-brand-footer`. Audience: all.

### Page: About (`/sites/dce-hub/SitePages/About.aspx`)

Sections:

1. Hero ("About Delta Crown Extensions").
2. Mission statement + values.
3. Leadership team grid (`dce-people-spotlight` × N).
4. Brand story (markdown content).
5. Contact info.

### Page: People (`/sites/dce-hub/SitePages/People.aspx`)

Sections:

1. Hero ("Our Team").
2. People web part with audience-aware filter (R1-R3 see all; R4-R6
   see DCE-only).
3. Org chart visualization (Microsoft 365 People web part).

### Page: Resources (`/sites/dce-hub/SitePages/Resources.aspx`)

Sections:

1. Hero ("Resources").
2. SOP library tile (links to Operations Manuals site when built).
3. Brand assets tile (links to Brand Center site).
4. Training tile (links to Training site when built).
5. Forms / templates (`dce-card-grid` with curated forms).

### Page: Admin (`/sites/dce-hub/SitePages/Admin.aspx`)

Sections (R1, R2 only — page-level audience targeting):

1. Permission audit dashboard.
2. User-onboarding status.
3. Site health / activity.
4. Recent admin actions log.

## Crown Connection — pages

Crown Connection is a private M365-Group team site at
`/sites/CrownConnection`. Its home is the team-site home page.

### Page: Home (`/sites/CrownConnection/SitePages/Home.aspx`)

Sections:

1. **Hero** — "Crown Connection". Subhead: "Where DCE owners and HTT
   franchisor meet." Audience: all members.
2. **Pinned announcement** — `dce-news-feed` pinned-only mode. Most
   recent admin-pinned announcement at the top. Audience: all.
3. **Welcome / owner spotlight** — `dce-people-spotlight`. Audience: all.
4. **Quick actions** — `dce-quicklink-strip`. 4 links: Documents /
   Calendar / Ask the Franchisor / Owner-only library. Audience: all.
5. **Document hub tile** — `dce-card-grid` with cards for SOP, Brand,
   HR, Marketing, Operations. Audience: all.
6. **Upcoming events** — `dce-event-list`. Audience: all.
7. **Ask the Franchisor** — `dce-form-embed`. Form visible to all;
   submission rights to R2 + R3.
8. **HTT corporate collateral** — `dce-card-grid` linking to
   corporate-side resources. Audience: R3 + R6.
9. **Owner-only library shortcut** — `dce-card-grid`. Audience: R3
   ONLY.
10. **Footer** — same as Hub.

### Page: Documents (Crown Connection)

The default group Documents library, organized into folders that
mirror the document-hub tile categories.

### Page: Events

Standard Group calendar + events list.

## Navigation

### Hub mega-menu (DCE Hub global nav)

```
Home
About
People
Resources
   ├── Brand Center
   ├── SOP Library
   ├── Training
   ├── Forms & Templates
   └── Logos & Branding
Operations
   ├── Daily Briefing      (R4, R5)
   ├── Schedule            (R4, R5)
   ├── Submit a Ticket     (R4, R5)
   └── Help Desk           (all)
Owner Connect
   └── (deep-link to Crown Connection home) (R2, R3, R6)
Admin
   ├── Permission Audit    (R1, R2)
   ├── User Status         (R1, R2)
   └── Site Health         (R1)
```

Audience targeting is applied per node. R5 staff see Home / About /
People / Resources / Operations / Help only. R3 owners see those plus
Owner Connect. R1 GAs see everything.

### Crown Connection local nav

```
Home
Announcements
Documents
Events
Forms
   └── Ask the Franchisor
Resources
   ├── Owner-only library  (R3 only)
   └── HTT collateral
```

## Audience targeting at the page level

Pages with audience targeting (so they're hidden from non-audience in
search and page navigation):

| Site | Page | Audiences | Reason |
|---|---|---|---|
| DCE Hub | Admin | R1, R2 | Operational sensitivity |
| Crown Connection | Owner-only library landing | R3 | Owner-specific content |

All other pages are visible to all site members but use web-part-level
audience targeting for selective content.

## Search

- Hub search is the default for users browsing from the Hub.
- Each site has site search as fallback.
- We do **not** customize search verticals in v1 — out of scope.

## Translation / localization

Not in scope. DCE operates in English. If franchise expansion requires
Spanish content, we revisit then.

## Content governance

- **Author of record** for each page is set in the page metadata.
- **Review cadence** for SOPs: quarterly. Owner: Jamie.
- **Approval workflow** for Crown Connection pinned announcements:
  Tyler or Jenna approves before pinning. Implementation: SharePoint
  approval flow on the Pages library.

## Anti-patterns to refuse

1. **Page bloat.** A single page with 15+ web parts. Split into
   multiple pages or use audience targeting + tabs.
2. **Document libraries inside document libraries.** SharePoint
   supports nested folders but not nested libraries — keep flat.
3. **Wiki pages in 2026.** Use modern SharePoint pages, never the
   legacy wiki.
4. **Custom master pages.** Modern SharePoint doesn't support them
   reliably; use SPFx Application Customizer for global chrome.
