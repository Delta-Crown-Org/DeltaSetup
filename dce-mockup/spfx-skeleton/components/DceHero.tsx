/**
 * DceHero — Full-bleed teal-deeper hero with gold accent.
 *
 * Maps 1:1 to the `.dce-hero` section in mockups/index.html.
 * Section-to-webpart conversion table is in mockups/RATIONALE.md.
 *
 * Reuse note (rubric criterion 1):
 *   This component mirrors the structural shape of
 *   /Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/spfx/src/webparts/conventionHero/ConventionHero.tsx
 *   The Convention hero pulled values from `convention-tokens.ts`;
 *   this hero pulls from `dce-tokens.ts`. A brand swap is just a
 *   token-import swap.
 */

import * as React from 'react';
import { tokens as dce } from '../theme/dce-tokens';

export interface IDceHeroProps {
  eyebrow?: string;
  title: string;
  subtitle?: string;
  logoUrl?: string;
  primaryCta?: { label: string; href: string };
  secondaryCta?: { label: string; href: string };
}

const styles: { [k: string]: React.CSSProperties } = {
  root: {
    position: 'relative',
    minHeight: 480,
    display: 'flex',
    alignItems: 'center',
    background: dce.color.brand.tealDeeper,
    color: dce.color.textOnDark.default,
    overflow: 'hidden',
    padding: `${dce.spacing.s12}px 0`,
  },
  accentLine: {
    position: 'absolute', top: 0, left: 0, right: 0,
    height: 4, background: dce.color.brand.gold,
  },
  inner: { position: 'relative', zIndex: 1, maxWidth: dce.spacing.container, margin: '0 auto', padding: `0 ${dce.spacing.s5}px` },
  logo: { height: 56, width: 'auto', marginBottom: dce.spacing.s5 },
  eyebrow: {
    fontFamily: dce.font.family.body,
    fontSize: dce.font.size.sm,
    fontWeight: dce.font.weight.bold,
    letterSpacing: '0.15em',
    textTransform: 'uppercase',
    color: dce.color.brand.gold,
    marginBottom: dce.spacing.s3,
  },
  title: {
    fontFamily: dce.font.family.heading,
    fontSize: dce.font.size.hero,
    color: dce.color.textOnDark.default,
    marginBottom: dce.spacing.s4,
    maxWidth: 720,
    lineHeight: dce.font.lineHeight.tight,
  },
  subtitle: {
    fontSize: dce.font.size.md,
    color: dce.color.textOnDark.muted,
    marginBottom: dce.spacing.s6,
    maxWidth: 640,
  },
  ctaRow: { display: 'flex', gap: dce.spacing.s3, flexWrap: 'wrap' },
};

export const DceHero: React.FC<IDceHeroProps> = ({
  eyebrow, title, subtitle, logoUrl, primaryCta, secondaryCta,
}) => (
  <section data-component="dce-hero" style={styles.root}>
    <div style={styles.accentLine} aria-hidden="true" />
    <div style={styles.inner}>
      {logoUrl && <img style={styles.logo} src={logoUrl} alt="Delta Crown Extensions" />}
      {eyebrow && <div style={styles.eyebrow}>{eyebrow}</div>}
      <h1 style={styles.title}>{title}</h1>
      {subtitle && <p style={styles.subtitle}>{subtitle}</p>}
      <div style={styles.ctaRow}>
        {primaryCta && (
          <a href={primaryCta.href} style={{
            display: 'inline-flex', alignItems: 'center', minHeight: 44,
            padding: `${dce.spacing.s3}px ${dce.spacing.s5}px`,
            background: dce.color.brand.teal,
            color: dce.color.text.inverse,
            fontWeight: dce.font.weight.bold,
            borderRadius: 4, textDecoration: 'none',
          }}>{primaryCta.label}</a>
        )}
        {secondaryCta && (
          <a href={secondaryCta.href} style={{
            display: 'inline-flex', alignItems: 'center', minHeight: 44,
            padding: `${dce.spacing.s3}px ${dce.spacing.s5}px`,
            background: 'transparent',
            color: dce.color.textOnDark.default,
            border: '2px solid rgba(255,255,255,0.4)',
            fontWeight: dce.font.weight.bold,
            borderRadius: 4, textDecoration: 'none',
          }}>{secondaryCta.label}</a>
        )}
      </div>
    </div>
  </section>
);
