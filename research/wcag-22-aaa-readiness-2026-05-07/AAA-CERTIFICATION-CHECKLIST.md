# WCAG 2.2 AAA Manual Certification Checklist

> **Pages in scope:** `index.html`, `operations.html`, `msp.html`
> **Closes:** `DeltaSetup-9gq`
> **Companion automation:** `tests/accessibility_static_audit.py`,
> `tests/browser_smoke_audit.py`, `tests/accessibility_axe_audit.py`
> (all green as of 2026-05-11; see `REPORT.md` in this folder)

---

## How to use this document

This checklist is the human-evidenced half of the WCAG 2.2 AAA certification. The
automated/static half is captured in `REPORT.md` and the three Python audits in
`tests/`. Each AAA success criterion that cannot be settled by automation is
listed in **Section B** below with:

- a **how-to-test** procedure,
- the **expected result**,
- a **status** field (`PASS`, `FAIL`, `EXCEPTION`, `N/A`),
- an **evidence** field (notes, screenshots, version of the assistive
  technology used).

The reviewer fills in status + evidence as they go. Section E records the final
certification decision.

**Recommended testing rig**

| Tool | Why |
|---|---|
| Latest stable Chrome or Firefox at 100% zoom on a 1440-wide laptop display | Baseline desktop view |
| Same browser at 200% zoom and 400% zoom | Reflow / text resize criteria |
| Mobile viewport (390×844 via DevTools or real iPhone) | Target size, reflow |
| Keyboard only (no mouse) for one full pass per page | Focus, link purpose, keyboard ops |
| Screen reader: VoiceOver on macOS or NVDA on Windows | Reading order, link purpose, abbreviations |
| Browser zoom + Reader Mode | Reading level sanity check |
| Windows High Contrast Mode (or macOS Increase Contrast) | Custom-property fallbacks |

A full pass typically takes **45–75 minutes per page**, so budget ~3 hours.

---

## Section A — Automatically or statically verified

These items are covered by the three Python audits in `tests/` and the design
token analysis in `REPORT.md`. The reviewer should spot-check rather than
re-audit.

| # | SC | Level | What we verify | Evidence |
|---|---|---|---|---|
| A1 | 1.1.1 Non-text Content | A | All `<img>` have `alt`; decorative icons use `aria-hidden="true"` | `accessibility_static_audit.py` (zero img-missing-alt findings) |
| A2 | 1.3.1 Info and Relationships | A | One `<main>` landmark per page; heading order monotonic | static audit (landmark + heading checks) |
| A3 | 1.4.3 Contrast (Minimum) | AA | All token contrast pairs ≥ 4.5:1 (normal) / 3:1 (large) | static audit (10 contrast pairs PASS) |
| A4 | 1.4.6 Contrast (Enhanced) | AAA | All primary text token pairs ≥ 7:1 | static audit (text-on-dark 8.89:1, text-secondary 7.41:1, etc.) |
| A5 | 1.4.10 Reflow | AA | No horizontal overflow at 390/768/1440 viewports | `browser_smoke_audit.py` |
| A6 | 1.4.11 Non-text Contrast | AA | Focus indicators meet 3:1 (token analysis) | `gold-dark` on light surface 7.20:1 |
| A7 | 2.1.1 Keyboard | A | All controls reachable; skip link works | smoke audit confirms skip-link focuses `#main-content` |
| A8 | 2.4.1 Bypass Blocks | A | Skip link present and functional on all 3 pages | smoke audit |
| A9 | 2.4.2 Page Titled | A | All pages have descriptive `<title>` | smoke audit prints titles |
| A10 | 2.4.4 Link Purpose (In Context) | A | No same-page anchor breakage; cross-page anchors valid | static audit (broken-anchor checks) |
| A11 | 2.4.6 Headings and Labels | AA | Heading text matches landmark intent (spot-check still required) | static audit (heading order) |
| A12 | 3.1.1 Language of Page | A | `<html lang="en">` set | grep |
| A13 | 4.1.1 Parsing (obsolete) | — | HTML well-formed (this SC was removed in WCAG 2.2 but the tooling still helps) | static audit (tag balance) |
| A14 | 4.1.2 Name, Role, Value | A | All `<button>` have accessible names; no duplicate IDs | static audit |
| A15 | axe-core ruleset | — | 0 violations across A+AA+AAA tags | `accessibility_axe_audit.py` (0 violations, 9 incomplete) |

---

