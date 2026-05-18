# ADR-010 — Lock SPFx components to Fluent UI v8

**Status:** Accepted
**Date:** 2026-05-18
**Decision-maker:** Tyler Granlund + code-puppy-73a4b6
**Implements:** `03-design-system.md`, `06-tooling-pnp.md`, `12-implementation-plan.md`
**Depends on:** ADR-006

---

## Context

The spec pack had a Fluent UI version mismatch:

- `03-design-system.md` and `06-tooling-pnp.md` called for Fluent UI v9
  (`@fluentui/react-components`).
- The reusable `Convention-Page-Build/spfx` scaffold pins Fluent UI v8
  (`@fluentui/react` 8.121.0).
- `dce-mockup/spfx-skeleton/README.md` already recorded ADR-006 final review
  evidence that v8 is the safer SPFx-aligned choice, but the skeleton code
  still imported v9 symbols.

SPFx 1.22.2 still runs on React 17.0.1. The real Sprint-1 delivery is PnP,
Brand Center, and first-party SharePoint web parts; custom SPFx is deferred
unless first-party parts cannot paint the picture. When SPFx is used, it must
match the known-good scaffold instead of introducing dependency churn.

## Decision

Lock DCE SPFx custom component work to **Fluent UI v8**:

```json
"@fluentui/react": "8.121.0"
```

Do **not** introduce `@fluentui/react-components` / Fluent UI v9 in Sprint 1
or in the first SPFx skeleton port.

## Consequences

- SPFx web parts use `ThemeProvider`, `createTheme`, and `ITheme` from
  `@fluentui/react`.
- Style Dictionary should emit a Fluent UI v8-compatible theme artifact for
  SPFx, plus the existing SharePoint theme JSON for tenant chrome.
- The v9 token artifact can be added later only if a future ADR approves a
  Fluent UI migration.
- Existing mockup HTML/CSS remains unaffected; this ADR only governs SPFx
  package dependencies and generated theme shape.
- Production SPFx package builds remain blocked until the Heft CI correction
  lands and the new `dce-sharepoint` repo has green validation.

## Alternatives considered

### A. Use Fluent UI v9 now

Rejected for Sprint 1. v9 aligns with current Microsoft design-system naming,
but it diverges from the reusable SPFx scaffold and increases dependency risk
while SPFx is explicitly deferred.

### B. Avoid Fluent UI completely

Rejected. SharePoint-native SPFx components should use Microsoft’s design
system rather than a bespoke component layer. Bespoke UI is how entropy buys a
condo.

### C. Lock Fluent UI v8

Accepted. This matches the known-good scaffold, keeps React 17 compatibility
straightforward, and supports the defer-SPFx strategy from ADR-005.

## Migration note

If Microsoft/SPFx guidance later makes Fluent UI v9 the lower-risk option,
write a superseding ADR that:

1. updates package pins,
2. replaces v8 `ThemeProvider` usage with v9 `FluentProvider`,
3. changes the Style Dictionary Fluent formatter,
4. runs SPFx build/a11y/browser gates in `dce-sharepoint`, and
5. records rollback steps back to v8.
