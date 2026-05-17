/**
 * useAudience — React hook that mirrors the mockup's audience-targeting
 * behavior, backed by real Microsoft Graph group membership.
 *
 * Mocked groups in the Tier-B HTML (see js/audience-targeting.js) map 1:1
 * to Entra group display names checked here via Graph
 * /me/transitiveMemberOf. The hook caches results for the duration of
 * the page session.
 *
 * IMPORTANT (per 02-identity-audience.md):
 *   - Audience targeting is VISIBILITY, not SECURITY. Confidential
 *     content must use a documented permission break, not just this hook.
 *   - HTT corp users arrive in DCE with userType=Member via cross-tenant
 *     sync. Their Graph group lookups behave identically to native users.
 *   - 50-group hard cap per audience-targeted item (SharePoint limit).
 */

import * as React from 'react';
import { MSGraphClientV3 } from '@microsoft/sp-http';
import { WebPartContext } from '@microsoft/sp-webpart-base';

export interface IAudienceConfig {
  groups: string[];     // Group display names; OR semantics
  mode?: 'any' | 'all';
}

export interface IAudienceState {
  loading: boolean;
  visible: boolean;
  matchedGroups: string[];
}

interface IGraphGroup {
  id: string;
  displayName: string;
}

let cachedMemberOf: Promise<string[]> | null = null;

function loadMemberOf(context: WebPartContext): Promise<string[]> {
  if (cachedMemberOf) return cachedMemberOf;
  cachedMemberOf = context.msGraphClientFactory
    .getClient('3')
    .then((client: MSGraphClientV3) =>
      client.api('/me/transitiveMemberOf').select('id,displayName').get()
    )
    .then((response: { value: IGraphGroup[] }) =>
      (response.value || []).map(g => g.displayName).filter(Boolean)
    )
    .catch((err: unknown) => {
      // Fail-closed: if Graph fails, hide audience-targeted content
      // rather than leaking it. Matches SharePoint's behavior on
      // unresolved audience tokens.
      console.warn('[useAudience] /me/transitiveMemberOf failed', err);
      return [];
    });
  return cachedMemberOf;
}

export function useAudience(context: WebPartContext, cfg: IAudienceConfig): IAudienceState {
  const [state, setState] = React.useState<IAudienceState>({
    loading: true,
    visible: false,
    matchedGroups: [],
  });

  React.useEffect(() => {
    let cancelled = false;
    loadMemberOf(context).then(memberGroups => {
      if (cancelled) return;
      const matched = cfg.groups.filter(g => memberGroups.includes(g));
      const visible =
        cfg.groups.length === 0
          ? true
          : cfg.mode === 'all'
            ? matched.length === cfg.groups.length
            : matched.length > 0;
      setState({ loading: false, visible, matchedGroups: matched });
    });
    return () => { cancelled = true; };
  }, [context, cfg.groups.join('|'), cfg.mode]);

  return state;
}

/**
 * Helper for use outside a component (e.g., extension that decides
 * whether to inject a placement at all).
 */
export async function evaluateAudience(
  context: WebPartContext,
  cfg: IAudienceConfig
): Promise<boolean> {
  const memberGroups = await loadMemberOf(context);
  if (cfg.groups.length === 0) return true;
  const matched = cfg.groups.filter(g => memberGroups.includes(g));
  return cfg.mode === 'all' ? matched.length === cfg.groups.length : matched.length > 0;
}
