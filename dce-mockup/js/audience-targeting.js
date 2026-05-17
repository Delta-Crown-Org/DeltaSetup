/*
 * audience-targeting.js — mirrors SharePoint's audience-targeting behavior
 *
 * Each section on a mockup page has data-audience="GroupA|GroupB" listing
 * the groups whose members may see the section. SharePoint resolves this
 * server-side; we resolve it in the browser against the current persona's
 * groups (from identity.js).
 *
 * Special tokens:
 *   data-audience="*"           — visible to all (default behavior)
 *   data-audience-mode="any"    — default; OR semantics across groups
 *   data-audience-mode="all"    — AND semantics across groups (rare)
 *
 * NOTE: Per Microsoft's official audience-targeting doc, "audience
 * targeting does not prevent unauthorized access; users with permission
 * can still reach the content via direct link or search." This module
 * deliberately uses .display=none rather than removing elements, to
 * mirror that mental model — the markup is still in the DOM, just hidden.
 * For real confidentiality, use a permission break (05-permissions-model.md).
 */

(function (global) {
  'use strict';

  const ALL_AUDIENCES_TOKEN = '*';

  function parseAudience(node) {
    const raw = (node.getAttribute('data-audience') || '').trim();
    if (!raw || raw === ALL_AUDIENCES_TOKEN) return { all: true, groups: [] };
    const groups = raw.split('|').map(g => g.trim()).filter(Boolean);
    return { all: false, groups: groups };
  }

  function matchAudience(audienceCfg, mode, personaGroups) {
    if (audienceCfg.all) return true;
    if (audienceCfg.groups.length === 0) return true;
    if (mode === 'all') {
      return audienceCfg.groups.every(g => personaGroups.includes(g));
    }
    return audienceCfg.groups.some(g => personaGroups.includes(g));
  }

  function evaluatePage(persona) {
    const personaGroups = persona.groups || [];
    const nodes = document.querySelectorAll('[data-audience]');
    let visibleCount = 0;
    let hiddenCount = 0;

    nodes.forEach(node => {
      const cfg = parseAudience(node);
      const mode = node.getAttribute('data-audience-mode') || 'any';
      const visible = matchAudience(cfg, mode, personaGroups);

      if (visible) {
        node.setAttribute('data-audience-visible', 'true');
        visibleCount++;
        // Show the actual content; hide the empty-slot placeholder if any
        const slot = node.querySelector(':scope > .dce-empty-slot');
        if (slot) slot.style.display = 'none';
        const body = node.querySelector(':scope > .dce-audience-body');
        if (body) body.style.display = '';
      } else {
        node.setAttribute('data-audience-visible', 'false');
        hiddenCount++;
      }
    });

    return { visibleCount, hiddenCount };
  }

  function annotateAudienceLabels() {
    /*
     * Adds a small "Audience: GROUPS" label inline when the diagnostic
     * mode is on. Helps Tyler verify the rubric at a glance.
     */
    const nodes = document.querySelectorAll('[data-audience]');
    nodes.forEach(node => {
      if (node.querySelector(':scope > .dce-audience-debug')) return;
      const raw = node.getAttribute('data-audience') || '*';
      if (raw === '*') return;
      const tag = document.createElement('span');
      tag.className = 'dce-audience-debug';
      tag.style.cssText = 'font-size:10px;font-family:ui-monospace,monospace;background:var(--color-brand-secondary);color:var(--_dce-teal-deeper);padding:2px 6px;border-radius:3px;margin-left:8px;font-weight:700;letter-spacing:0.04em;vertical-align:middle;display:none;';
      tag.textContent = 'aud=' + raw;
      const heading = node.querySelector('.dce-section-header__title');
      if (heading) heading.appendChild(tag);
    });
  }

  function setDiagnostics(on) {
    document.body.toggleAttribute('data-show-empty-slots', on);
    document.querySelectorAll('.dce-audience-debug').forEach(el => {
      el.style.display = on ? '' : 'none';
    });
  }

  const Audience = {
    evaluatePage,
    setDiagnostics,
    annotateAudienceLabels,
  };

  // Auto-evaluate on persona change
  document.addEventListener('DOMContentLoaded', () => {
    Audience.annotateAudienceLabels();
    if (global.DceIdentity) {
      Audience.evaluatePage(global.DceIdentity.getCurrent());
    }
  });

  document.addEventListener('dce:persona-changed', (e) => {
    Audience.evaluatePage(e.detail);
  });

  global.DceAudience = Audience;
})(typeof window !== 'undefined' ? window : globalThis);
