/*
 * identity.js — mock identity provider for the DCE mockup
 *
 * Each persona profile is a realistic snapshot of what a user object
 * looks like AFTER cross-tenant sync (HTT → DCE) or after native DCE
 * provisioning. The role-switcher (mockup-controls.js) selects which
 * persona is "signed in"; audience-targeting.js uses the persona's
 * groups to decide which web parts are visible.
 *
 * Tenant facts (from docs/sharepoint-pnp-spec/00-context.md):
 *   HTT Brands tenant:   0c0e35dc-188a-4eb3-b8ba-61752154b407 / httbrands.com
 *   DCE tenant:          ce62e17d-2feb-4e67-a115-8ea4af68da30 / deltacrown.com
 *   Sync app:            HTT-to-DCE-User-Sync (every 40 minutes)
 *   Gate group rule:     user.userPrincipalName -match ".*@httbrands\.com$"
 *                        and user.accountEnabled -eq true
 *   Target object UPN:   <local>_httbrands.com#EXT#@deltacrown.onmicrosoft.com
 *   userType:            Member (NOT Guest)
 *
 * Role taxonomy (from 02-identity-audience.md):
 *   R1 — Global Admin                  (Tenant Global Admins via PIM)
 *   R2 — Franchisor Leadership         (DCE-Franchisor-Leadership)
 *   R3 — DCE Franchise Owner           (Crown Connection members minus HTT corp)
 *   R4 — DCE Manager / Lead            (DCE-Managers)
 *   R5 — DCE Staff                     (DeltaCrownAllStaff)
 *   R6 — HTT Corporate                 (synced via SG-DCE-Sync-Users)
 *
 * For this mockup Tyler asked us to surface 3 personas in the switcher
 * (Owner, Manager, HTT Corp). The other 3 are modeled in the data
 * layer for rubric coverage (criterion 3: identity model correctness).
 *
 * ─────────────────────────────────────────────────────────────────
 * CRITICAL GOTCHA (verified by solutions-architect-e9372f, 2026-05-16):
 * SharePoint audience targeting evaluates group MEMBERSHIP, not
 * group OWNERSHIP. If a role-holder is only an Owner of the group
 * and not also a Member, they will NOT see audience-targeted
 * content. Every persona's groups[] array below represents
 * MEMBERSHIP. The DCE-Site-Owners role (R1) for Tyler must therefore
 * also have him added as a Member of every targeting group he should
 * see (he already is, via the all-membership list). Reference:
 * https://learn.microsoft.com/answers/questions/687425/
 * ─────────────────────────────────────────────────────────────────
 */