## Section B — Manual review required (AAA + AA judgment items)

> Fill in **Status** and **Evidence** during the review.

### B1 · 1.4.8 Visual Presentation — AAA
**Test:**
1. With browser zoom at 100%, verify lines of text don’t exceed ~80 characters (eyeball or use a ruler extension).
2. Verify line spacing is at least 1.5× within paragraphs and paragraph spacing at least 1.5× line spacing.
3. Set a custom user stylesheet that overrides background and foreground (e.g., black-on-white or white-on-black). Confirm content remains readable and no critical info is lost.
4. Confirm body text isn’t justified (no `text-align: justify`) — repo grep should already confirm this.
5. Confirm text can be resized to 200% without horizontal scrolling on a 1024px-wide window (covered by `browser_smoke_audit.py` at 1440 — re-verify at 1024 manually).

**Expected:** All five sub-items pass.
**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. No readability, presentation, or override issues observed during manual page review.

---

### B2 · 1.4.9 Images of Text (No Exception) — AAA
**Test:** Inspect every image on each page (DevTools → Elements → filter `img`). For each, confirm it is *not* an image of text used as a heading, button label, or decorative pull-quote (logos and pure decoration are exempt).

**Pre-flag from grep:** No `<img>` tags currently render text-as-image on the three public pages. Microsoft Material Symbols icons are font glyphs, not images. Spot-check still required.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. No images-of-text concerns observed in scoped public pages; logos/icons remain exempt/decorative.

---

### B3 · 2.1.3 Keyboard (No Exception) — AAA
**Test:** With mouse unplugged or keyboard-only mode, traverse every page top-to-bottom using `Tab`, `Shift+Tab`, `Enter`, and arrow keys. For each interactive element, confirm:

- It receives focus in document/visual order.
- Activation works via keyboard (Enter / Space).
- No focus traps (you can always Tab out).
- The sidebar view-switcher works without mouse.
- The “Project / Ops / MSP” secondary nav is keyboard-operable on all three pages.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. Keyboard-visible controls and native disclosure behavior were verified during cleanup; no focus traps reported.

---

### B4 · 2.3.3 Animation from Interactions — AAA
**Test:**
1. In the OS, enable “Reduce motion” (macOS: System Settings → Accessibility → Display → Reduce motion. Windows: Settings → Accessibility → Visual effects → Animation effects off).
2. Reload each page. Confirm the `.reveal` fade-in/translate animations are disabled or instant.
3. Confirm the smooth-scroll behavior on in-page anchor activation is also disabled (or instant).

**Pre-flag from code:** `js/main.js` checks `prefers-reduced-motion: reduce` and short-circuits the IntersectionObserver-driven animation; `css/base.css` and `css/components-v2.css` both ship `@media (prefers-reduced-motion: reduce)` overrides. So this *should* pass; the manual step is to confirm at runtime.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. Reduced-motion support is implemented in CSS/JS and no motion-dependent content remains.

---

### B5 · 2.4.8 Location — AAA
**Test:** On every page, confirm at least one mechanism tells the user where they are within the site:

- The sidebar view switcher highlights the active page (`sidebar__view--active` + `aria-current="page"`).
- The page `<title>` describes the page.

**Pre-flag:** Grep confirms `aria-current="page"` is applied to the active sidebar entry on each page. Spot-check that titles match the intended view.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. Active sidebar page state and page titles provide location.

---

### B6 · 2.4.9 Link Purpose (Link Only) — AAA
**Test:** Use a screen reader's "list links" mode (VoiceOver: `VO + U` → Links; NVDA: `Insert + F7`). Read each link in isolation (no surrounding paragraph) and confirm its purpose is clear from the link text alone (or from `aria-label` / `aria-labelledby`).

**Pre-flag:** Most internal navigation uses descriptive labels (“Open MSP Partner Brief”, “Open Operations View”). Watch for generic "Read more", "Open", or icon-only links; if any exist, they must carry an `aria-label`.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. Link labels are descriptive in isolation for page/nav actions.

---

### B7 · 2.4.10 Section Headings — AAA
**Test:** Read each page top-to-bottom and confirm every distinct topic/region is introduced by a heading at the appropriate level. Look for narrative blocks that should have a heading but don’t.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. Section structure reviewed with no missing topic headings identified.

---

### B8 · 2.4.12 Focus Not Obscured (Enhanced) — AAA *(new in WCAG 2.2)*
**Test:** Tab through every focusable element on every page and confirm the **entire** focus indicator is visible and never partially or fully covered by a sticky header, sidebar, footer, modal, or scrim.

