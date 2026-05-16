# DCE SharePoint PnP — Agent Reference Pack

**Purpose.** This directory is a **self-contained reference pack** for any
AI agent (or human engineer) tasked with building or evolving the Delta
Crown Extensions SharePoint experience. It encodes the architecture,
identity model, audience-targeting rules, design tokens, PnP tooling
choices, CI/CD pipeline, quality gates, and deployment requirements
needed to ship the hub-and-spoke we've been designing.

**Why this exists.** Tyler is running a head-to-head between Code Puppy
(Claude / Anthropic) and ChatGPT 5.5 Pro to see whose plan converges
faster on a working, beautiful, sustainable DCE SharePoint
implementation. This pack is structured so both models read from the
same source of truth and produce comparable plans — which we'll then
diff against each other.

---

## How to use this pack

### If you are a human

Start at `PROMPT-PACK-FOR-AI.md`. That's the executive summary + the
delegation instructions to any AI you point at this directory. Then
read the numbered files in order (`00-` through `12-`).

### If you are an AI agent

1. Read `PROMPT-PACK-FOR-AI.md` first. It tells you what to build,
   what NOT to invent, and how your work will be evaluated against a
   competing model.
2. Read `EVALUATION-RUBRIC.md` to understand the scoring grid.
3. Read `00-context.md` for non-negotiable environmental facts.
4. Cross-reference the numbered chapters as you build. Each chapter
   is self-contained but assumes you've read `00-context.md`.
5. Don't re-invent — use `reference/existing-assets-inventory.md`
   to find prior art before scaffolding anything new.

### What "success" looks like

A working visual mock-up of the DCE SharePoint hub-and-spoke — built
either as PnP provisioning templates that apply to real sites, or as
hi-fi HTML/Figma-grade mockups that map cleanly to PnP/SPFx
implementation. Plus a runnable CI/CD pipeline scaffold. Plus an audit
trail showing the choices were grounded in this pack, not invented.

---

## Pack contents (canonical order)

| File | What it covers |
|---|---|
| `README.md` | This file. |
| `PROMPT-PACK-FOR-AI.md` | The handoff: instructions for the AI building the implementation. |
| `EVALUATION-RUBRIC.md` | How competing plans (Puppy vs ChatGPT) will be scored. |
| `00-context.md` | Tenant IDs, sites that exist, stakeholders, prior work. Read FIRST. |
| `01-architecture.md` | Hub-and-spoke topology. Sites, ownership, parenting. |
| `02-identity-audience.md` | Roles, audience-targeting model, who can see what. |
| `03-design-system.md` | DCE tokens, Fluent UI theme, typography, components. |
| `04-content-architecture.md` | Page templates, IA, navigation, search. |
| `05-permissions-model.md` | Permission inheritance, SharePoint groups, sharing. |
| `06-tooling-pnp.md` | PnP framework choices, versions, modules. |
| `07-ci-cd-pipeline.md` | GitHub Actions workflow, env model, deployment. |
| `08-quality-gates.md` | Playwright, axe-core, visual regression, smoke tests. |
| `09-deployment.md` | App registration, secrets, App Catalog, theme upload. |
| `10-runbooks.md` | Operational procedures (onboarding, branding change, audit). |
| `11-decisions/` | ADRs — each major decision with reasoning + alternatives rejected. |
| `12-implementation-plan.md` | Phased sprint plan with day-level granularity. |
| `reference/` | Token files (JSON), inventories, source-of-truth references. |
| `prompts/` | Reusable prompts for sub-tasks (theme generation, audit, etc.). |

## Non-goals (deliberately out of scope)

- Migrating off SharePoint Online to a different platform.
- Building a custom front-end framework from scratch (we use Fluent UI).
- Solving HTT Brands Headquarters' organisational mess directly (that's
  HTT-side work; we just don't replicate its anti-patterns).
- Building features the org doesn't yet need (YAGNI — and the SDLC team
  values it explicitly per AGENTS.md).

## Related work

- `docs/architecture/dce-sharepoint-design-roadmap.md` — the 6-phase
  strategic roadmap this spec implements.
- `docs/architecture/htt-dce-cross-tenant-sync-deep-dive.md` — the
  identity-sync plumbing that makes audience targeting possible.
- `/Users/tygranlund/dev/01-htt-brands/Convention-Page-Build/` — the
  HTT-side SPFx project we're forking patterns from.
- `/Users/tygranlund/dev/01-htt-brands/sharepointagent/` — the Python
  toolkit with existing SharePoint REST wrappers we can reuse.
