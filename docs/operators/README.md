# Operator-facing documentation (Phase 4 prep)

This folder hosts the **operator-facing** documentation for DCE — the
docs that Jenna (and any future operator) reads to run the system, as
distinct from the architect-facing docs in
[`docs/sharepoint-pnp-spec/`](../sharepoint-pnp-spec/) and the agent-facing
docs in [`docs/architecture/`](../architecture/).

## Status: drafts in flight

Every file in this folder with a `-DRAFT` suffix is **Phase 4 prep** —
written ahead of the Phase 4 handoff so that the documents exist before
they are needed. Final homes per the execution plan:

| Draft (here) | Final home (after dce-sharepoint repo exists) |
|---|---|
| `jenna-runbook-DRAFT.md` | `Delta-Crown-Org/dce-sharepoint/docs/operators/jenna-runbook.md` |
| `site-request-intake-DRAFT.md` | `Delta-Crown-Org/dce-sharepoint/docs/operators/site-request-intake.md` |

The migration is gated on `DeltaSetup-emj` (create the `dce-sharepoint`
repo), which is itself gated on `DeltaSetup-jn4` (ADR-006 cosign). Once
that chain unblocks, move the files to their final homes and replace
this folder's drafts with thin `MOVED: see <url>` stubs.

## Authoring principles

These docs are read by someone who is **not** Tyler. Therefore:

1. **No assumed context.** "Click the gear icon" not "go to the usual place."
2. **No assumed shortcuts.** Spell out the full path, full URL, full command.
3. **Every command is copy-pasteable.** No `<replace-this>` placeholders without an "if you're not sure, look here" pointer.
4. **Failure modes get equal billing with happy paths.** Every section answers "what if it doesn't work?" before declaring done.
5. **Escalation is named.** "Ask Tyler" is fine; "Ask someone" is not.

## Cross-references

- Architecture: [`docs/sharepoint-pnp-spec/`](../sharepoint-pnp-spec/)
- Decisions: [`docs/sharepoint-pnp-spec/decisions/`](../sharepoint-pnp-spec/decisions/)
- Runbooks (existing, system-level): [`docs/sharepoint-pnp-spec/10-runbooks.md`](../sharepoint-pnp-spec/10-runbooks.md)
- ADR-011 (notification suppression — operator-critical): [`decisions/011-notification-suppression-by-default.md`](../sharepoint-pnp-spec/decisions/011-notification-suppression-by-default.md)