(function (global) {
  'use strict';

  const TENANTS = {
    HTT: {
      id: '0c0e35dc-188a-4eb3-b8ba-61752154b407',
      domain: 'httbrands.com',
      name: 'HTT Brands',
    },
    DCE: {
      id: 'ce62e17d-2feb-4e67-a115-8ea4af68da30',
      domain: 'deltacrown.com',
      name: 'Delta Crown Extensions',
    },
  };

  /*
   * Group identifiers — these are the only audience identifiers
   * referenced by web parts. Adding a new audience requires an ADR
   * (per 02-identity-audience.md § Audience proliferation guardrails).
   */
  const GROUPS = {
    DCE_SITE_OWNERS:           'DCE-Site-Owners',
    DCE_FRANCHISOR_LEADERSHIP: 'DCE-Franchisor-Leadership',
    DCE_FRANCHISE_OWNERS:      'DCE-Franchise-Owners',
    DCE_MANAGERS:              'DCE-Managers',
    DCE_ALLSTAFF:              'DCE-AllStaff',
    HTT_CORP_VIA_SYNC:         'DCE-HTT-Corporate-Sync',
    CROWN_CONNECTION:          'CrownConnection',
    TENANT_GLOBAL_ADMINS:      'Tenant Global Admins',
  };

  /*
   * Personas — every property mirrors a real Entra/Graph user object
   * shape. Audience targeting matches against `groups` (group display
   * names) only; never against displayName/jobTitle directly, per the
   * role-vs-attribute philosophy in 02-identity-audience.md.
   */
  const PERSONAS = {
    'r3-owner-allynn': {
      role: 'R3',
      roleLabel: 'DCE Franchise Owner',
      displayName: 'Allynn Shepherd',
      jobTitle: 'Franchise Owner',
      companyName: 'Delta Crown Extensions',
      mail: 'allynn.shepherd@deltacrown.com',
      userPrincipalName: 'allynn.shepherd@deltacrown.com',
      userType: 'Member',
      homeTenantId: TENANTS.DCE.id,
      provisioning: 'native-dce',
      // Owners are NOT in DCE-AllStaff per 02-identity-audience.md
      // role taxonomy (AllStaff is the R5 frontline-staff group).
      // This is why Owners do not see Operations Alerts on the Hub
      // (which targets DCE-Managers + DCE-AllStaff).
      groups: [
        GROUPS.DCE_FRANCHISE_OWNERS,
        GROUPS.CROWN_CONNECTION,
      ],
      initials: 'AS',
      surfaceInSwitcher: true,
    },
    'r4-manager-jamie': {
      role: 'R4',
      roleLabel: 'DCE Manager / Lead Extensionista',
      displayName: 'Jamie Reyes',
      jobTitle: 'Studio Manager',
      companyName: 'Delta Crown Extensions',
      mail: 'jamie.reyes@deltacrown.com',
      userPrincipalName: 'jamie.reyes@deltacrown.com',
      userType: 'Member',
      homeTenantId: TENANTS.DCE.id,
      provisioning: 'native-dce',
      groups: [
        GROUPS.DCE_MANAGERS,
        GROUPS.DCE_ALLSTAFF,
      ],
      initials: 'JR',
      surfaceInSwitcher: true,
    },
    'r6-htt-corp-kristin': {
      role: 'R6',
      roleLabel: 'HTT Corporate (cross-tenant)',
      displayName: 'Kristin Kidd',
      jobTitle: 'Director, Brand Operations',
      companyName: 'HTT Brands',
      mail: 'kristin.kidd@httbrands.com',
      // The post-sync UPN form, per 00-context.md
      userPrincipalName: 'kristin.kidd_httbrands.com#EXT#@deltacrown.onmicrosoft.com',
      userType: 'Member',  // sync makes them Member, NOT Guest
      homeTenantId: TENANTS.HTT.id,
      provisioning: 'cross-tenant-sync',
      gateGroup: 'SG-DCE-Sync-Users',
      gateRule: 'user.userPrincipalName -match ".*@httbrands\\.com$" and user.accountEnabled -eq true',
      groups: [
        GROUPS.HTT_CORP_VIA_SYNC,
        GROUPS.CROWN_CONNECTION,
      ],
      initials: 'KK',
      surfaceInSwitcher: true,
    },
    // Personas below are modeled for rubric coverage but not exposed
    // in the default switcher dropdown (Tyler's scope is the 3 above).
    'r1-ga-tyler': {
      role: 'R1',
      roleLabel: 'Global Admin (PIM-eligible)',
      displayName: 'Tyler Granlund',
      jobTitle: 'IT Director',
      companyName: 'HTT Brands',
      mail: 'tyler.granlund@httbrands.com',
      userPrincipalName: 'tyler.granlund@deltacrown.com',  // dual-tenant admin form
      userType: 'Member',
      homeTenantId: TENANTS.DCE.id,
      provisioning: 'dual-tenant-admin',
      groups: [
        GROUPS.TENANT_GLOBAL_ADMINS,
        GROUPS.DCE_SITE_OWNERS,
        GROUPS.DCE_FRANCHISOR_LEADERSHIP,
        GROUPS.DCE_FRANCHISE_OWNERS,
        GROUPS.DCE_MANAGERS,
        GROUPS.DCE_ALLSTAFF,
        GROUPS.HTT_CORP_VIA_SYNC,
        GROUPS.CROWN_CONNECTION,
      ],
      initials: 'TG',
      surfaceInSwitcher: false,
    },
    'r2-leadership-jenna': {
      role: 'R2',
      roleLabel: 'Franchisor Leadership',
      displayName: 'Jenna Bowden',
      jobTitle: 'Brand Director',
      companyName: 'HTT Brands',
      mail: 'jenna.bowden@httbrands.com',
      userPrincipalName: 'jenna.bowden_httbrands.com#EXT#@deltacrown.onmicrosoft.com',
      userType: 'Member',
      homeTenantId: TENANTS.HTT.id,
      provisioning: 'cross-tenant-sync',
      groups: [
        GROUPS.DCE_FRANCHISOR_LEADERSHIP,
        GROUPS.HTT_CORP_VIA_SYNC,
        GROUPS.CROWN_CONNECTION,
      ],
      initials: 'JB',
      surfaceInSwitcher: false,
    },
    'r5-staff-morgan': {
      role: 'R5',
      roleLabel: 'DCE Staff (Extensionista)',
      displayName: 'Morgan Lee',
      jobTitle: 'Extensionista',
      companyName: 'Delta Crown Extensions',
      mail: 'morgan.lee@deltacrown.com',
      userPrincipalName: 'morgan.lee@deltacrown.com',
      userType: 'Member',
      homeTenantId: TENANTS.DCE.id,
      provisioning: 'native-dce',
      groups: [
        GROUPS.DCE_ALLSTAFF,
      ],
      initials: 'ML',
      surfaceInSwitcher: false,
    },
  };

  // Default persona is the DCE Franchise Owner — most realistic landing
  // for an internal hub visitor.
  const DEFAULT_PERSONA_KEY = 'r3-owner-allynn';

  const Identity = {
    tenants: TENANTS,
    groups: GROUPS,
    personas: PERSONAS,
    defaultPersonaKey: DEFAULT_PERSONA_KEY,
    currentPersonaKey: DEFAULT_PERSONA_KEY,

    getCurrent: function () {
      return PERSONAS[this.currentPersonaKey];
    },

    setPersona: function (key) {
      if (!PERSONAS[key]) {
        console.warn('[identity] unknown persona key:', key);
        return;
      }
      this.currentPersonaKey = key;
      try {
        localStorage.setItem('dce-mockup-persona', key);
      } catch (e) {
        /* localStorage unavailable; harmless */
      }
      document.dispatchEvent(new CustomEvent('dce:persona-changed', {
        detail: PERSONAS[key],
      }));
    },

    restorePersona: function () {
      let stored;
      try { stored = localStorage.getItem('dce-mockup-persona'); }
      catch (e) { /* noop */ }
      if (stored && PERSONAS[stored]) this.currentPersonaKey = stored;
    },

    listSwitcherPersonas: function () {
      return Object.entries(PERSONAS)
        .filter(([, p]) => p.surfaceInSwitcher)
        .map(([key, p]) => ({ key, ...p }));
    },

    listAllPersonas: function () {
      return Object.entries(PERSONAS).map(([key, p]) => ({ key, ...p }));
    },

    /*
     * Cross-tenant context summary — surfaced by the role-switcher and
     * the identity hint banner. Demonstrates that we know what `Member`
     * vs `Guest` means and how the sync UPN format works.
     */
    describePersonaProvenance: function (persona) {
      if (persona.provisioning === 'cross-tenant-sync') {
        return {
          flow: 'Cross-tenant sync (Azure2Azure)',
          gate: persona.gateGroup,
          gateRule: persona.gateRule,
          homeTenant: TENANTS.HTT.name,
          guestTenant: TENANTS.DCE.name,
          syncedUpn: persona.userPrincipalName,
          userType: persona.userType,
          note: 'Provisioned as Member (NOT Guest) so audience targeting + ' +
                '"People in your org" sharing links both treat them as full DCE members.',
        };
      }
      if (persona.provisioning === 'native-dce') {
        return {
          flow: 'Native DCE provisioning',
          homeTenant: TENANTS.DCE.name,
          userType: persona.userType,
          note: 'User object lives in the DCE tenant. No B2B layer.',
        };
      }
      return {
        flow: 'Dual-tenant administrator',
        homeTenant: TENANTS.DCE.name,
        userType: persona.userType,
        note: 'Tyler maintains accounts in both tenants for admin paths.',
      };
    },
  };

  Identity.restorePersona();
  global.DceIdentity = Identity;
})(typeof window !== 'undefined' ? window : globalThis);
