/**
 * Fluent UI v9 theme — DERIVED from `dce-tokens.ts`.
 *
 * Per 03-design-system.md § "Fluent UI integration":
 *   Style Dictionary builds `fluentui-theme-dce.json` from `dce-tokens.json`.
 *   SPFx web parts wrap their content in <FluentProvider theme={dceTheme}>.
 *   SharePoint Admin Center receives the same theme as an upload-themed JSON.
 *
 * NOTE: The HTT Convention-Page-Build/spfx project pins Fluent UI v8
 * (@fluentui/react 8.121.0). DCE intentionally moves to v9
 * (@fluentui/react-components) — flagged in RATIONALE.md as a spec
 * inconsistency to resolve. Until that decision is locked, this file
 * targets v9 because it's what the May 2026 Microsoft 365 platform
 * has standardized on.
 */

import { tokens as dce } from './dce-tokens';
import { BrandVariants, createLightTheme, Theme } from '@fluentui/react-components';

// Fluent UI v9 BrandVariants is a 16-step ramp. We derive it from the
// DCE teal ramp + neutrals. In production, Style Dictionary's
// `json/fluentui-v9` custom format generates this directly.
const dceBrand: BrandVariants = {
  10:  '#001211',
  20:  '#003633',
  30:  '#004D44',  // tealDark
  40:  '#005A50',
  50:  '#006B5E',  // teal (canonical)
  60:  '#1A7F73',
  70:  '#2D9387',
  80:  '#4A9B8E',  // tealLight
  90:  '#5DB7A9',  // tealOnDark
  100: '#74C5B9',
  110: '#8AD2C9',
  120: '#9FDED8',
  130: '#B4EAE7',
  140: '#C9F5F4',
  150: '#DEFAF9',
  160: '#F0FDFC',
};

export const dceTheme: Theme = {
  ...createLightTheme(dceBrand),
  fontFamilyBase: dce.font.family.body,
  fontFamilyMonospace: 'Consolas, monospace',
  // Component-token overrides where DCE deviates from the Fluent default
  colorBrandBackground: dce.color.brand.teal,
  colorBrandBackgroundHover: dce.color.brand.tealDark,
  colorBrandBackgroundPressed: dce.color.brand.tealDeeper,
  colorBrandForeground1: dce.color.brand.teal,
  colorBrandForeground2: dce.color.brand.tealDark,
  colorBrandStroke1: dce.color.brand.teal,
};
