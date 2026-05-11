# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

## Public-page quality gates

Any change touching `index.html`, `operations.html`, `msp.html`, `css/`, or `js/` MUST pass all three before push:

```bash
python3 tests/accessibility_static_audit.py   # HTML structure + design-token contrast
python3 tests/browser_smoke_audit.py          # Layout/console/skip-link across viewports
python3 tests/accessibility_axe_audit.py      # axe-core WCAG 2.0/2.1/2.2 A+AA+AAA rule pass
```

All three exit non-zero on failure. The axe runner uses a vendored copy of
axe-core at `tests/vendor/axe.min.js` — no network needed at test time.
Incomplete (axe "could not auto-determine") findings are surfaced as WARN and
do not fail the gate; they belong in the manual AAA cert checklist
(`DeltaSetup-9gq`).

