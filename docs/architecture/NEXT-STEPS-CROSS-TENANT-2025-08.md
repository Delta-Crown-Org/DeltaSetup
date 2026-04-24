# Next Steps: Cross-Tenant Architecture Follow-Through

## Purpose
This plan turns the new cross-tenant research into an execution sequence for DeltaSetup.

It is intentionally narrow:
- formalize the new architecture guidance
- add guardrail tests so we do not repeat known anti-patterns
- keep current single-tenant DCE work intact while preparing for future cross-tenant collaboration

## Current Reality
### Already done
- Baseline single-tenant DCE architecture documented in ADR-001 and ADR-002
- Second-pass cross-tenant research added under `research/cross-tenant-collaboration-m365/`
- Prior HTT lessons reviewed from:
  - `Convention-Page-Build`
  - `Cross-Tenant-Utility`

### Still needed
1. Formal architecture decision for cross-tenant collaboration overlay
2. Fitness tests for cross-tenant anti-patterns and required sequencing concepts
3. Reconciliation of existing ADR language so future work does not accidentally imply unsafe cross-tenant reuse
4. Follow-on implementation planning for tenant hardening and permission enforcement

## Recommended Execution Order

### Step 1 — Create ADR-004
**Issue:** `DeltaSetup-111`

Create:
- `docs/architecture/decisions/ADR-004-cross-tenant-collaboration-sharepoint-access.md`

#### Scope
ADR-004 should define:
- single-tenant baseline vs cross-tenant collaboration overlay
- B2B collaboration guests vs cross-tenant sync decision criteria
- B2B Direct Connect limitations for normal SharePoint access
- explicit anti-pattern prohibition on resource-tenant dynamic-group gating in inbound B2B partner policy
- order of operations for partner onboarding and first-run access
- guidance on where dynamic groups are safe (authorization) vs unsafe (admission)

#### Exit criteria
- ADR-004 exists in MADR format
- references ADR-001 and ADR-002 cleanly
- includes a decision outcome and consequences
- includes a concise security/risk section

---

### Step 2 — Add architecture fitness tests for ADR-004
**Issue:** `DeltaSetup-110`

Create:
- `tests/architecture/test_adr_004_cross_tenant_access.py`

#### Minimum test coverage
1. ADR-004 exists
2. ADR-004 references single-tenant baseline and cross-tenant overlay
3. ADR-004 forbids resource-tenant dynamic-group gating in inbound partner policy
4. ADR-004 states B2B Direct Connect is not the standard SharePoint site access model
5. ADR-004 documents bilateral automatic redemption when relevant
6. ADR-004 separates admission from authorization
7. ADR-004 documents order of operations
8. ADR-004 includes decision guidance for guest vs synced member patterns

#### Exit criteria
- tests run locally with pytest
- tests are narrow and doc-focused, not fake integration theater
- failures clearly point to missing architecture content

---

### Step 3 — Align future implementation planning to ADR-004
Once ADR-004 exists, revisit:
- security-hardening scripts
- permission matrix assumptions
- future multi-tenant or franchise-collaboration planning

#### Specific follow-up checks
- ensure no script/docs suggest inbound B2B group gating with resource-tenant dynamic groups
- ensure future external-collab plans distinguish:
  - guest access
  - cross-tenant sync
  - Teams shared channels / Direct Connect
- ensure attribute-driven authorization assumptions are documented if sync is ever introduced

#### Exit criteria
- no major architecture doc contradicts ADR-004
- future work items use the right pattern language

---

### Step 4 — Resume operational hardening work
This is separate from the cross-tenant architecture thread, but still one of the biggest practical completion items.

#### Still-open operational themes
- finalize SharePoint internal permission enforcement via PnP hardening
- validate DLP / PII handling in operational terms
- reconcile stale issue tracker state with actual deployed state

#### Exit criteria
- architecture and implementation planning stop drifting apart

## Proposed Short-Term Work Plan

### Session A
- Draft ADR-004
- Review against new research pack
- Commit ADR

### Session B
- Add `test_adr_004_cross_tenant_access.py`
- Run pytest
- Tighten wording if tests expose ambiguity

### Session C
- Reconcile existing docs / roadmap / operational status with ADR-004
- Decide whether any implementation issues should be opened for cross-tenant pilot planning

## Decision Rules Going Forward
1. **Default to single-tenant unless there is a real cross-tenant requirement.**
2. **Do not use B2B Direct Connect as a pretend SharePoint portal strategy.**
3. **Do not push authorization rules into inbound partner policy when they depend on resource-tenant post-provisioning state.**
4. **Use dynamic groups freely at the authorization layer, not the admission layer.**
5. **Pilot identity flows before broad rollout whenever sync or cross-tenant collaboration is introduced.**

## Suggested Immediate Next Move
Start `DeltaSetup-111` by drafting ADR-004.

That gives us the formal architecture source of truth first, then the tests, then any follow-on implementation alignment.
