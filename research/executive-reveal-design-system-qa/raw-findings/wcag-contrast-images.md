# WCAG contrast and image/logo findings

Sources: W3C WCAG 2.2 Understanding 1.4.3, 1.4.11, 1.4.5; WAI Functional Images tutorial.

- Text contrast minimum: 4.5:1 for normal text, 3:1 for large text. Enhanced AAA target: 7:1 normal text.
- Logotypes are exempt from text contrast requirements, but corporate visual guidelines beyond logo/logotype are not exempt.
- Meaningful graphics and UI indicators require 3:1 contrast against adjacent colors unless the particular presentation is essential (logos/flags can qualify).
- Background images that do not provide sufficient contrast with foreground text are a documented failure mode.
- Images of text should be avoided when CSS text can achieve the presentation; logotypes are considered essential and should still have text alternatives.
- A linked logo used alone should have alt text describing destination/function, e.g. “Brand home”; a decorative logo adjacent to visible text can use empty alt.

Implication: brand-heavy slides may display official logos as-is, but all explanatory copy, statistics, badges, and captions must meet contrast independently. Avoid placing copy directly on photography without a stable scrim/panel.
