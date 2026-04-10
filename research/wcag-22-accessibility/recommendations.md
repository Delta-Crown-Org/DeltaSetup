# Accessibility & Content Organization Recommendations

## Executive Summary

This document provides prioritized, actionable recommendations for implementing WCAG 2.2 accessibility compliance and optimizing content organization for Delta Crown Extensions (DCE) franchise portals.

### Implementation Phases

| Phase | Timeline | Focus | Investment |
|-------|----------|-------|------------|
| Phase 1: Foundation | Weeks 1-4 | Critical WCAG fixes, core accessibility | 2-3 dev sprints |
| Phase 2: Testing Infrastructure | Weeks 5-8 | axe-core, manual testing setup | 1-2 dev sprints |
| Phase 3: Content Architecture | Weeks 9-12 | Taxonomy, governance UX | 2-3 dev sprints |
| Phase 4: Optimization | Ongoing | Continuous improvement | 10% of dev capacity |

---

## Priority 1: Critical WCAG 2.2 Requirements (Phase 1)

### 1.1 Focus Management (2.4.11, 2.4.13) 🔴

**Business Impact**: High - Required for keyboard users, affects all interactive content
**Implementation Effort**: Medium
**Timeline**: Weeks 1-2

#### Immediate Actions

```javascript
// 1. Implement scroll-padding for sticky headers
// In SharePoint CSS override
html {
  scroll-padding-top: 80px; /* Match header height */
  scroll-padding-bottom: 60px; /* Match footer height */
}

// 2. Ensure focus indicators meet 2.4.13
.ms-Fabric *:focus-visible {
  outline: 2px solid #0078D4;
  outline-offset: 2px;
}

// 3. Modal focus management
// When modal opens
document.body.style.overflow = 'hidden';
modal.setAttribute('aria-modal', 'true');
modal.querySelector('button, [href], input').focus();

// When modal closes
modal.setAttribute('aria-hidden', 'true');
triggerButton.focus();
```

#### Testing Checklist

- [ ] Tab through entire portal with sticky navigation present
- [ ] Verify focused elements are at least partially visible (2.4.11)
- [ ] Calculate focus indicator area (2px thick perimeter minimum)
- [ ] Verify 3:1 contrast for focus indicators (2.4.13)
- [ ] Test modals: focus trap and return on close

#### SharePoint-Specific Requirements

- [ ] Override default SharePoint focus styles
- [ ] Test with SharePoint app bar (global navigation)
- [ ] Verify command bar focus visibility
- [ ] Check quick launch focus indicators

---

### 1.2 Target Size (2.5.8) 🔴

**Business Impact**: Critical - Touch target requirements for mobile users
**Implementation Effort**: Low
**Timeline**: Week 1

#### Implementation

```css
/* Minimum target size: 24×24px */
.clickable-element {
  min-width: 24px;
  min-height: 24px;
}

/* Recommended for franchise portals: 44px for touch */
.portal-button {
  min-height: 44px;
  min-width: 44px;
  padding: 12px 16px;
}

/* Spacing exception pattern */
.icon-button {
  width: 20px;
  height: 20px;
  margin: 2px; /* Creates 24px effective target */
}
```

#### High-Priority Elements

1. **Document library action buttons**
2. **Navigation menu items**
3. **Modal close buttons**
4. **Form submission buttons**
5. **Checkbox/radio inputs**

#### Testing

```javascript
// Automated testing with axe-core
describe('Target Size', () => {
  it('meets WCAG 2.2 target size', async () => {
    await page.goto('/documents');
    const results = await new AxeBuilder({ page })
      .withRules(['target-size'])
      .analyze();
    expect(results.violations).toEqual([]);
  });
});
```

---

### 1.3 Authentication (3.3.8) 🔴

**Business Impact**: Critical - Legal compliance, blocks users with cognitive disabilities
**Implementation Effort**: Medium
**Timeline**: Week 2-3

#### Requirements

```html
<!-- Allow paste in password fields -->
<input type="password" 
       id="password"
       name="password"
       autocomplete="current-password"
       required>
<!-- NEVER use: onpaste="return false" -->

<!-- Alternative authentication options -->
<div class="auth-alternatives">
  <p>Or sign in with:</p>
  <button type="button" class="sso-microsoft">
    Microsoft Work Account
  </button>
  <button type="button" class="magic-link">
    Email me a sign-in link
  </button>
</div>
```

