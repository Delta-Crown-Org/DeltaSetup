/**
 * Fluent UI v8 theme — DERIVED from `dce-tokens.ts`.
 *
 * Per ADR-010 and 03-design-system.md § "Fluent UI integration":
 *   Style Dictionary builds `fluentui-theme-dce.json` from `dce-tokens.json`.
 *   SPFx web parts wrap their content in <ThemeProvider theme={dceTheme}>.
 *   SharePoint Admin Center receives a SharePoint theme from the same tokens.
 */

import { tokens as dce } from './dce-tokens';
import { createTheme, ITheme } from '@fluentui/react';

export const dceTheme: ITheme = createTheme({
  palette: {
    themePrimary: dce.color.brand.teal,
    themeLighterAlt: '#F0FDFC',
    themeLighter: '#C9F5F4',
    themeLight: '#9FDED8',
    themeTertiary: dce.color.brand.tealLight,
    themeSecondary: dce.color.brand.tealOnDark,
    themeDarkAlt: '#005A50',
    themeDark: dce.color.brand.tealDark,
    themeDarker: dce.color.brand.tealDeeper,
    neutralLighterAlt: '#FAF9F6',
    neutralLighter: '#F4F1EA',
    neutralLight: '#E5E0D6',
    neutralQuaternaryAlt: '#D7D1C4',
    neutralQuaternary: '#C8C0B0',
    neutralTertiaryAlt: '#AFA694',
    neutralTertiary: '#7B725F',
    neutralSecondary: '#4F4738',
    neutralPrimaryAlt: '#332D24',
    neutralPrimary: dce.color.text.primary,
    neutralDark: dce.color.brand.tealDeeper,
    black: dce.color.brand.tealDeeper,
    white: dce.color.surface.canvas,
  },
  fonts: {
    medium: {
      fontFamily: dce.font.family.body,
    },
    mediumPlus: {
      fontFamily: dce.font.family.body,
    },
    large: {
      fontFamily: dce.font.family.heading,
    },
    xLarge: {
      fontFamily: dce.font.family.heading,
    },
  },
});
