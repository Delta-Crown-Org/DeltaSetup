# Analysis — Live Color, Photography, Motion, Voice, Accessibility

## 1. Live color/style drift vs canonical deck context

| Brand | Live state | Drift assessment | Deck implication |
|---|---|---|---|
| HTT Brands | White nav; maroon HTT mark; warm salon photo with burgundy/maroon overlay; HEART/relationship/platform language. | Aligned with parent red/maroon/white context; yellow is not prominent in observed hero. | Keep canonical parent palette. For executive dark slides, use maroon as emotional/parent accent and reserve yellow for small highlights only if contrast passes. |
| DCE / Crown | Redirected to Crown Extension Studio; white header; gold/camel logo/CTA; teal navigation; serif headline over bright salon photo. | Consumer site is lighter and more retail/local-salon than current repo canonical teal/gold luxury platform system. It still validates gold, teal, Crown Society, membership, consultation, Crown Standard-style luxury. | Do not replace canonical DCE logo/tokens. Use live recon as mood input: brighter salon photography, gold CTA, membership language. Keep deck on dark teal/near-black luxury canvas. |
| Frenchies | Cream/navy/coral; editorial nail close-up; rounded terracotta CTA. | Strongly aligned with canonical palette and warm/brush/editorial direction. | Use Frenchies as the warm, clean, human-care counterpoint in cross-brand synthesis. |
| The Lash Lounge | Plum/amethyst, mauve bands, white/black space, centered logo, editorial circular lash image. | Canonical says Montserrat/black canvas + magnetic voice; live site leans plum/mauve and serif headline, but black/white/plum magnetic confidence remains. | On dark deck, use amethyst/plum accents instead of pure black-only expression; preserve magnetic, confidence-led voice. |
| Bishops | Orange/black/white, bold brutal typography, halftone black-and-white image collage, pale blue accent tile. | Strongly aligned with canonical #EB631B/#FFF/#000 plus pale blue accent. | Use Bishops as the high-energy, graphic proof of portfolio range; maintain orange as CTA/accent, not body text on white unless contrast is verified. |

## 2. Photography / hero treatment

- **HTT:** polished business/beauty salon environment; warm lighting; confident subject; burgundy overlay for legibility and parent identity.
- **DCE/Crown:** salon service moment with guest/stylist; white brick/interior; oversized serif headline over image; premium but approachable.
- **Frenchies:** large editorial crop of model/nails; warm neutral background; minimal text above fold; brand color comes through nav/CTA and next section.
- **The Lash Lounge:** split composition: text on pale field, circular close-up eye/lash image on dark plum panel; controlled luxury and confidence.
- **Bishops:** collage of halftone/scanline black-and-white salon/personality imagery with rounded cards; energetic editorial, less polished luxury and more attitude.

## 3. Motion / micro-interactions observed

- HTT: nav collapse, hover prefetch, HubSpot form; likely Avada transitions.
- DCE/Crown: dropdown and mobile menu interactions; Squarespace transform/clip-path image blocks; cookie banner overlay.
- Frenchies: visible floating accessibility widget; likely CTA/nav hover; limited extraction due hidden body state.
- The Lash Lounge: slick hero carousel autoplay, service accordion, video poster fade, testimonial/product sliders, product hover image transitions.
- Bishops: sticky/scroll header class, mobile overlay menu, submenu slide toggles, blog and Instagram slick sliders, lazy loading.

**Deck translation:** Use Reveal.js motion sparingly: quick fade/slide/scale transitions, one restrained portfolio carousel or staggered brand cards. Avoid autoplaying motion in the executive deck; provide `prefers-reduced-motion` support.

## 4. WCAG AA notes for dark executive deck palette

- White or near-white text on the existing DCE dark teal/near-black canvas is safe and aligned with repo context (`#0A1F1C` with rgba white text is documented as AAA/AA depending opacity).
- DCE gold `#D4A84B` is appropriate for decoration, dividers, icons, and filled CTA backgrounds with dark text. It should not be small text on white/light surfaces. Existing project note: gold vs white is about 2.31:1.
- HTT yellow should be treated similarly: use as accent/fill, not small text on white or pale backgrounds unless measured.
- Bishops orange `#EB631B` works visually as a CTA fill with black/near-black or white depending exact size/weight; avoid using orange as small text on white unless tested, as orange hues can sit near the AA boundary.
- Frenchies coral/peach tones are best used as backgrounds or large accents; use navy `#263045` for text.
- TLL mauve/lavender bands should not carry low-contrast small text; use deep plum for text or white on deep plum.
- Avoid relying on brand photography as a text background unless a dark overlay or solid text panel guarantees contrast across the whole crop.
- AccessiBe overlays observed on multiple sites are not a substitute for native deck accessibility. Reveal.js deck should still include semantic headings, keyboard order, visible focus, alt text or decorative hiding, and reduced-motion handling.

## 5. Cross-brand synthesis

The current portfolio reads as a credible beauty platform with four distinct public energies:

1. **HTT:** relationship-first, multi-brand growth platform.
2. **DCE/Crown:** premium repeatable transformation, membership, consultation, Crown Society.
3. **Frenchies:** clean care revolution, warmth, natural detail.
4. **TLL:** confidence, customization, technical/luxe service.
5. **Bishops:** individuality, accessibility, attitude, community.

For an executive intro deck, the strongest synthesis is not sameness; it is a parent platform that preserves distinctive brand magnetism while adding shared operating leverage.