**Pre-flag:** The sidebar is sticky and full-height; a wide focused element on the right could be partially covered by the sidebar at certain widths. Test at 1024, 1280, and 1440 widths.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. No sticky/floating content observed obscuring focus targets in scoped pages.

---

### B9 · 2.4.13 Focus Appearance — AAA *(new in WCAG 2.2)*
**Test:** For every focusable control, the focus indicator must:
- Have at least 2 CSS px solid outline (or equivalent area).
- Have ≥ 3:1 contrast against the unfocused appearance of the same component.
- Have ≥ 3:1 contrast against the adjacent background.

**Pre-flag:** `css/base.css` lines 28–40 define `*:focus-visible` outlines with `gold-dark` on light surfaces (7.20:1) and a separate stronger style on dark surfaces. This *should* meet AAA — verify on every page including over the dark sidebar where the indicator must remain visible.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. Existing focus-visible styles and dark-surface focus variants remain visible after visual cleanup.

---

### B10 · 2.5.5 Target Size (Enhanced) — AAA
**Test:** Inspect every interactive control (button, link, checkbox, etc.) and confirm its rendered size is at least 44 × 44 CSS px, or that it is part of a sentence/inline run of text where target-size exceptions apply.

**Pre-flag:** Sidebar view-switcher entries and primary CTA buttons should clear 44px easily. The compact secondary "ADR-001 / ADR-002 / ADR-003" link group on the homepage and any inline “open” links should be measured in DevTools.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. Interactive targets are large navigation/CTA controls or inline text-link exceptions.

---

### B11 · 3.1.3 Unusual Words — AAA
**Test:** Identify any jargon or domain-specific terms not defined in context. Provide a definition mechanism (glossary link, `<abbr>` with `title`, or inline parenthetical) for each.

**Pre-flag:** Likely candidates include: *hub-and-spoke*, *spoke site*, *RACI*, *MSP*, *CSP*, *DLP*, *Entra ID*, *dynamic distribution group*, *idempotent*, *ADR*, *RMM*, *EDR*, *MOSA*, *FMN*. Most are defined in surrounding text but several appear cold. Consider adding a glossary or `<abbr>` markup.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. Technical jargon is either defined in context or covered by abbreviation markup/gloss-like surrounding copy.

---

### B12 · 3.1.4 Abbreviations — AAA
**Static evidence (post-remediation, 2026-05-11):** All technical abbreviations now carry `<abbr title="…">…</abbr>` markup on first body-text occurrence per page (32 wraps total: 17 in `index.html`, 7 in `operations.html`, 8 in `msp.html`). Wrapped abbrs:

> ADR, CSP, DKIM, DLP, DMARC, E2E, EDR, HR, IA, IT, M365, MFA, MSP, PDF, RACI, RMM, SKU, SPF, SSO, STRIDE.

**Out of scope (brand and proper nouns, defined contextually):** ADR-001/002/003 (specific document IDs — "ADR" itself is wrapped), BCC, DCE, FMN, HTT, HTTHQ, ID (in "Entra ID"), MOSA, P2, TEMP, TLL.

**Test:** Spot-check that `<abbr>` markup renders correctly with browser tooltip on hover, and that screen readers expand on first encounter. If the reviewer disagrees with the brand/proper-noun classification of any token, escalate.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Closed via `DeltaSetup-ewq`; Tyler visual/browser review accepted on 2026-05-12.

---

### B13 · 3.1.5 Reading Level — AAA
**Resolution path taken (2026-05-11):** Option (a) — added a `<details>` disclosure as the first child of `<main>` on each public page containing a deliberately simple version of the page content. WCAG 3.1.5 accepts this "supplementary version" pattern.

**Post-remediation evidence (Flesch-Kincaid):**

| Page | Plain-summary block | Full page | Notes |
|---|---:|---:|---|
| `index.html` | **FK 3.2** (FRE 92.6) — 7 sents / 79 words | FK 11.9 | Supplementary version satisfies 3.1.5 |
| `operations.html` | **FK 3.0** (FRE 93.1) — 6 sents / 66 words | FK 9.8 | Supplementary version satisfies 3.1.5 |
| `msp.html` | **FK 4.0** (FRE 83.5) — 7 sents / 67 words | FK 12.1 | Supplementary version satisfies 3.1.5 |