#### Critical Checks

- [ ] Remove paste blocking on all authentication fields
- [ ] Support `autocomplete` attributes for password managers
- [ ] Provide OAuth/SSO alternative
- [ ] Allow magic link authentication
- [ ] Support hardware security keys

---

### 1.4 Dragging Movements (2.5.7) 🟡

**Business Impact**: Medium - Alternative input methods for document management
**Implementation Effort**: High
**Timeline**: Weeks 3-4

#### Implementation for Document Libraries

```javascript
// Provide button alternatives to drag-drop
class AccessibleDocumentManager {
  constructor(container) {
    this.container = container;
    this.items = container.querySelectorAll('.document-item');
    this.setupDragAlternatives();
  }
  
  setupDragAlternatives() {
    this.items.forEach((item, index) => {
      const actions = document.createElement('div');
      actions.className = 'reorder-actions';
      actions.innerHTML = `
        <button aria-label="Move up" data-action="up">↑</button>
        <button aria-label="Move down" data-action="down">↓</button>
        <button aria-label="Move to top" data-action="top">⇈</button>
        <button aria-label="Move to bottom" data-action="bottom">⇊</button>
      `;
      
      item.querySelector('.actions').appendChild(actions);
      
      // Event handlers for alternatives
      actions.querySelectorAll('button').forEach(btn => {
        btn.addEventListener('click', () => this.reorder(item, btn.dataset.action));
      });
    });
  }
}
```

---

## Priority 2: Testing Infrastructure (Phase 2)

### 2.1 Automated Testing Setup

#### axe-core Integration (Primary)

```javascript
// axe.config.js
module.exports = {
  tags: ['wcag2a', 'wcag2aa', 'wcag22aa'],
  rules: [
    { id: 'target-size', enabled: true } // WCAG 2.2
  ]
};

// Jest test
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);

test('meets WCAG 2.2 AA', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container, {
    rules: { 'color-contrast': { enabled: false } }
  });
  expect(results).toHaveNoViolations();
});
```

#### Pa11y Integration (Secondary)

```json
{
  "pa11y": {
    "standard": "WCAG2AA",
    "urls": [
      "https://deltacrown.sharepoint.com/sites/portal",
      "https://deltacrown.sharepoint.com/sites/hub-operations",
      "https://deltacrown.sharepoint.com/sites/hub-training"
    ]
  }
}
```

### 2.2 CI/CD Pipeline

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  axe-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run test:accessibility
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: axe-results
          path: axe-results/
```

### 2.3 Manual Testing Schedule

| Test Type | Frequency | Owner | Duration |
|-----------|-----------|-------|----------|
| Keyboard navigation | Weekly | QA | 1 hour |
| Screen reader (NVDA) | Bi-weekly | QA | 2 hours |
| Screen reader (VoiceOver) | Bi-weekly | QA | 2 hours |
| Full manual audit | Quarterly | External | 1 week |
| User testing | Bi-annually | UX Research | 2 weeks |

---

## Priority 3: Content Organization (Phase 3)

### 3.1 Taxonomy Implementation

#### Core Metadata Schema

```json
{
  "ContentType": {
    "Name": "DCE Document",
    "Description": "Base content type for DCE documents",
    "Columns": [
      {
        "Name": "ContentClassification",
        "Type": "ManagedMetadata",
        "Required": true,
        "TermSet": "DCE Classification",
        "Values": ["Public", "Internal", "Confidential", "Restricted"]
      },
      {
        "Name": "DocumentType",
        "Type": "Choice",
        "Required": true,
        "Values": ["Policy", "Procedure", "Form", "Guideline", "Training"]
      },
      {
        "Name": "Department",
        "Type": "ManagedMetadata",
        "Required": true,
        "TermSet": "DCE Departments"
      },
      {
        "Name": "ReviewCycle",
        "Type": "Choice",
        "Required": true,
        "Values": ["Annual", "BiAnnual", "Quarterly", "AsNeeded"]
      },
      {
        "Name": "NextReviewDate",
        "Type": "DateTime",
        "Required": false,
        "Calculated": true,
        "Formula": "=[Modified]+365" // Based on ReviewCycle
      }
    ]
  }
}
```

#### Hub Site Structure

```
DCE Home Site (Home Site)
├── Hub: Operations Hub
│   ├── Site: Standard Operating Procedures
│   ├── Site: Safety & Compliance
│   └── Site: Quality Standards
├── Hub: Training Hub
│   ├── Site: Onboarding Program
│   ├── Site: Product Training
│   └── Site: Certification Tracking
└── Hub: Franchise Support Hub
    ├── Site: Franchisee Resources
    ├── Site: Performance Dashboard
    └── Site: Support Center
