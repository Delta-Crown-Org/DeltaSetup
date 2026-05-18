# DCE visual system

This is the canonical Delta Crown Extensions visual-system note for the public
status pages, presentation assets, and SharePoint theme work.

## Official palette

| Role | Hex | Usage | Contrast guidance |
| --- | --- | --- | --- |
| Royal gold | `#D8A562` | Accent lines, decorative marks, premium highlights, focus on dark surfaces | Do **not** use as normal text on white/ivory. Passes AAA as text on almost-black. |
| Emerald | `#03534D` | Primary brand color, buttons, links, headings on light surfaces, dark overlays | Passes AAA on white/ivory. Do not place emerald text/icons on almost-black. |
| Almost-black | `#231F20` | Primary body text, dark surface, Brand Center neutral dark/black | Passes AAA on white/ivory. Preferred dark text color. |
| Ivory | `#FAFAF7` | Page background | Use with almost-black or emerald text. |

These values supersede the earlier working teal/gold pair `#006B5E` and
`#D4A84B`. Those older values may remain in historical research packets, but
new implementation work must use the official palette above.

## Token mapping

Public pages source these values from `css/tokens.css`:

```css
--dce-emerald:      #03534D;
--dce-gold:         #D8A562;
--dce-almost-black: #231F20;
--dce-ivory:        #FAFAF7;
```

Legacy aliases such as `--teal` and `--gold` intentionally point at the formal
DCE values so older component CSS can remain stable while the visual language is
standardized. Cute, but also practical. We like practical.

SharePoint theme artifacts in `Delta-Crown-Org/dce-sharepoint` must derive from
the same palette:

- `tokens/dce-tokens.json`
- `themes/dce-sharepoint-theme.json`
- `themes/dce-fluent-v8-theme.json`

The SharePoint `themePrimary` must be `#03534D`, `accent` must be `#D8A562`, and
neutral dark/black text must resolve to `#231F20`.

## Curated assets

### Logo assets committed in this repo

| Path | Use |
| --- | --- |
| `assets/logos/dce/primary-stacked-royal-gold.svg` | Preferred stacked mark on light/ivory surfaces. |
| `assets/logos/dce/primary-stacked-white.svg` | Preferred stacked mark on dark emerald/almost-black surfaces. |
| `assets/logos/dce/primary-horizontal-royal-gold.svg` | Horizontal mark for wide light layouts. |
| `assets/logos/dce/primary-horizontal-white.svg` | Horizontal mark for wide dark layouts. |
| `assets/logos/dce/logomark-royal-gold.svg` | Decorative watermark/accent mark. |
| `assets/logos/dce/logomark-white.svg` | Decorative mark on dark surfaces. |
| `assets/logos/primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_royal-gold.png` | PNG fallback for deck/public pages on light surfaces. |
| `assets/logos/primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_white.png` | PNG fallback for dark surfaces. |
| `assets/logos/primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_white.svg` | SVG fallback where the long source filename is already wired. |

### Photography assets committed in this repo

| Path | Current use |
| --- | --- |
| `assets/photography/dce/salon-consultation.jpg` | Public-page hero context. |
| `assets/photography/dce/salon-service-space.jpg` | Operations hero/context. |
| `assets/photography/dce/bts-stylist-work.jpg` | MSP/working brief backdrop. |
| `assets/photography/dce/salon-interior-detail.jpg` | Sidebar and decorative background texture. |
| `assets/photography/dce/leadership-candid.jpg` | Reserved for people/leadership content. |
| `assets/photography/dce/operations-headshot.jpg` | Reserved for operator/person card content. |

### SharePoint paths

The live SharePoint page builders upload the deployable logo set to:

- Crown Connection: `/sites/CrownConnection/SiteAssets/Brand/`
- DEV DCE Hub: `/sites/dce-hub-dev/SiteAssets/Brand/`

Current deployed logo filename:

- `logo-dce-royal-gold.png`
- `logo-dce-white.png`
- `logo-dce-white.svg`

Source repo for those deployable assets:

- `Delta-Crown-Org/dce-sharepoint/assets/logos/`

## Crown Society marks

Crown Society marks are approved as **internal/decorative only** unless a future
brand owner explicitly approves broader usage.

Allowed:

- watermark treatment in decks/internal pages,
- low-opacity decorative stamp on cards,
- internal concept exploration.

Not allowed without approval:

- replacing the primary DCE logo,
- external/public brand identity use,
- owner-facing claims that imply a launched program or membership tier.

Committed source paths:

- `assets/logos/dce/crown-society/monogram-emerald.svg`
- `assets/logos/dce/crown-society/monogram-royal-gold.svg`
- `assets/logos/dce/crown-society/stamp-emerald.svg`
- `assets/logos/dce/crown-society/stamp-royal-gold.svg`

## Usage rules

- Use SVG for crisp UI wherever possible; PNG is fallback/deck-safe.
- Do not stretch, rotate, recolor, outline, or add effects to primary logos.
- Keep clear space around logos at least equal to the cap height of the wordmark.
- Use royal gold as accent/decorative on light surfaces; pair it with dark text
  or dark backgrounds for readable text.
- Use emerald for primary actions/links on light surfaces.
- Use almost-black for body text and dark neutral surfaces.
- New raw hex values outside token roots require a documented reason. Otherwise,
  use the semantic token. DRY is not optional just because CSS lets us sin.

## Oversized public pages

`index.html` is pre-existing and over the preferred 600-line file-size target.
No public-page split was performed in this pass because this work only formalized
brand docs and token alignment. If `index.html`, `operations.html`, `msp.html`,
`css/`, or `js/` are substantially edited again, split/refactor should be its
own cohesive issue and must pass the public-page quality gates.
