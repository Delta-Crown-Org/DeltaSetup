# Quick Reference: SharePoint Hub & Spoke for Multi-Brand Franchise

## 🎯 Key Decisions at a Glance

| Question | Answer |
|----------|--------|
| **Hub Topology** | Hub-per-Brand + Shared Services Hub |
| **Provisioning** | PnP Tenant Templates + Site Designs |
| **Isolation** | Permission-based + Sensitivity Labels (Info Barriers not in Business Premium) |
| **Teams** | Brand Teams + Corporate Teams, all connected to respective hubs |
| **Max Sites per Hub** | ~2,000 (performance threshold) |
| **Max Hub Sites** | 2,000 per tenant |
| **Max Nav Links** | 100 recommended (hard limit 500) |

---

## 📊 Critical Limits (Microsoft Official)

| Limit | Value | Notes |
|-------|-------|-------|
| Hub sites per organization | **2,000** | Soft limit |
| Sites per hub (search scope) | **~2,000** | Performance degrades beyond |
| Navigation depth | **3 levels** | Recommended: 2 levels |
| Navigation links | **100 recommended** (500 hard) | UX degrades above 100 |
| Sites web part | **99 maximum** | Hard limit |
| Document libraries | **2,000 per site collection** | Per site |
| Files/folders per library | **30 million** | Storage limit |

---

## 🏗️ Recommended Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 CORPORATE SHARED SERVICES HUB                │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │ HR Hub  │ │  IT Hub │ │Fin. Hub │ │Training │           │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘           │
└───────┼───────────┼───────────┼───────────┼────────────────┘
        │           │           │           │
        └───────────┴───────────┴───────────┘
                    │ (Cross-brand access)
        ┌───────────┴───────────┐
        ▼                       ▼
┌───────────────┐       ┌───────────────┐
│  BRAND A HUB  │       │  BRAND B HUB  │
│  ┌─────────┐  │       │  ┌─────────┐  │
│  │ Ops Site│  │       │  │ Ops Site│  │
│  │Location1│  │       │  │Location1│  │
│  │Location2│  │       │  │Location2│  │
│  │ Team    │  │       │  │ Team    │  │
│  └─────────┘  │       │  └─────────┘  │
└───────────────┘       └───────────────┘
```

---

## ⚠️ Critical Business Premium Constraints

| Feature | Business Premium | Workaround |
|---------|-----------------|------------|
| Information Barriers | ❌ Not included | Use permission-based isolation |
| Multi-Geo | ❌ Not available | Single geography only |
| Advanced Audit | ❌ Not available | Basic audit only |
| User Limit | 300 maximum | Plan accordingly |

---

## 🔐 Security Model for Multi-Brand

### Layer 1: Permissions
- Each brand = separate site collections
- Brand users = owners/members of their sites only
- No cross-brand site ownership

### Layer 2: Sensitivity Labels
```
PUBLIC
├─ BRAND A - INTERNAL (auto-apply to Brand A sites)
├─ BRAND B - INTERNAL (auto-apply to Brand B sites)
└─ CORPORATE CONFIDENTIAL (shared services)
```

### Layer 3: DLP Policies
- Brand-scoped policies
- Block sharing between brands
- Audit external sharing attempts

---

## 🛠️ Provisioning Approach

### PnP Tenant Template (Full Brand Deployment)
```powershell
# Deploy complete brand workspace
Apply-PnPTenantTemplate -Path "BrandTemplate.xml"
```

**Includes**:
- Teams team with channels
- SharePoint hub site
- Associated sites
- Content types
- Navigation
- Branding

### Site Design (Self-Service)
- "Location Site" template
- "Department Site" template
- "Project Site" template

---

## 📋 10-Week Implementation Roadmap

| Week | Phase | Key Activities |
|------|-------|---------------|
| 1-2 | Foundation | Create hubs, configure labels |
| 3-4 | Pilot | Deploy to pilot brand, gather feedback |
| 5 | Refinement | Update templates, finalize governance |
| 6-8 | Rollout | Deploy to all brands |
| 9 | Integration | Connect shared services |
| 10+ | Optimize | Monitor, improve, expand |

---

## ❓ Common Questions Answered

### Q: Can a site belong to multiple hubs?
**A**: No. One site = One hub association. Content can appear on multiple hubs via web parts.

### Q: Do hub sites change permissions of associated sites?
**A**: No. Hub association does NOT alter site permissions. Add "reader" group to hub for easier read access.

### Q: Can we use Information Barriers with Business Premium?
**A**: No. Information Barriers require E5 or compliance add-ons. Use permission-based isolation instead.

### Q: How do Teams private channels work with hubs?
**A**: Private channels create separate SharePoint sites with independent permissions. Evaluate hub association case-by-case.

### Q: What's the difference between PnP Site Templates and Tenant Templates?
**A**: Site Templates = site-level provisioning. Tenant Templates = tenant-level (can include Teams, Azure AD, etc.).

---

## 📚 Full Documentation

For detailed analysis, see:
- [README.md](./README.md) - Executive summary
- [analysis.md](./analysis.md) - Multi-dimensional analysis
- [recommendations.md](./recommendations.md) - Implementation guidance
- [sources.md](./sources.md) - Source credibility assessment
- [raw-findings/](./raw-findings/) - Extracted source content

---

*Quick Reference v1.0 - April 2025*
*Based on Microsoft Learn, PnP Community resources, and SharePoint architecture best practices*
