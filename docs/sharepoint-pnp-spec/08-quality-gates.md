# 08 — Quality Gates

## Principle

> **Every PR is presumed broken until the gates prove otherwise.**

This mirrors the public-site quality gates already running on this
DeltaSetup repo (see `AGENTS.md` — accessibility static audit, browser
smoke audit, axe-core audit, all non-zero on fail).

## The four gates

| Gate | Tool | Target | Severity |
|---|---|---|---|
| **G1 — Token validation** | Style Dictionary build | Tokens compile to all 3 outputs (CSS, Fluent, SP theme) | Block merge |
| **G2 — Template syntax** | `Test-PnPSiteTemplate` | Every `templates/**/*.xml` parses | Block merge |
| **G3 — Accessibility** | `axe-core` + `pa11y-ci` | WCAG 2.2 AA, AAA where named | Block merge |
| **G4 — Smoke + visual** | Playwright (Chromium, Firefox, WebKit) | Pages load, key web parts render, snapshots match | Block merge |

## Gate 1 — Token validation

Runs on every PR that touches `tokens/**`. Verifies:

1. Style Dictionary build succeeds (`npx style-dictionary build`).
2. Output files exist:
   - `dist/css/dce-tokens.css`
   - `dist/fluent/fluentui-theme-dce.json`
   - `dist/sharepoint/theme.json`
3. Each output file is valid CSS / JSON.
4. (Custom rule) Every Tier-2 token resolves to a Tier-1 token; no
   orphan references.
5. (Custom rule) Tier-3 component tokens resolve to Tier-2, never to
   Tier-1 directly.

Failure here = no merge. No exceptions.

## Gate 2 — Template syntax

Every PnP template (XML or JSON) must:

1. Parse cleanly via `Test-PnPSiteTemplate`.
2. Reference only known web-part GUIDs (see
   `reference/sharepoint-webpart-guids.md`).
3. Reference only audience groups listed in `02-identity-audience.md`.

Failure = no merge.

## Gate 3 — Accessibility