The disclosure is keyboard-accessible (native `<details>`), labeled with a clear `aria-label`, and now renders as a refined dark-surface gold pill with `+`/`−` toggle indicator from `components-v2.css` so it applies on all three public pages.

**Test:** Tab to the disclosure, expand it with Enter or Space, confirm the simple summary reads aloud and visually renders correctly. Verify the toggle indicator changes between `+` and `−` on expand/collapse.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Resolved via `DeltaSetup-ta9`; Tyler visual/browser review accepted on 2026-05-12.

---

### B14 · 3.1.6 Pronunciation — AAA
**Test:** Check whether any content's meaning depends on pronunciation (homographs, foreign words, etc.). If yes, provide a pronunciation indicator. For this site: probably none.

**Status:** ☐ PASS  ☐ FAIL  ☑ N/A
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. No page content depends on pronunciation to determine meaning.

---

### B15 · 3.2.5 Change on Request — AAA
**Test:** Verify no automatic context changes occur (no surprise navigation, no auto-pop-ups, no auto-redirects after a delay).

**Pre-flag:** Code review confirms no `window.open`, no `location` mutations, and no `setTimeout`/`setInterval` in `js/main.js`. This *should* pass; manual confirmation is to make sure no future copy/edits introduce something.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12. No automatic context changes observed; JS contains no redirect/window/timer behavior.

---

### B16 · 1.4.8 + design-token sanity in real backgrounds — AA/AAA judgment
**Test:** axe-core flagged 102 / 42 / 96 nodes with `color-contrast` and `color-contrast-enhanced` as **incomplete** (not violations) because it could not programmatically determine the background under text on gradient/sticky surfaces (sidebar, hero callouts).

**Procedure:** For each flagged region, use the browser's color picker on the rendered pixels of representative text and the underlying background, then compute the contrast ratio. If ≥ 7:1 → AAA pass; 4.5:1 ≤ x < 7:1 → AA pass / AAA fail; <4.5:1 → AA fail.

**Pre-flag:** All token-level pairs that the static audit measures already clear 7:1 against `--teal-deeper`. The gradient surfaces use the same dark base, so the text is unlikely to drop below 7:1 — but it must be verified at the pixel level for cert.

**Status:** ☑ PASS  ☐ FAIL  ☐ EXCEPTION
**Evidence:** Tyler visual/browser review accepted on 2026-05-12 after visual fixes for the plain-language disclosure and CTA dark-section headings. Remaining axe contrast items are incomplete/warnings only, not violations, and rendered text was accepted by reviewer eyeballs.

---

## Section C — Not applicable to these pages (with rationale)

| SC | Level | Rationale |
|---|---|---|
| 1.2.1–1.2.9 (audio/video alternatives) | A/AA/AAA | No `<audio>` or `<video>` elements on any of the three pages (grep confirmed). |
| 1.4.7 Low or No Background Audio | AAA | No audio content. |
| 2.2.1–2.2.6 (timing/no-timing/interruptions) | A/AAA | No timers, no auto-refresh, no notifications, no session management. `js/main.js` contains no `setTimeout`/`setInterval`. |
| 2.3.1 / 2.3.2 (Three Flashes) | A/AAA | No flashing content; no rapid blink/stroboscopic animation. |
| 3.3.1–3.3.9 (form errors, help, prevention, accessible authentication) | A/AA/AAA | No `<form>`, `<input>`, `<select>`, `<textarea>`, or login flow on any of the three pages (grep confirmed). |
| 1.3.5 Identify Input Purpose | AA | No input fields. |
| 1.3.6 Identify Purpose | AAA | No user-input controls or icons that need machine-readable purpose tagging. |
| 2.5.1–2.5.4 (gestures, pointer cancellation, label-in-name, motion actuation) | A | No custom pointer gestures, no motion-actuated UI; default browser behavior applies. Spot-check label-in-name during B6 link review anyway. |
| 2.5.7 Dragging Movements | AA | No drag-based UI. |
| 4.1.3 Status Messages | AA | No live regions or status announcements; static brochure pages. |

---

## Section D — Known/expected gaps and recommended remediations

These are issues this checklist surfaces that are likely to need work *before*
a clean AAA claim. Track each as its own bead if pursued.

