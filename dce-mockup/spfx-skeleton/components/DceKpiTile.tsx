/**
 * DceKpiTile — single-stat tile with trend indicator.
 *
 * Audience: rendered only for personas in R1/R2/R3/R4 (no front-line
 * staff or HTT corp). The parent web part wraps a row of these with
 * <AudienceGate> from ./AudienceGate.tsx.
 */

import * as React from 'react';
import { tokens as dce } from '../theme/dce-tokens';

export interface IDceKpiTileProps {
  label: string;
  stat: string;
  trendDirection?: 'up' | 'down' | 'flat';
  trendText?: string;
}

const styles: { [k: string]: React.CSSProperties } = {
  root: {
    background: dce.color.surface.card,
    borderRadius: 8,
    padding: dce.spacing.s5,
    boxShadow: '0 4px 16px rgba(10, 31, 28, 0.08)',
    borderTop: `3px solid ${dce.color.brand.teal}`,
  },
  label: {
    fontSize: dce.font.size.sm,
    fontWeight: dce.font.weight.bold,
    textTransform: 'uppercase',
    letterSpacing: '0.08em',
    color: dce.color.text.secondary,
    marginBottom: dce.spacing.s2,
  },
  stat: {
    fontFamily: dce.font.family.heading,
    fontSize: dce.font.size.xxl,
    lineHeight: 1,
    color: dce.color.brand.teal,
    marginBottom: dce.spacing.s2,
  },
  trend: (dir: 'up' | 'down' | 'flat'): React.CSSProperties => ({
    fontSize: dce.font.size.sm,
    fontWeight: dce.font.weight.medium,
    color: dir === 'up' ? dce.color.state.success
         : dir === 'down' ? dce.color.state.danger
         : dce.color.text.secondary,
  }),
};

export const DceKpiTile: React.FC<IDceKpiTileProps> = ({ label, stat, trendDirection = 'flat', trendText }) => (
  <article data-component="dce-kpi-tile" style={styles.root}>
    <div style={styles.label}>{label}</div>
    <div style={styles.stat}>{stat}</div>
    {trendText && (
      <div style={styles.trend(trendDirection)}>
        {trendDirection === 'up' ? '▲' : trendDirection === 'down' ? '▼' : '·'} {trendText}
      </div>
    )}
  </article>
);
