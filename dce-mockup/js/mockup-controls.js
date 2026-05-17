/*
 * mockup-controls.js — wires up the role-switcher and identity badge.
 * These controls exist only in the Tier-B mockup; they are NOT ported
 * to SPFx. The SPFx implementation gets identity from window.context.
 */

(function (global) {
  'use strict';

  function renderIdentityBadge(persona) {
    const badge = document.getElementById('identityBadge');
    if (!badge) return;
    const tenantBadge = persona.companyName === 'HTT Brands' ? 'HTT' : 'DCE';
    badge.innerHTML = `
      <div class="sp-suitebar__identity-avatar" aria-hidden="true">${persona.initials}</div>
      <div>
        <div style="font-weight:700;">${escapeHtml(persona.displayName)}</div>
        <div style="opacity:0.7;font-size:10px;">${escapeHtml(persona.jobTitle)}</div>
      </div>
      <span class="sp-suitebar__org-pill" title="${escapeHtml(persona.companyName)}">${tenantBadge}</span>
    `;
    badge.title = persona.userPrincipalName;
  }

  function renderHintBanner(persona) {
    const banner = document.getElementById('identityHintBanner');
    if (!banner) return;
    if (!global.DceIdentity) return;
    const prov = global.DceIdentity.describePersonaProvenance(persona);
    let html;
    if (prov.flow === 'Cross-tenant sync (Azure2Azure)') {
      html = `
        <strong>Cross-tenant context:</strong>
        ${escapeHtml(persona.displayName)} signed in from
        <strong>${escapeHtml(prov.homeTenant)}</strong> and is browsing
        <strong>${escapeHtml(prov.guestTenant)}</strong>.
        Their object exists in DCE as <code>userType=Member</code> via
        cross-tenant sync (gate: <code>${escapeHtml(prov.gate)}</code>,
        every 40&nbsp;min). UPN form:
        <code style="word-break:break-all;">${escapeHtml(prov.syncedUpn)}</code>.
      `;
    } else if (prov.flow === 'Native DCE provisioning') {
      html = `
        <strong>Native context:</strong>
        ${escapeHtml(persona.displayName)} has a DCE-native account
        (<code>${escapeHtml(persona.userPrincipalName)}</code>). No B2B layer;
        audience targeting evaluates DCE group membership directly.
      `;
    } else {
      html = `
        <strong>Admin context:</strong>
        ${escapeHtml(persona.displayName)} maintains accounts in both tenants
        (HTT admin + DCE admin) and uses PIM to elevate when needed.
        Default scope on this page is read-only.
      `;
    }
    banner.innerHTML = html;
  }

  function renderRoleSwitcher() {
    if (!global.DceIdentity) return;
    const root = document.getElementById('roleSwitcher');
    if (!root) return;
    const personas = global.DceIdentity.listSwitcherPersonas();
    root.innerHTML = `
      <div class="role-switcher__header">
        <div class="role-switcher__title-row">
          <div class="role-switcher__title">Preview as…</div>
          <div class="role-switcher__subtitle">Audience targeting reacts live to your selection.</div>
        </div>
        <button class="role-switcher__collapse-btn" id="rsCollapseBtn" aria-label="Minimize role switcher">–</button>
      </div>
      <div class="role-switcher__body">
        <select id="personaSelect" class="role-switcher__select" aria-label="Choose a preview persona">
          ${personas.map(p =>
            `<option value="${p.key}">${escapeHtml(p.roleLabel)} — ${escapeHtml(p.displayName)}</option>`
          ).join('')}
        </select>
        <div id="personaDetails" class="role-switcher__details"></div>
        <label class="role-switcher__toggle-row">
          <input type="checkbox" id="diagToggle" />
          Show audience tags + hidden-section placeholders
        </label>
      </div>
    `;

    const select = document.getElementById('personaSelect');
    const collapseBtn = document.getElementById('rsCollapseBtn');
    const diagToggle = document.getElementById('diagToggle');

    select.value = global.DceIdentity.currentPersonaKey;
    select.addEventListener('change', (e) => {
      global.DceIdentity.setPersona(e.target.value);
    });

    collapseBtn.addEventListener('click', () => {
      root.classList.toggle('collapsed');
      collapseBtn.textContent = root.classList.contains('collapsed') ? '☰' : '–';
    });

    diagToggle.addEventListener('change', (e) => {
      if (global.DceAudience) global.DceAudience.setDiagnostics(e.target.checked);
    });
  }

  function renderPersonaDetails(persona) {
    const target = document.getElementById('personaDetails');
    if (!target || !global.DceIdentity) return;
    const prov = global.DceIdentity.describePersonaProvenance(persona);
    target.innerHTML = `
      <div><span>role:</span> ${escapeHtml(persona.role)} — ${escapeHtml(persona.roleLabel)}</div>
      <div><span>upn:</span> ${escapeHtml(persona.userPrincipalName)}</div>
      <div><span>userType:</span> ${escapeHtml(persona.userType)}</div>
      <div><span>provisioning:</span> ${escapeHtml(prov.flow)}</div>
      <div><span>groups:</span> ${persona.groups.map(escapeHtml).join(', ')}</div>
    `;
  }

  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  document.addEventListener('DOMContentLoaded', () => {
    renderRoleSwitcher();
    const persona = global.DceIdentity.getCurrent();
    renderIdentityBadge(persona);
    renderHintBanner(persona);
    renderPersonaDetails(persona);
  });

  document.addEventListener('dce:persona-changed', (e) => {
    renderIdentityBadge(e.detail);
    renderHintBanner(e.detail);
    renderPersonaDetails(e.detail);
  });
})(typeof window !== 'undefined' ? window : globalThis);