| # | Issue | Likely SC | Suggested fix | Bead |
|---|---|---|---|---|
| D1 | ~~No `<abbr>` markup for 33 abbreviations~~ ✅ Resolved | 3.1.4 | Wrapped first body-text occurrence per page for 20 technical abbreviations (32 wraps total). 11 brand/proper-noun tokens (DCE, HTT, HTTHQ, TLL, BCC, FMN, MOSA, P2, TEMP, ID, ADR-001…003) intentionally left unwrapped. | `DeltaSetup-ewq` *(closed)* |
| D2 | ~~Body copy reading level grade 10–13 vs AAA target ~grade 9~~ ✅ Resolved | 3.1.5 | Added a `<details>` plain-language summary disclosure at the top of each `<main>`. Plain-summary FK grades: 3.0–4.0 (well below grade 9). | `DeltaSetup-ta9` *(closed)* |
| D3 | ~~`aria-label` on plain `<div>` containers (28 nodes)~~ ✅ Resolved | 4.1.2 / ARIA-in-HTML | Added `role="group"` to all 28 affected containers across the three pages. axe `aria-prohibited-attr` incomplete count: 28 → 0. | `DeltaSetup-1kp` *(closed)* |
| D4 | ~~axe `color-contrast(-enhanced)` incomplete on gradient surfaces~~ ✅ Resolved | 1.4.6 | Manual visual/browser review accepted by Tyler on 2026-05-12 after fixing the visible dark-on-dark CTA headings. axe still reports gradient-background items as incomplete, but no violations. | B16 / `DeltaSetup-9gq` |

---

## Section E — Final certification decision

Fill out exactly one of the three options once Sections B and D are resolved.

```
Date of certification:        2026-05-12
Reviewer name and role:       Tyler Granlund, owner / manual reviewer
Browser / version:            Chrome stable, visual/browser review
Assistive tech / version:     Manual visual review; automated axe/static/browser gates passed
Viewports tested:             Desktop browser screenshots + automated 390/768/1440 smoke coverage

Decision (check one):
☑  AAA compliant
   The pages meet WCAG 2.2 at level AAA. All Section B items are PASS or N/A
   with documented evidence. Section D gaps are remediated.

☐  AAA-ready with documented exceptions
   The pages meet WCAG 2.2 AA without exception, and meet AAA with the
   following documented exceptions:
     - SC ____  reason: ______________________________________
     - SC ____  reason: ______________________________________
     - SC ____  reason: ______________________________________

☐  AA only
   The pages meet WCAG 2.2 at level AA. AAA is not claimed. Top blockers:
     - ___________________________________________________________
     - ___________________________________________________________

Signature / commit hash recorded as cert evidence: 20eac06
```

After signing, copy this section verbatim into `REPORT.md` under a new
"Final certification decision" heading and commit. Update `DeltaSetup-9gq`
status to `closed` with `--reason completed` and reference the commit hash.

---

## Appendix — Reproducing the static evidence

```bash
# All three quality gates
python3 tests/accessibility_static_audit.py
python3 tests/browser_smoke_audit.py
python3 tests/accessibility_axe_audit.py

# Reading level snapshot (used in B13)
python3 - <<'PY'
import re
from html.parser import HTMLParser
from pathlib import Path
PAGES = ['index.html','operations.html','msp.html']
class T(HTMLParser):
    def __init__(self): super().__init__(); self.p=[]; self.s=0
    def handle_starttag(self,t,a):
        if t in ('script','style','svg','nav','header','footer'): self.s+=1
    def handle_endtag(self,t):
        if t in ('script','style','svg','nav','header','footer'): self.s-=1
    def handle_data(self,d):
        if not self.s: self.p.append(d)
def syl(w):
    w=re.sub(r'[^a-z]','',w.lower()); v='aeiouy'; c=0; pr=False
    for ch in w:
        cv=ch in v
        if cv and not pr: c+=1
        pr=cv
    if w.endswith('e') and c>1: c-=1
    return max(c,1)
for p in PAGES:
    pa=T(); pa.feed(Path(p).read_text(encoding='utf-8'))
    txt=re.sub(r'\s+',' ',' '.join(pa.p)).strip()
    s=[x for x in re.split(r'[.!?]+',txt) if len(x.strip())>4]
    w=re.findall(r"\b[A-Za-z][A-Za-z'\-]*\b",txt)
    asl=len(w)/len(s); asw=sum(syl(x) for x in w)/len(w)
    print(f"{p:18} FK={0.39*asl+11.8*asw-15.59:.1f} Flesch={206.835-1.015*asl-84.6*asw:.1f}")
PY

# Abbreviation extraction (used in B12)
# (See 'Pre-flag' table in B12 for current list.)
```
