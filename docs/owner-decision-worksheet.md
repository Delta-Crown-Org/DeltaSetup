# Delta Crown Owner Decision Worksheet

**Status date:** 2026-05-12  
**Tracking bead:** `DeltaSetup-gf9`  
**Purpose:** turn remaining owner-decision debt into explicit yes/no/options decisions.

This worksheet does **not** authorize tenant changes by itself. It gives Tyler / Megan / owners a short list of decisions needed before full production launch claims are safe.

An Excel version is available at `generated/delta-crown-owner-decision-workbook.xlsx`. Regenerate it with:

```bash
python3 tools/generate_owner_decision_workbook.py
```

## Decision summary

| ID | Decision | Current state | Recommended default | Owner needed |
|---|---|---|---|---|
| OD-001 | GitHub default branch / stale `main` | Remote default is `main`; current canonical work is `gh-pages`. | Change repo default to `gh-pages` or make `main` an explicit redirect/archive branch. | Tyler / repo owner |
| OD-002 | Brand Resources vs Brand Assets model | Docs target `Brand Resources`; tenant has `Brand Assets` and legacy ClientServices artifacts. | Use `Brand Resources` as user-facing destination concept; keep Marketing `Brand Assets` as execution library if needed. | Tyler + business/content owner |
| OD-003 | Dynamic security group owners | `AllStaff`, `Managers`, `Marketing`, `Stylists`, `External` have 0 owners in Graph. | Assign at least two owners: MSP/operator + business owner. | Tyler / Megan |
| OD-004 | DLP test mode vs enforce | `DCE-Data-Protection` and `Corp-Data-Protection` are `TestWithNotifications`; `External-Sharing-Block` is enabled. | Review raw rule details, then schedule staged enforce flip. | Tyler + security/compliance owner |
| OD-005 | `DeltaCrown-TeamsProvisioner-TEMP` app fate | App exists with 3 expired credentials dated 2026-04-16. | Delete app if no dependency; otherwise rename/document owner and remove expired secrets. | Tyler / tenant app owner |
| OD-006 | ClientServices deprecation banner / cleanup | Empty legacy lists/libraries exist; broad inherited permissions documented; client records are out of M365 scope. | Add visible deprecation/owner note before any repurpose/archive/delete action. | Tyler + data/content owner |

## OD-001 — GitHub default branch / stale `main`

### Evidence

```text
Remote HEAD branch: main
Canonical active branch: gh-pages
Live site branch: gh-pages
```

The README already warns that `gh-pages` is current and `main` is abandoned legacy architecture.

### Risk

Future operators may land on `main`, read stale architecture, and make decisions from the wrong branch. That is how repos become haunted houses with YAML wallpaper.

### Options

| Option | Description | Pros | Cons |
|---|---|---|---|
| A | Change GitHub default branch to `gh-pages`. | Most direct; repo landing page matches current work. | Requires repo admin action. |
| B | Keep default `main`, replace `main` README with hard redirect to `gh-pages`. | Lower risk if branch policy cannot change. | Still leaves users one click away from stale files. |
| C | Archive/delete stale `main` after preserving tag. | Cleanest long-term. | Higher governance risk; needs explicit approval. |

### Recommendation

Choose **Option A** if possible. If not, choose **Option B** immediately.

### Decision

```text
Selected option: TBD
Owner approval: TBD
Follow-up change issue: TBD
```

## OD-002 — Brand Resources vs Brand Assets model

### Evidence

- `docs/brand-resources-target-model.md` defines `Brand Resources` as the approved reference-material concept.
- `docs/clientservices-to-brand-resources-transition-plan.md` says ClientServices/client-record assumptions are legacy.
- `DEPLOYMENT-STATUS.md` and tenant evidence still include Marketing `Brand Assets` and legacy `dce-clientservices` artifacts.
- `docs/legacy-clientservices-cleanup-register.md` says live resources should not be renamed, deleted, or repurposed without inventory and owner approval.

### Risk

Without one vocabulary, users and MSP operators may confuse:

- approved reference material;
- marketing execution assets;
- legacy ClientServices artifacts;
- client records, which are out of Microsoft 365 scope.

### Options

| Option | Description | Use when |
|---|---|---|
| A | `Brand Resources` is the user-facing reference destination; `Brand Assets` remains a Marketing execution library. | Recommended if both concepts are useful. |
| B | Rename/consolidate everything to `Brand Resources`. | Only after tenant inventory proves no dependency/data risk. |
| C | Keep `Brand Assets` as the only user-facing term. | If business owners reject `Brand Resources`. |
| D | Defer until Teams/SharePoint owners attest current usage. | If owners cannot classify content yet. |

### Recommendation

Choose **Option A**: `Brand Resources` for staff reference, `Brand Assets` for marketing production/execution. Do not repurpose or rename `/sites/dce-clientservices` yet.

### Decision

```text
Selected option: TBD
Owner approval: TBD
Follow-up change issue: TBD
```

## OD-003 — Dynamic security group owners

### Evidence

Current owner count from Graph inventory:

| Group | Owners |
|---|---:|
| AllStaff | 0 |
| External | 0 |
| Managers | 0 |
| Marketing | 0 |
| Stylists | 0 |

Current membership state:

| Group | Members |
|---|---:|
| AllStaff | 6 |
| Managers | 1 |
| Marketing | 0 |
| Stylists | 0 |
| External | 0 |

