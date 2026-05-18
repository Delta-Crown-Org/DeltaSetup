/**
 * DceHubHomeWebPart — composes the DCE Hub home page sections into a
 * single SPFx web part. Mirrors the section order of mockups/index.html.
 *
 * Section-to-component map:
 *   1. Hero               → <DceHero />
 *   2. Quick links strip  → <DceQuicklinks />              (TODO)
 *   3. KPI tiles          → <AudienceGate><DceKpiRow /></AudienceGate>
 *   4. News               → <DceNewsFeed />                (TODO)
 *   5. Owner spotlight    → <DcePeopleSpotlight />         (TODO)
 *   6. Events             → <DceEventList />               (TODO)
 *   7. Ops alerts         → <AudienceGate><DceNewsFeed kind="ops" /></AudienceGate>
 *   8. Brand resources    → <DceCardGrid />                (TODO)
 *   9. Footer             → handled by Application Customizer, not this web part
 *
 * Reuse note: Heft build pipeline, deploy-spfx.ps1, package.json
 * pins all come from Convention-Page-Build/spfx/. Strip HTT-specific
 * tokens, replace with the import from ./theme/dce-tokens.
 */

import { Version } from '@microsoft/sp-core-library';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';
import * as React from 'react';
import * as ReactDom from 'react-dom';
import { ThemeProvider } from '@fluentui/react';

import { dceTheme } from './theme/fluentui-theme-dce';
import { DceHero } from './components/DceHero';
import { DceKpiTile } from './components/DceKpiTile';
import { AudienceGate } from './components/AudienceGate';

export interface IDceHubHomeWebPartProps {
  // Web part properties — exposed in the property pane.
  // Intentionally minimal in the skeleton.
  heroTitle: string;
}

export default class DceHubHomeWebPart extends BaseClientSideWebPart<IDceHubHomeWebPartProps> {

  public render(): void {
    const element = React.createElement(ThemeProvider, { theme: dceTheme },
      React.createElement(React.Fragment, null,

        // Section 1 — Hero (audience: all)
        React.createElement(DceHero, {
          eyebrow: 'Delta Crown Extensions · Operations Hub',
          title: this.properties.heroTitle || "Everything you need to run your day.",
          subtitle: 'Brand, operations, and people — one place. Audience-aware, cross-tenant-ready.',
          logoUrl: '/sites/dce-hub/SiteAssets/logo-dce-white.svg',
          primaryCta: { label: "View today's priorities", href: '#kpis' },
          secondaryCta: { label: 'Open Crown Connection →', href: '/sites/CrownConnection' },
        }),

        // Section 3 — KPI tiles (audience: R1/R2/R3/R4 only)
        React.createElement(AudienceGate, {
          context: this.context,
          groups: ['DCE-Site-Owners', 'DCE-Franchisor-Leadership', 'DCE-Franchise-Owners', 'DCE-Managers', 'Tenant Global Admins'],
          mode: 'any',
          children: React.createElement('div', { style: { display: 'grid', gap: 16, gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', padding: 32 } },
            React.createElement(DceKpiTile, { label: 'Active owners', stat: '5', trendDirection: 'up', trendText: '+1 this month' }),
            React.createElement(DceKpiTile, { label: "Today's bookings", stat: '94', trendDirection: 'up', trendText: '12% WoW' }),
            React.createElement(DceKpiTile, { label: 'Open tickets', stat: '3', trendDirection: 'down', trendText: '5 from yesterday' }),
            React.createElement(DceKpiTile, { label: "This week's NPS", stat: '72', trendDirection: 'up', trendText: '+4 pts' })
          ),
        }),

        // TODO: Sections 2, 4, 5, 6, 7, 8 — see component list in
        // 03-design-system.md § Component library — first wave.
      )
    );

    ReactDom.render(element, this.domElement);
  }

  protected onDispose(): void {
    ReactDom.unmountComponentAtNode(this.domElement);
  }

  protected get dataVersion(): Version {
    return Version.parse('1.0');
  }
}
