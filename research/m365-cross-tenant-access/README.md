# M365 / Entra ID Cross-Tenant Access Research

**Date:** 2025-08-08  
**Researcher:** Web-Puppy (`web-puppy-b2e0e5`)  
**Project context:** Franchise / multi-brand Microsoft 365 architecture work in this repo, with emphasis on SharePoint, Teams, cross-tenant collaboration, and operational guardrails.

## Executive summary

This update focuses on four Microsoft Learn–anchored topics requested for deeper follow-up:

1. **Multitenant organization (MTO) vs non-MTO patterns**
2. **Cross-tenant sync attribute mapping and `userType` behavior**
3. **Deny-by-default cross-tenant access posture**
4. **Cross-tenant sync failure modes and order-of-operations gotchas**

## Direct answers

### Topic 1: What is MTO, and how is it different from standard cross-tenant sync?
- A **multitenant organization (MTO)** is an Entra/Microsoft 365 feature that creates an explicit organizational boundary around multiple tenants your organization owns.
- MTO is **not the same thing** as cross-tenant sync:
  - **MTO** = a higher-level grouping/boundary plus Microsoft 365 collaboration semantics.
  - **Cross-tenant sync** = the provisioning engine that creates/updates/deletes B2B users across tenants.
- Microsoft says the two are **independent**, but MTO’s best experience generally relies on **B2B member provisioning**, often via cross-tenant sync.
- MTO enables differentiated **“in-organization”** user treatment plus improved experiences in **new Teams** and **Viva Engage** that standard cross-tenant sync alone does not create.
- For a **franchise / brand** scenario, use **MTO only when the tenants are truly one organization with high trust and near-internal collaboration expectations**. If brands are semi-independent, selectively connected, or need narrow app/resource sharing, use **standard cross-tenant sync + partner-specific cross-tenant access settings** without assuming MTO.

### Topic 2: What can be mapped in cross-tenant sync, and how does `userType` behave?
- Microsoft documents that cross-tenant sync can map **commonly used Entra user attributes**, including `displayName`, `userPrincipalName`, directory extension attributes, and `manager` in supported clouds/scenarios.
- `userType` can be mapped to:
  - **Member**: external member in target tenant; more internal-like behavior.
  - **Guest**: external guest in target tenant.
- Important gotcha: **existing B2B guests do not automatically flip to Member** unless the mapping is configured with **Apply this mapping = Always**.
- `showInAddressList` is especially important for Microsoft 365 people search and Outlook visibility; Microsoft says it defaults to **true** in cross-tenant sync mappings.
- `IsSoftDeleted` matters operationally because users that fall out of scope are **soft deleted** in the target tenant; that deprovisioning is easy to trigger accidentally by changing assignment, group membership, or scoping filters.

### Topic 3: What does deny-by-default mean for cross-tenant access?
- Microsoft’s documented defaults are **not a full deny-by-default posture for B2B collaboration**. By default, B2B collaboration with other Entra tenants is enabled.
- A deliberate **deny-by-default** posture therefore means **changing the default inbound/outbound B2B collaboration settings to block**, then adding only required partners under **Organizational settings**.
- Microsoft says **organization-specific settings take precedence over default settings**.
- So if you **block inbound by default** but create a **partner-specific allow override**, that partner override wins for that organization.
- Big warning from Microsoft: changing defaults to block can break existing business-critical access, so this must be done only after log review and partner inventory.

### Topic 4: What are common cross-tenant sync failure modes?
- The most common setup failures are **policy prerequisite failures**, not mapping failures:
  - target tenant did not enable **Allow user synchronization into this tenant**
  - source and/or target did not enable **automatic redemption** correctly
- Microsoft’s configure doc shows `AzureActiveDirectoryCrossTenantSyncPolicyCheckFailure` when:
  - the **source tenant** has not enabled outbound automatic redemption
  - the **target tenant** has not enabled inbound sync / inbound policy prerequisites
- Cross-tenant sync can also fail later operationally because of:
  - users falling **out of scope**, triggering soft deletion
  - **contact object collisions** at scale
  - **quarantine** when provisioning is unhealthy
  - userType/address-list expectations not matching M365 behavior
- Order matters: **inbound sync + auto redemption first, then source outbound auto redemption, then mapping/testing, then production scope**.

## Best-fit conclusion for this repo’s franchise scenario

For this project’s multi-brand / franchise context, the safest Microsoft-aligned pattern is:

- **Use standard cross-tenant sync + partner-specific cross-tenant access settings** as the baseline.
- Use **`userType=Member`** only for brands/users that should operate like one workforce.
- Use **MTO** only if the participating tenants are genuinely one enterprise boundary and you want the added Teams/Viva/M365 “in-organization” semantics.
- Use a **deny-by-default default policy** only if you can operationally maintain partner-specific overrides and have reviewed existing dependencies.
- Treat **scope changes, auto-redemption settings, and inbound sync enablement** as the key order-of-operations risks.

## Files
- `sources.md`
- `analysis.md`
- `recommendations.md`
- `raw-findings/microsoft-learn-quotes.md`