Runs against the rendered Dev site (or a Playwright-driven local
preview if site auth isn't available in PR builds).

### Required rules

- WCAG 2.2 AA, all level-A and level-AA rules in axe-core 4.11+.
- WCAG 2.2 AAA on text-heavy zones explicitly tagged (see `06-`).
- Custom contrast check using `--text-on-dark-*` tokens.
- Target size: minimum 44×44 for all interactive elements,
  minimum 24×24 for inline (per WCAG 2.5.8).
- Focus appearance: 3px outline with 4.73:1 contrast against
  surroundings (per WCAG 2.4.11).

### Handling "incomplete" findings

axe-core sometimes reports findings as "incomplete" — it can't
auto-determine pass/fail (e.g., color contrast through a transparent
overlay). Per `AGENTS.md` pattern:

- Surface incomplete findings as WARN, not FAIL.
- Add to manual AAA checklist (one per repo).
- Quarterly review of incomplete list.

### Tools

- `pa11y-ci` for the headless audit.
- `axe-core` via Playwright + `@axe-core/playwright`.
- `jest-axe` for component-level unit tests (when we add SPFx).

## Gate 4 — Smoke + visual regression

### Smoke tests

Playwright spec at `tests/playwright/smoke.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';

const VIEWPORTS = [
  { width: 375, height: 812, name: 'mobile' },
  { width: 768, height: 1024, name: 'tablet' },
  { width: 1440, height: 900, name: 'desktop' },
];

for (const vp of VIEWPORTS) {
  test.describe(`${vp.name} viewport`, () => {
    test.beforeEach(async ({ page }) => {
      await page.setViewportSize({ width: vp.width, height: vp.height });
      await page.goto(process.env.PROD_SITE_URL || process.env.DEV_SITE_URL);
    });

    test('hero renders with brand color', async ({ page }) => {
      const hero = page.locator('.dce-hero, [data-component="dce-hero"]');
      await expect(hero).toBeVisible();
      const bg = await hero.evaluate(el => getComputedStyle(el).backgroundColor);
      expect(bg).toMatch(/rgb\(10, 31, 28\)|#0a1f1c/i);
    });

    test('quick links visible', async ({ page }) => {
      const qlinks = page.locator('[data-component="dce-quicklinks"] a');
      await expect(qlinks.first()).toBeVisible();
      expect(await qlinks.count()).toBeGreaterThanOrEqual(4);
    });

    test('audience-targeted admin section hidden for non-admin', async ({ page }) => {
      // assumes test user is R5
      const admin = page.locator('[data-component="dce-admin-panel"]');
      await expect(admin).toHaveCount(0);
    });

    test('no console errors', async ({ page }) => {
      const errors: string[] = [];
      page.on('pageerror', err => errors.push(err.message));
      await page.reload();
      expect(errors).toEqual([]);
    });
  });
}
```

### Visual regression

Use Playwright's built-in screenshot comparison. Tolerance: 0.2%
pixel difference for layout drift; explicit `maxDiffPixelRatio: 0.05`
in `playwright.config.ts`.

Snapshots stored at `tests/visual/snapshots/`. First-time runs
generate baselines; subsequent runs diff. PR reviewers see diffs
inline via GitHub Actions artifacts.

### Browser matrix

Required:

- Chromium (Microsoft Edge equivalent — the majority of SharePoint
  users).
- Firefox (regression detection across rendering engines).
- WebKit (Safari users — typically smaller share but worth covering).

Mobile: Playwright's "Mobile Safari" and "Mobile Chrome" device
emulations.

## Token-level WCAG verification

Beyond axe-core's runtime check, we statically verify token
combinations are accessible. Custom script at
`tests/accessibility/check-token-contrast.js`:

```javascript
const tokens = require('../../tokens/dce-tokens.json');
const { getContrastRatio } = require('./contrast-utils');

const PAIRS_TO_CHECK = [
  ['text', 'surface', 'AAA'],
  ['text', 'surface-card', 'AAA'],
  ['text-on-dark', 'surface-dark', 'AAA'],
  ['_dce-teal', 'surface', 'AA-text'],
  // ... full matrix from 03-design-system
];

let failed = 0;
for (const [fg, bg, target] of PAIRS_TO_CHECK) {
  const ratio = getContrastRatio(tokens[fg].value, tokens[bg].value);
  const required = target === 'AAA' ? 7 : 4.5;
  if (ratio < required) {
    console.error(`FAIL: ${fg} on ${bg} = ${ratio.toFixed(2)} (need ${required})`);
    failed++;
  }
}
process.exit(failed > 0 ? 1 : 0);
```

Run as part of G1.

## Manual AAA checklist

Some WCAG AAA criteria can't be automated (per the `AGENTS.md` pattern
in this repo). Maintain a checklist in `tests/accessibility/manual-aaa-checklist.md`:

- 1.4.6 Contrast (Enhanced) — verified by token check; spot-check
  hero overlay text manually.
- 1.4.8 Visual Presentation — line length ≤80ch, line height 1.5+,
  paragraph spacing.
- 2.4.10 Section Headings — every page section starts with an `<h2>`
  or deeper.
- 3.1.3 Unusual Words — glossary for industry jargon (Extensionista,
  Concierge, etc.).
- 3.1.5 Reading Level — body copy at ≤9th-grade level
  (Flesch-Kincaid).

Reviewed quarterly. Owner: Tyler.

## Quality-gate failure handling

When a gate fails:

1. **G1 / G2** — engineer fixes locally, re-pushes.
2. **G3** — engineer reviews axe-core output. If a finding is a
   genuine regression: fix. If it's a known-acceptable exception
   (e.g., third-party embed): add to `tests/accessibility/exceptions.json`
   with a justification + sunset date.
3. **G4** — engineer reviews diff. If intentional UI change: regenerate
   snapshots locally with `npx playwright test --update-snapshots`,
   commit new baselines.

**No green-on-failure overrides.** If a gate is wrong, fix the gate
in a separate PR.

## Performance budget (aspirational, not yet a gate)

Targets (not blocking in v1; tracked in dashboard):

- LCP < 2.5s
- CLS < 0.1
- INP < 200ms
- TTI < 3.8s

Measured via Lighthouse CI against the live site (post-deploy step).
Trend tracked; alarms not yet wired.