```

### 3.2 Content Lifecycle Workflow

```javascript
// SharePoint Framework Extension for lifecycle
export default class ContentLifecycleExtension extends BaseApplicationCustomizer {
  public onInit(): Promise<void> {
    // Add lifecycle indicator to document cards
    this._addLifecycleIndicators();
    return Promise.resolve();
  }
  
  private _addLifecycleIndicators(): void {
    const cards = document.querySelectorAll('.document-card');
    cards.forEach(card => {
      const status = card.dataset.status;
      const indicator = document.createElement('div');
      indicator.className = `lifecycle-indicator lifecycle-${status}`;
      indicator.setAttribute('role', 'status');
      indicator.setAttribute('aria-label', `Document status: ${status}`);
      card.appendChild(indicator);
    });
  }
}
```

### 3.3 Search Configuration

```powershell
# PowerShell PnP: Configure search
Connect-PnPOnline -Url "https://deltacrown.sharepoint.com/sites/portal"

# Create managed properties
$props = @(
    @{Name="DCEContentType"; Type="Text"; Queryable=$true; Retrievable=$true; Refinable=$true},
    @{Name="DCEDepartment"; Type="Text"; Queryable=$true; Retrievable=$true; Refinable=$true},
    @{Name="DCEReviewDue"; Type="DateTime"; Queryable=$true; Retrievable=$true; Refinable=$false}
)

foreach ($prop in $props) {
    Set-PnPSearchConfiguration -Configuration $prop -SearchConfigurationScope Tenant
}
```

---

## Priority 4: Content Governance UX (Phase 3)

### 4.1 Approval Workflow Interface

```html
<!-- Accessible workflow component -->
<nav aria-label="Approval workflow" class="workflow-progress">
  <ol class="workflow-steps">
    <li class="step completed">
      <span class="step-indicator" aria-hidden="true">✓</span>
      <span class="step-label">Draft</span>
      <span class="visually-hidden">Completed</span>
    </li>
    <li class="step current" aria-current="step">
      <span class="step-indicator" aria-hidden="true">●</span>
      <span class="step-label">Review</span>
      <span class="assignee">Assigned to: Operations Team</span>
      <button class="btn-primary">Approve</button>
      <button class="btn-secondary">Request Changes</button>
    </li>
    <li class="step future">
      <span class="step-indicator" aria-hidden="true">○</span>
      <span class="step-label">Published</span>
    </li>
  </ol>
</nav>
```

### 4.2 Version Control UI

```html
<section aria-labelledby="version-history">
  <h2 id="version-history">Version History</h2>
  <ol class="version-list">
    <li class="version current">
      <span class="version-number">v2.3</span>
      <span class="badge">Current</span>
      <time datetime="2025-01-15">Jan 15, 2025</time>
      <span class="author">by Sarah Johnson</span>
      <button aria-haspopup="dialog">Compare</button>
    </li>
  </ol>
</section>
```

### 4.3 Ownership Dashboard

```html
<section aria-labelledby="my-content">
  <h2 id="my-content">My Content</h2>
  
  <div class="content-stats">
    <div role="region" aria-label="Documents owned">
      <span class="stat-number">12</span>
      <span class="stat-label">Documents</span>
    </div>
    <div role="region" aria-label="Due for review">
      <span class="stat-number">3</span>
      <span class="stat-label">Due for Review</span>
    </div>
  </div>
  
  <ul aria-label="Content requiring action">
    <li class="action-item urgent">
      <span class="urgency-indicator" aria-label="Due in 3 days"></span>
      <a href="/docs/safety-procedures">Safety Procedures</a>
      <time datetime="2025-01-21">Due Jan 21</time>
      <button>Review Now</button>
    </li>
  </ul>
