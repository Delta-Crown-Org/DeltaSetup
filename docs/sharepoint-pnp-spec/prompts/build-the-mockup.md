# Prompt — "Build the DCE Hub home page mockup"

Use this prompt verbatim with ChatGPT 5.5 Pro (or any capable agent)
after they've absorbed the rest of this spec pack.

---

## Prompt

> You have read the DCE SharePoint PnP spec pack at
> `docs/sharepoint-pnp-spec/`. Your task is now to produce a Tier-B
> (hi-fi HTML) mockup of the **DCE Hub home page** described in
> `04-content-architecture.md` § "Page: Home".
>
> **Output:**
>
> 1. A single static HTML file at
>    `mockups/dce-hub-home.html` (under the spec pack directory).
> 2. A CSS file at `mockups/dce-hub-home.css` that imports from the
>    generated `dist/css/dce-tokens.css` (or inlines the CSS variables
>    if generation hasn't run yet — clearly marked).
> 3. A `mockups/README.md` describing how to run it locally
>    (`python3 -m http.server 8000` from the mockups dir, browse to
>    `localhost:8000/dce-hub-home.html`).
>
> **Constraints:**
>
> - Use ONLY tokens from `reference/dce-tokens.json`. No hardcoded hex
>   values except in the `:root` block of the CSS (which mirrors the
>   tokens).
> - 7 sections per `04-content-architecture.md` (no admin section — that's
>   audience-targeted to R1/R2 only, leave it out of the mockup).
> - Each section must have `data-component="<name>"` attribute matching
>   the component names in `03-design-system.md`.
> - Mobile + tablet + desktop responsive. Breakpoints from
>   `dce-tokens.json` `breakpoint` section.
> - Use the DCE white logo SVG in the hero overlay. Path:
>   `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build-wts/bd-aj1-dce-audit/logos/DeltaCrown/primary-logo-horizontal-without-tag-delta-crown-hair-extensions-dce_white.svg`
>   (copy to `mockups/assets/logo-dce-white.svg`).
> - Pass `axe-core` with no AA violations.
> - Each section's HTML must mechanically map to a planned SPFx web
>   part — keep markup simple and component-like.
>
> **Self-check before delivery:**
>
> 1. Run `npx axe-core mockups/dce-hub-home.html --tags wcag2a,wcag2aa,wcag22aa` and report findings.
> 2. Visually verify in three viewports (375 / 768 / 1440) by manually
>    resizing or using browser devtools.
> 3. Confirm no `#` color values outside the `:root` token block.
> 4. Write a 200-word RATIONALE.md at `mockups/RATIONALE.md` that says
>    what you reused, what you deviated, and why.

---

## Acceptance test

Tyler will:

1. Open `mockups/dce-hub-home.html` in Chrome and verify the 7 sections
   render in the order specified.
2. Resize to mobile and verify it doesn't fall apart.
3. Run axe-core and verify zero AA violations.
4. Compare colors side-by-side with `deltacrown.com` — they should be
   visually identical.
5. Score the output against `EVALUATION-RUBRIC.md`.

If the rubric score is ≥ 75%, the mockup is accepted for sprint-1.