### Risk

Ownerless dynamic groups create operational ambiguity. When membership is wrong, nobody is clearly accountable for the rule, the metadata, or the access fallout. “The admin” is not an owner model; it is a future incident report wearing a fake mustache.

### Options

| Option | Description |
|---|---|
| A | Assign two owners per group: MSP operator + business/access owner. |
| B | Assign one central identity owner for all dynamic groups. |
| C | Keep ownerless until broader metadata cleanup completes. |

### Recommendation

Choose **Option A** for production. Minimum owner pattern:

| Group | Recommended owner types |
|---|---|
| AllStaff | MSP identity operator + DCE operations/business owner |
| Managers | MSP identity operator + DCE leadership owner |
| Marketing | MSP identity operator + marketing owner |
| Stylists | MSP identity operator + salon/operations owner |
| External | MSP identity operator + vendor/partner access owner |

### Decision

```text
Selected option: TBD
Named owners: TBD
Follow-up change issue: TBD
```

## OD-004 — DLP test mode vs enforce

### Evidence

From `docs/delta-crown-compliance-inventory-summary.md`:

| Policy | Current mode |
|---|---|
| DCE-Data-Protection | TestWithNotifications |
| Corp-Data-Protection | TestWithNotifications |
| External-Sharing-Block | Enable |

### Risk

Test mode is useful during rollout, but it is not final enforcement. Public or owner-facing claims about DLP protection must distinguish tested policies from enforcing policies.

### Options

| Option | Description | Pros | Cons |
|---|---|---|---|
| A | Keep test mode for 30 days and review alerts. | Safer rollout. | Not fully enforced. |
| B | Flip both policies to enforce in one maintenance window. | Fastest production posture. | Higher false-positive/business interruption risk. |
| C | Enforce one policy first, then the other. | Staged risk reduction. | Takes longer. |
| D | Keep test mode indefinitely. | Avoids disruption. | Not production-grade protection. |

### Recommendation

Choose **Option C** unless the rule review shows very low risk. Review raw DLP rules first, then schedule staged enforcement.

### Decision

```text
Selected option: TBD
Policy order/window: TBD
Rollback owner: TBD
Follow-up change issue: TBD
```

## OD-005 — `DeltaCrown-TeamsProvisioner-TEMP` app fate

### Evidence

From `docs/delta-crown-security-apps-licenses-inventory-summary.md`:

```text
App registration: DeltaCrown-TeamsProvisioner-TEMP
Credentials: 3 password credentials, all expired on 2026-04-16
```

### Risk

Expired temporary apps are clutter at best and security/governance smell at worst. If it is no longer needed, delete it. If it is needed, it should not be named `TEMP` with expired secrets and no documented owner.

### Options

| Option | Description |
|---|---|
| A | Delete the app registration after dependency check. |
| B | Keep app, rename it, assign owner, remove expired credentials, document purpose. |
| C | Keep as-is temporarily with an expiration date and owner. |

### Recommendation

Choose **Option A** if Teams provisioning is complete and no automation depends on it. Otherwise choose **Option B**. Do not choose C unless there is a very short review deadline.

### Decision

```text
Selected option: TBD
Dependency owner: TBD
Follow-up change issue: TBD
```

## OD-006 — ClientServices deprecation banner / cleanup

### Evidence

- `docs/delta-crown-sharepoint-pnp-inventory-summary.md` documents ClientServices artifacts as empty metadata/list structures with broad inherited permissions.
- `docs/legacy-clientservices-cleanup-register.md` says ClientServices/client-record assumptions are legacy and client records are out of M365 scope.
- Current direction is Brand Resources, not client records in Microsoft 365.

### Risk

Users may interpret old ClientServices resources as approved places for client data. That conflicts with the current scope and creates compliance/story risk.

### Options

| Option | Description |
|---|---|
| A | Add a visible deprecation/banner page or site notice: do not use for client records; pending cleanup. |
| B | Remove navigation links only, leaving site untouched. |
| C | Archive or delete after owner approval. |
| D | Repurpose as Brand Resources after inventory and approval. |

### Recommendation

Choose **Option A** as the immediate safe tenant-facing signal, then decide between archive/replace/repurpose later. Do not delete or repurpose yet.

### Decision

```text
Selected option: TBD
Banner wording approved: TBD
Follow-up change issue: TBD
```

## Minimum owner meeting agenda

1. Pick OD-001 repo default branch option.
2. Approve OD-002 vocabulary: `Brand Resources` vs `Brand Assets` relationship.
3. Name OD-003 dynamic group owners.
4. Choose OD-004 DLP enforcement path and review window.
5. Choose OD-005 TEMP app cleanup path.
6. Choose OD-006 ClientServices immediate deprecation signal.
7. Decide whether Teams channel inventory will use licensed access or owner attestation.

## After decisions are made

Create separate change issues for any tenant-impacting work. Keep them small:

- one issue for repo default branch / README redirect;
- one issue for dynamic group owner assignment;
- one issue for DLP enforcement change;
- one issue for TEMP app cleanup;
- one issue for ClientServices banner/cleanup;
- one issue for Brand Resources implementation planning.

Do not mash all tenant changes into one heroic mega-ticket. Mega-tickets are where accountability goes to become compost.