</section>
```

---

## Implementation Checklist

### Pre-Launch Requirements

#### Accessibility (Must Have)

- [ ] WCAG 2.2 AA compliance verified
- [ ] axe-core tests passing in CI/CD
- [ ] Manual keyboard testing complete
- [ ] Screen reader testing (NVDA) complete
- [ ] Focus management implemented
- [ ] Target size requirements met
- [ ] Authentication alternatives provided

#### Content Organization (Must Have)

- [ ] Taxonomy deployed
- [ ] Hub sites configured
- [ ] Content types created
- [ ] Metadata columns configured
- [ ] Search schema updated
- [ ] Workflows enabled
- [ ] Governance UX implemented

#### Testing Infrastructure (Must Have)

- [ ] axe-core integrated in unit tests
- [ ] axe-core integrated in E2E tests
- [ ] Pa11y site scan configured
- [ ] CI/CD pipeline for accessibility
- [ ] Manual testing schedule established
- [ ] Testing documentation complete

### Post-Launch (Ongoing)

- [ ] Monthly accessibility audit
- [ ] Quarterly manual review
- [ ] Bi-annual user testing
- [ ] Continuous monitoring dashboard
- [ ] Developer training program
- [ ] Accessibility champions network

---

## Resource Requirements

### Team Roles

| Role | FTE | Duration | Responsibilities |
|------|-----|----------|------------------|
| Accessibility Specialist | 0.5 | Ongoing | Audits, guidance, training |
| Front-end Developer | 2 | Phase 1-2 | WCAG implementation |
| SharePoint Architect | 1 | Phase 3 | Taxonomy, hub sites |
| QA Engineer | 1 | All phases | Testing, automation |
| UX Designer | 0.5 | Phase 3 | Governance UX |
| Content Manager | 0.5 | Phase 3 | Taxonomy, metadata |

### Tools & Licensing

| Tool | Cost | Notes |
|------|------|-------|
| axe-core | Free | Open source |
| Pa11y | Free | Open source |
| axe DevTools | $40/user/mo | Optional premium |
| NVDA | Free | Screen reader testing |
| External audit | $15K-30K | Quarterly |

### Timeline Summary

```
Weeks 1-4:   [==========] Critical WCAG fixes
Weeks 5-8:   [==========] Testing infrastructure
Weeks 9-12:  [==========] Content architecture
Week 13+:    [==========] Ongoing optimization

Total Development: ~3 months
Ongoing Effort: 10% dev capacity
```

---

## Success Metrics

### Accessibility Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| WCAG 2.2 AA Compliance | 100% | Automated + manual audit |
| axe-core Pass Rate | 100% | CI/CD pipeline |
| Keyboard Operability | 100% | Manual testing |
| Screen Reader Success | >95% | NVDA/VoiceOver testing |
| User Satisfaction | >4.0/5.0 | Surveys |

### Content Organization Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Search Success Rate | >70% | Analytics |
| Content Discovery Time | <2 min | User testing |
| Metadata Completeness | >95% | Audit |
| Content Freshness | >90% | Review tracking |

---

## Risk Mitigation

### High-Risk Items

| Risk | Mitigation | Owner |
|------|------------|-------|
| SharePoint focus styles | CSS overrides, SPFx extensions | Dev |
| Drag-drop alternatives | Button implementations | Dev |
| Cognitive accessibility | Plain language, clear instructions | Content |
| WCAG 2.2 audit failure | Early testing, iterative fixes | QA |

### Contingency Plans

- **If WCAG 2.2 complete compliance not achievable**: Document exceptions, implement remediation plan
- **If manual testing reveals critical issues**: Pause release, fix issues
- **If content migration delays**: Phase by department, priority first

---

## Next Steps

### Immediate (This Week)

1. [ ] Review recommendations with stakeholders
2. [ ] Schedule accessibility training for dev team
3. [ ] Set up axe-core in development environment
4. [ ] Begin focus indicator implementation

### Short-term (Next 4 Weeks)

1. [ ] Implement critical WCAG 2.2 requirements
2. [ ] Deploy axe-core in CI/CD
3. [ ] Conduct manual keyboard testing
4. [ ] Begin content taxonomy design

### Medium-term (Next 12 Weeks)

1. [ ] Complete all WCAG 2.2 requirements
2. [ ] Implement content governance UX
3. [ ] Deploy hub site architecture
4. [ ] Establish manual testing schedule

---

## Contact & Maintenance

**Research ID**: web-puppy-63bf85  
**Date**: January 2025  
**Next Review**: April 2025  
**Owner**: DCE Operations Team  

---

*This document should be reviewed and updated quarterly to reflect WCAG updates, tool improvements, and organizational needs.*
