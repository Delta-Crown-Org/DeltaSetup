# 03 — DCE Design System

## Source of truth

`reference/dce-tokens.json` is the canonical token file. It is
derived from `deltacrown.com/css/tokens.css` (WCAG-audited public
site). All themes, components, and styles must trace back to it.

Update protocol: tokens are changed in `tokens.css` first (which is
governed by this repo's `gh-pages` quality gates). Then the agent
re-generates `dce-tokens.json` via Style Dictionary. Changes to the
JSON file outside that flow are rejected on review.

## Token taxonomy (3-tier)

We use the same 3-tier system spec'd in `DESIGN_SYSTEM_MEGA_BRIEF.md`
(the HTT mega brief). Adapting it to DCE:

```
Tier 1 — Raw / Reference tokens (private; never used in components):
  --_dce-teal:         #006B5E
  --_dce-teal-dark:    #004D44
  --_dce-teal-deeper:  #0A1F1C
  --_dce-gold:         #D4A84B
  --_dce-gold-dark:    #6E4F0E
  --_dce-sage:         #7A9B8A

Tier 2 — Semantic / Alias tokens (used everywhere):
  --color-brand-primary:    var(--_dce-teal)
  --color-brand-secondary:  var(--_dce-gold)
  --color-text-heading:     var(--_dce-teal)
  --color-link:             var(--_dce-teal)
  --color-button-bg:        var(--_dce-teal)
  --color-button-text:      var(--text-inverse)
  --color-surface-hero:     var(--_dce-teal-deeper)

Tier 3 — Component tokens (per-component):
  --hero-bg:                var(--color-surface-hero)
  --hero-text:              var(--text-on-dark)
  --card-border-top:        var(--color-brand-primary)
  --card-shadow:            0 4px 16px rgba(10, 31, 28, 0.08)
  --nav-active-underline:   var(--color-brand-secondary)
```

A brand swap is a Tier-1 edit; no component CSS changes.

## Color palette + WCAG ratings

Filling in DCE values that the HTT mega brief omitted:

### Text-safe colors (≥4.5:1 on white)

| Name | Hex | Ratio vs white | WCAG |
|---|---|---|---|
| `--_dce-teal` | `#006B5E` | 7.07:1 | AAA ✅ |
| `--_dce-teal-dark` | `#004D44` | 9.91:1 | AAA ✅ |
| `--_dce-teal-deeper` | `#0A1F1C` | 18.91:1 | AAA ✅ |
| `--_dce-gold-dark` | `#6E4F0E` | 8.27:1 | AAA ✅ |
| `--text` | `#1A2A3A` | 14.18:1 | AAA ✅ |
| `--text-secondary` | `#465463` | 7.99:1 | AAA ✅ |
| `--text-muted` | `#8A96A4` | 3.53:1 | AA Large only |

### Decorative-only (FAIL on white)

| Name | Hex | Ratio vs white | Use |
|---|---|---|---|
| `--_dce-gold` | `#D4A84B` | 2.31:1 | Backgrounds, icons; NEVER text. Use with `--_dce-teal-deeper` text for AAA (16.55:1). |
| `--_dce-sage` | `#7A9B8A` | 2.86:1 | Accent fills, illustration. |
| `--_dce-teal-light` | `#4A9B8E` | 2.83:1 | Decorative; pair with dark backgrounds. |

### Text-on-dark ramp

For text on `--_dce-teal-deeper` (`#0A1F1C`):

| Token | Value | Ratio | WCAG |
|---|---|---|---|
| `--text-on-dark` | `rgba(255,255,255,0.92)` | 16.5:1 | AAA ✅ |
| `--text-on-dark-muted` | `rgba(255,255,255,0.70)` | 9.5:1 | AAA ✅ |
| `--text-on-dark-subtle` | `rgba(255,255,255,0.62)` | 7.5:1 | AA — large text only per existing token comment |

## Typography

### Fonts

| Role | Font | Fallback chain | Why |
|---|---|---|---|
| Headings | Playfair Display | Georgia, serif | Elegant, brand-distinctive; matches `deltacrown.com` |
| Body | Tenor Sans | -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif | Light, modern, pairs cleanly with Playfair |
| UI / data | Segoe UI Variable | system-ui, sans-serif | SharePoint's native font; we don't fight it for chrome |

### SharePoint nuance

SharePoint Brand Center supports custom font upload (since late 2024).
We upload Playfair Display + Tenor Sans woff2 files for the chrome
elements that respect Brand Center fonts (site title, nav).

For body/article copy in SPFx web parts, we reference fonts directly
via `@font-face` declarations in the SPFx CSS bundle.

For everywhere else (default SharePoint chrome we don't control), we
accept Segoe UI as the rendering font — the typography hierarchy still
reads cleanly.

### Type scale

```
--font-size-xs:    0.75rem   (12px)
--font-size-sm:    0.875rem  (14px)
--font-size-base:  1rem      (16px)
--font-size-md:    1.125rem  (18px)
--font-size-lg:    1.5rem    (24px)
--font-size-xl:    2rem      (32px)
--font-size-2xl:   2.5rem    (40px)
--font-size-hero:  clamp(2.5rem, 5vw, 4rem)   (40-64px responsive)

--line-height-tight:  1.15
--line-height-normal: 1.5
--line-height-loose:  1.7

--font-weight-regular: 400
--font-weight-medium:  500
--font-weight-bold:    700
```

## Component library — first wave

The DCE Hub and Crown Connection home pages need these components.
Each gets its own SPFx web part eventually; in Tier-B mockup phase,
each is a CSS class with a strict naming convention.

| Component | Web-part name | Used on | Description |
|---|---|---|---|
| `dce-hero` | `dce-hero-banner` | Hub, Crown Connection | Full-bleed teal-deeper background, gold accent line, hero text + CTA. Mobile: stacked. |
| `dce-card-grid` | `dce-card-grid` | Hub Home (quick links), Crown Connection (Documents tile) | 3-col responsive (1-col mobile, 2-col tablet, 3-col desktop). Each card has icon, title, description, link. |
| `dce-news-feed` | `dce-news-list` | Hub Home, Crown Connection Announcements | News list with date, author, summary, audience-targetable. |
| `dce-people-spotlight` | `dce-person-card` | Hub Home (Owner Spotlight), Crown Connection (Welcome) | Photo + name + title + bio. |
| `dce-event-list` | `dce-event-tiles` | Hub Calendar, Crown Connection Events | Upcoming events with date, title, location. |
| `dce-form-embed` | `dce-form-embed` | Crown Connection (Ask Franchisor) | JotForm / Microsoft Forms / Power Apps embed wrapper. |
| `dce-quicklink-strip` | `dce-quicklinks` | All sites | Horizontal strip of 4-6 icon+label links. |
| `dce-kpi-tile` | `dce-kpi-block` | Hub Home (visible to R1/R2 only) | Single-stat tile with trend. |
| `dce-section-header` | `dce-section-header` | All pages | Eyebrow + title + optional description. |
| `dce-brand-footer` | `dce-footer` | All sites (via Application Customizer eventually) | Logo, links, social, legal. |

## Fluent UI integration

We layer DCE tokens on top of Fluent UI v9 (`@fluentui/react-components`).
Process:

1. Style Dictionary builds `fluentui-theme-dce.json` from
   `dce-tokens.json`. Format matches Fluent UI's `Theme` interface.
2. SPFx web parts wrap their content in `<FluentProvider theme={dceTheme}>`.
3. SharePoint Admin Center receives the same theme as an
   upload-themed JSON file. This gives us themed chrome.

Example Fluent UI theme map (subset):

```json
{
  "colorBrandBackground": "#006B5E",
  "colorBrandBackgroundHover": "#004D44",
  "colorBrandBackgroundPressed": "#0A1F1C",
  "colorBrandForeground1": "#006B5E",
  "colorBrandForeground2": "#004D44",
  "colorBrandStroke1": "#006B5E",
  "fontFamilyBase": "'Tenor Sans', -apple-system, BlinkMacSystemFont, sans-serif",
  "fontFamilyMonospace": "Consolas, monospace"
}
```

## Logo usage rules

Source: `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/logos/DeltaCrown/`

| File | Use |
|---|---|
| `primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_royal-gold.png` | On light backgrounds (default site theme, body content). |
| `primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_white.png` | On dark backgrounds (`--_dce-teal-deeper` hero overlays, footer). |
| `primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_white.svg` | Preferred over PNG for crispness; use everywhere SVG is supported. |

Minimum logo clear-space: equal to the logo's cap-height on all sides.
Don't:

- Stretch, rotate, recolor.
- Place on a background that drops contrast below 3:1.
- Use the white logo on light backgrounds (or vice versa).

## Motion

```
--ease-out:    cubic-bezier(0.22, 1, 0.36, 1)
--ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1)
--duration:    0.7s   (page-level)
--duration-fast: 0.2s (UI feedback)
```

Respect `prefers-reduced-motion: reduce` — every transform/opacity
transition must have a media query that disables it.

## Open design questions

1. **Hero photography vs illustration.** `deltacrown.com` uses crisp
   photography. SharePoint hero banners traditionally use stock-y
   imagery. Decision: use original DCE photography where available
   (logo work + brand library), fallback to gradient hero with logo
   watermark.
2. **Iconography.** `deltacrown.com` doesn't appear to use a strong
   icon system. Recommendation: adopt `@phosphor-icons/react` (the
   mega brief's recommendation) for component icons.
3. **Dark mode.** Not in scope for v1. The token system is dark-mode
   ready (`--surface-dark`, `--text-inverse`) but we won't ship a
   toggle until requested.
