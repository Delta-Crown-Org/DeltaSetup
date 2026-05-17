/**
 * <AudienceGate> — conditionally renders children based on the current
 * user's Entra group membership. Wraps `useAudience` from
 * ../audience/useAudience.ts.
 *
 * Usage:
 *   <AudienceGate context={this.context} groups={['DCE-Managers']}>
 *     <DceKpiRow />
 *   </AudienceGate>
 *
 * The mockup's data-audience attribute maps to this component on port.
 */

import * as React from 'react';
import { WebPartContext } from '@microsoft/sp-webpart-base';
import { useAudience } from '../audience/useAudience';

export interface IAudienceGateProps {
  context: WebPartContext;
  groups: string[];
  mode?: 'any' | 'all';
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export const AudienceGate: React.FC<IAudienceGateProps> = ({ context, groups, mode = 'any', children, fallback = null }) => {
  const { loading, visible } = useAudience(context, { groups, mode });
  if (loading) return null;
  if (!visible) return <>{fallback}</>;
  return <>{children}</>;
};
