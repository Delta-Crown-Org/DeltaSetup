# Raw findings — design-token governance

## Design Tokens Community Group — Format Module 2025.10 draft

URL: https://www.designtokens.org/TR/2025.10/format/

Findings:

- Status: preview draft, not a W3C Standard and not authoritative for implementation.
- Design tokens express design decisions platform-agnostically and create common vocabulary across disciplines/tools/technologies.
- A token is information associated with a human-readable name, at minimum a name/value pair.
- Token properties include value, type, and description; additional metadata includes extensions and deprecated flags.
- Groups organize tokens but tools should not infer type/purpose from group names.
- Type should be explicit or inherited; tools should not guess type from value.
- References/aliases express design choices, eliminate repetition, and maintain semantic relationships.

## USWDS — Design tokens

URL: https://designsystem.digital.gov/design-tokens/

Findings:

- Visual design is based on consistent palettes of typography, spacing, color, and other style elements called design tokens.
- Tokens constrain broad CSS value choice into curated palettes, improving design efficiency and designer/developer communication.
- USWDS notes: do not include the token’s raw value directly into Sass rules; use helper functions/mixins/settings/utilities.

## GOV.UK Design System — Colour

URL: https://design-system.service.gov.uk/styles/colour/

Findings:

- Always use the GOV.UK colour palette.
- Ensure text and interactive elements meet WCAG 2.2 contrast minimum.
- Use functional colour functions for purpose/context.
- Do not copy specific hex values; use functional/palette functions so updates carry through.
- Use variables only in their designed context.

DCE implication:

DCE should govern brand colors as semantic tokens and avoid raw hex values in component CSS/HTML. Existing refreshed tokens are a good start, but presentation/mockup legacy values and gold contrast constraints should be documented and enforced.