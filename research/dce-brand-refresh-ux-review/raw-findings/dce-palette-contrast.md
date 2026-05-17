# Raw findings — DCE palette contrast calculations

Calculated with WCAG relative luminance formula for sRGB colors.

Palette:

- Royal gold: `#D8A562`
- Emerald: `#03534D`
- Almost black: `#231F20`
- Ivory: `#FAFAF7`
- White: `#FFFFFF`

| Pair | Contrast | WCAG interpretation |
|---|---:|---|
| gold vs emerald | 4.04:1 | Fails normal text AA; passes large text and non-text 3:1. |
| gold vs almost black | 7.36:1 | Passes normal text AAA. |
| gold vs ivory | 2.12:1 | Fails text and non-text contrast. |
| gold vs white | 2.22:1 | Fails text and non-text contrast. |
| emerald vs almost black | 1.82:1 | Fails text and non-text contrast. |
| emerald vs ivory | 8.55:1 | Passes normal text AAA. |
| emerald vs white | 8.94:1 | Passes normal text AAA. |
| almost black vs ivory | 15.59:1 | Passes normal text AAA. |
| almost black vs white | 16.30:1 | Passes normal text AAA. |
| ivory vs white | 1.05:1 | Not meaningful for foreground/background contrast. |

Practical DCE role rules:

- Use emerald or almost black for normal text on ivory/white.
- Use ivory/white or gold for text on almost black.
- Use ivory/white for normal text on emerald; use gold only for large text/accent on emerald.
- Do not use gold for meaningful text/icons/borders on light surfaces unless paired with another compliant visual indicator.
- Do not use emerald on almost black for meaningful text/icons.