# Project context extraction

- Repository hosts DeltaSetup / Delta Crown Extensions static presentation and public pages.
- Existing presentation assets use DCE dark teal/gold palette: `--teal-deeper #0A1F1C`, `--teal #006B5E`, `--gold #D4A84B`, `--gold-light #E8C989`, `--surface #FAFAF7`.
- Typography in public presentation CSS: Playfair Display headings and Tenor Sans body.
- Existing DCE logo assets include white SVG/PNG and royal-gold PNG/SVG variants in `assets/logos/` and `presentation/assets/logos/`.
- Required quality gates for public-page changes touching HTML/CSS/JS: static accessibility audit, browser smoke audit, axe audit.
- User context: HTT/DCE executive intro Reveal.js deck, 16 slides, dark teal/gold system, proof slides for Frenchies, The Lash Lounge, and Bishops using canonical brand book / registered logos.

Computed contrast for DCE tokens:

| Pair | Ratio | Use |
|---|---:|---|
| gold #D4A84B on teal-deeper #0A1F1C | 7.75:1 | OK for normal text, labels, rules |
| gold-light #E8C989 on teal-deeper | 10.73:1 | OK for emphasis |
| white on teal-deeper | 17.13:1 | OK for all text |
| teal #006B5E on surface #FAFAF7 | 6.15:1 | OK for body/heading text |
| gold #D4A84B on white | 2.21:1 | Fail for text; decorative/accent only |
| gold-dark #B8943F on white | 2.86:1 | Fail for text; decorative/accent only |
| teal-deeper on gold | 7.75:1 | OK for CTA text on gold |
