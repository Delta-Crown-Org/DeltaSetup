# Accessibility Testing Tools Comparison

## Executive Summary

This document compares automated accessibility testing tools for franchise portal development, focusing on **axe-core 4.11.1** and **Pa11y 9.1.1** for CI/CD integration.

### Key Findings

| Tool | Coverage | False Positives | WCAG Version | Best For |
|------|----------|-------------------|--------------|----------|
| axe-core 4.11.1 | ~70% | Near 0% | 2.2 Level A/AA | Developer workflows, CI/CD |
| Pa11y 9.1.1 | ~60% | Low | 2.1/2.2 | Quick scans, batch testing |
| axe DevTools | ~70% | Near 0% | 2.2 | Browser testing |
| Lighthouse | ~30% | Medium | 2.1 | Performance + Accessibility |

### Recommendation

**Primary**: axe-core 4.11.1 for CI/CD integration  
**Secondary**: Pa11y 9.1.1 for regression testing  
**Manual**: Required for ~30% of WCAG criteria

---

## axe-core 4.11.1

### Overview

**Maintainer**: Deque Systems  
**License**: MPL-2.0  
**WCAG Support**: 2.2 Level A, AA, AAA  
**GitHub**: https://github.com/dequelabs/axe-core  

### What axe-core Can Detect

#### Level A Rules (Automatically Detectable)

| Rule ID | Description | WCAG | Impact |
|---------|-------------|------|--------|
| `accesskeys` | No duplicate accesskey values | 2.4.1 | Serious |
| `area-alt` | area elements have alt text | 1.1.1 | Critical |
| `aria-braille-equivalent` | aria-braille attributes have text equivalent | 4.1.2 | Serious |
| `aria-command-name` | ARIA commands have accessible names | 4.1.2 | Serious |
| `aria-dialog-name` | ARIA dialogs have accessible names | 4.1.2 | Serious |
| `aria-input-field-name` | ARIA input fields have accessible names | 4.1.2 | Critical |
| `aria-meter-name` | ARIA meters have accessible names | 1.1.1 | Serious |
| `aria-progressbar-name` | ARIA progressbars have accessible names | 1.1.1 | Serious |
| `aria-required-attr` | Required ARIA attributes present | 4.1.2 | Critical |
| `aria-required-children` | Required ARIA children present | 1.3.1 | Critical |
| `aria-required-parent` | Required ARIA parents present | 1.3.1 | Critical |
| `aria-roledescription` | aria-roledescription on semantic elements | 4.1.2 | Serious |
| `aria-roles` | ARIA roles are valid | 4.1.2 | Critical |
| `aria-text` | Check aria-text is on textless elements | 2.5.3 | Serious |
| `aria-toggle-field-name` | ARIA toggle fields have accessible names | 4.1.2 | Critical |
| `aria-tooltip-name` | ARIA tooltips have accessible names | 4.1.2 | Serious |
| `aria-treeitem-name` | ARIA treeitems have accessible names | 4.1.2 | Serious |
| `aria-valid-attr-value` | ARIA attributes have valid values | 4.1.2 | Critical |
| `aria-valid-attr` | ARIA attributes are valid | 4.1.2 | Critical |
| `autocomplete-valid` | autocomplete attribute is valid | 1.3.5 | Serious |
| `blink` | No blinking elements | 2.2.2 | Serious |
| `button-name` | Buttons have accessible names | 4.1.2 | Critical |
| `bypass` | Page has bypass blocks | 2.4.1 | Serious |
| `color-contrast` | Elements meet color contrast minimum | 1.4.3 | Serious |
| `definition-list` | dl elements are structured correctly | 1.3.1 | Serious |
| `dlitem` | dt and dd elements are contained by dl | 1.3.1 | Serious |
| `document-title` | Documents have titles | 2.4.2 | Serious |
| `duplicate-id-active` | IDs are unique for active elements | 4.1.1 | Serious |
| `duplicate-id-aria` | IDs used in ARIA and labels are unique | 4.1.1 | Critical |
| `duplicate-id` | IDs are unique | 4.1.1 | Minor |
| `form-field-multiple-labels` | Fields have at most one label | 1.3.1 | Moderate |
| `frame-focusable-content` | Frames with tabindex don't have focusable content | 2.1.1 | Serious |
| `frame-tested` | Frames are tested with axe | - | Serious |
| `frame-title-unique` | Frame titles are unique | 4.1.2 | Serious |
| `frame-title` | Frames have titles | 4.1.2 | Serious |
| `html-has-lang` | html element has lang attribute | 3.1.1 | Serious |
| `html-lang-valid` | lang attribute has valid value | 3.1.1 | Serious |
| `html-xml-lang-mismatch` | xml:lang and lang match | 3.1.1 | Moderate |
| `image-alt` | Images have alt text | 1.1.1 | Critical |
| `image-redundant-alt` | Alt text doesn't repeat adjacent text | 1.1.1 | Minor |
| `input-button-name` | Input buttons have accessible names | 4.1.2 | Critical |
| `input-image-alt` | Image buttons have alt text | 1.1.1 | Critical |
| `label-content-name-mismatch` | Label text matches accessible name | 2.5.3 | Serious |
| `label-title-only` | Form elements don't only use title for label | 1.3.1 | Serious |
| `label` | Form elements have labels | 1.3.1 | Critical |
| `landmark-banner-is-top-level` | Banner landmark is top level | 1.3.1 | Moderate |
| `landmark-complementary-is-top-level` | Complementary landmark is top level | 1.3.1 | Moderate |
| `landmark-contentinfo-is-top-level` | Contentinfo landmark is top level | 1.3.1 | Moderate |
| `landmark-main-is-top-level` | Main landmark is top level | 1.3.1 | Moderate |
| `landmark-no-duplicate-banner` | No duplicate banner landmarks | 1.3.1 | Moderate |
| `landmark-no-duplicate-contentinfo` | No duplicate contentinfo landmarks | 1.3.1 | Moderate |
| `landmark-no-duplicate-main` | No duplicate main landmarks | 1.3.1 | Moderate |
| `landmark-one-main` | Only one main landmark | 1.3.1 | Moderate |
| `landmark-unique` | Landmarks have unique labels | 1.3.1 | Moderate |
| `link-in-text-block` | Links are distinguishable from text | 1.4.1 | Low |
| `link-name` | Links have accessible names | 2.4.4 | Serious |
| `list` | Lists are structured correctly | 1.3.1 | Serious |
| `listitem` | Listitems have parents | 1.3.1 | Serious |
| `marquee` | No marquee elements | 2.2.2 | Serious |
| `meta-refresh-no-exceptions` | meta refresh doesn't exist | 2.2.2 | Critical |
| `meta-refresh` | meta refresh delay is sufficient | 2.2.2 | Critical |
| `meta-viewport-large` | viewport zoom not disabled | 1.4.4 | Serious |
| `meta-viewport` | viewport zooming isn't disabled | 1.4.4 | Critical |
| `nested-interactive` | Nested interactive controls don't exist | 4.1.2 | Serious |
| `no-duplicate-label` | Labels are unique | 2.4.6 | Moderate |
| `object-alt` | Objects have text alternatives | 1.1.1 | Serious |
| `p-as-heading` | P elements aren't styled as headings | 1.3.1 | Serious |
| `page-has-heading-one` | Page has a level-one heading | 1.3.1 | Moderate |
| `presentation-role-conflict` | Semantic elements aren't role=presentation | 1.3.1 | Serious |
| `role-img-alt` | Role=img elements have alt text | 1.1.1 | Serious |
| `scrollable-region-focusable` | Scrollable regions are keyboard accessible | 2.1.1 | Moderate |
| `select-name` | Select elements have accessible names | 4.1.2 | Critical |
| `server-side-image-map` | Server-side image maps aren't used | 1.1.1 | Minor |
| `skip-link` | Skip links work | 2.4.1 | Moderate |
| `svg-img-alt` | SVGs with img roles have alt text | 1.1.1 | Serious |
| `tabindex` | tabindex isn't positive | 2.4.3 | Serious |
| `table-duplicate-name` | Tables have unique accessible names | 1.3.1 | Minor |
| `table-fake-caption` | Tables use caption elements | 1.3.1 | Serious |
| `target-size` | Targets are at least 24x24 CSS pixels | 2.5.8 | Moderate |
| `td-has-header` | Non-empty table cells have headers | 1.3.1 | Serious |
| `td-headers-attr` | td headers attribute is valid | 1.3.1 | Serious |
| `th-has-data-cells` | Table headers have data cells | 1.3.1 | Serious |
| `valid-lang` | lang attributes have valid values | 3.1.2 | Serious |
| `video-caption` | Videos have captions | 1.2.2 | Critical |

#### Level AA Rules

| Rule ID | Description | WCAG | Impact |
|---------|-------------|------|--------|
| `color-contrast-enhanced` | Elements meet enhanced color contrast | 1.4.6 | Serious |
| `focus-visible` | Focus indicators are visible | 2.4.7 | Serious |
| `link-in-text-block` | Links in text blocks are underlined | 1.4.1 | Low |
| `no-autoplay-audio` | Audio doesn't autoplay | 1.4.2 | Moderate |
| `target-size` | Targets are 24×24 CSS pixels minimum | 2.5.8 | Moderate |

### WCAG 2.2 New Rules Support

#### axe-core 4.11.1 Coverage of WCAG 2.2

| WCAG 2.2 Criterion | Status | Notes |
|-------------------|--------|-------|
| 2.4.11 Focus Not Obscured (Minimum) | Partial | Can detect some obscuring issues |
| 2.4.12 Focus Not Obscured (Enhanced) | Partial | Can detect some obscuring issues |
| 2.4.13 Focus Appearance | No | Requires manual testing |
| 2.5.7 Dragging Movements | No | Requires manual testing |
| 2.5.8 Target Size (Minimum) | **Yes** | `target-size` rule |
| 3.2.6 Consistent Help | No | Requires manual testing |
| 3.3.7 Redundant Entry | No | Requires manual testing |
| 3.3.8 Accessible Authentication (Minimum) | Partial | Can detect paste blocking |
| 3.3.9 Accessible Authentication (Enhanced) | Partial | Can detect paste blocking |

### Installation & Configuration

#### NPM Installation

```bash
# Install axe-core
npm install --save-dev axe-core@4.11.1

# For testing frameworks
npm install --save-dev @axe-core/cli
npm install --save-dev @axe-core/react  # For React
npm install --save-dev @axe-core/webdriverjs  # For Selenium
npm install --save-dev jest-axe  # For Jest
```

#### Basic Configuration

```javascript
// axe.config.js
module.exports = {
  // Standard configuration for franchise portals
  standard: {
    // WCAG 2.2 Level AA compliance
    rules: [
      {
        id: 'target-size',
        enabled: true  // WCAG 2.2 requirement
      }
    ],
    
    // Run all rules except these
    exclude: [
      'color-contrast'  // Run separately for false positive handling
    ],
    
    // Tags to run
    tags: ['wcag2a', 'wcag2aa', 'wcag22aa', 'best-practice'],
    
    // Reporter options
    reporter: 'v2',
    
    // Result types to include
    resultTypes: ['violations', 'incomplete'],
    
    // Don't allow axe to scroll
    scrollableElement: null
  },
  
  // CI/CD configuration (strict)
  ci: {
    ...this.standard,
    tags: ['wcag2a', 'wcag2aa', 'wcag22aa'],
    reporter: 'no-pass',
    runOnly: {
      type: 'rule',
      values: [
        // Critical rules only for CI
        'aria-roles',
        'aria-valid-attr-value',
        'button-name',
        'color-contrast',
        'image-alt',
        'label',
        'link-name',
        'target-size'
      ]
    }
  }
};
```

#### Integration with Jest

```javascript
// axe.test.js
const { axe, toHaveNoViolations } = require('jest-axe');
const { render } = require('@testing-library/react');
const React = require('react');

// Add jest-axe matchers
expect.extend(toHaveNoViolations);

// Configure axe for tests
const axeConfig = {
  rules: {
    // Disable rules that may have false positives
    'color-contrast': { enabled: false },
    'skip-link': { enabled: false }
  }
};

describe('Accessibility Tests', () => {
  test('should have no accessibility violations', async () => {
    const { container } = render(<MyComponent />);
    const results = await axe(container, axeConfig);
    
    expect(results).toHaveNoViolations();
  });
});
```

#### Integration with Cypress

```javascript
// cypress/e2e/accessibility.cy.js
describe('Accessibility Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.injectAxe();
  });
  
  it('should have no accessibility violations', () => {
    cy.checkA11y(null, {
      rules: {
        'color-contrast': { enabled: false }
      }
    });
  });
  
  it('should meet WCAG 2.2 target size', () => {
    cy.checkA11y(null, {
      runOnly: {
        type: 'rule',
        values: ['target-size']
      }
    });
  });
});
```

#### Integration with Playwright

```javascript
// tests/accessibility.spec.js
const { test, expect } = require('@playwright/test');
const AxeBuilder = require('@axe-core/playwright').default;

test.describe('Accessibility', () => {
  test('should have no accessibility violations', async ({ page }) => {
    await page.goto('/');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .include('#app')  // Test only the app content
      .exclude('.advertisement')  // Exclude known issues
      .analyze();
    
    expect(accessibilityScanResults.violations).toEqual([]);
  });
  
  test('should meet WCAG 2.2 AA', async ({ page }) => {
    await page.goto('/');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2aa', 'wcag22aa'])
      .analyze();
    
    expect(accessibilityScanResults.violations).toEqual([]);
  });
});
```

### CI/CD Integration

#### GitHub Actions

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  axe-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Start dev server
        run: npm run dev &
        
      - name: Wait for server
        run: npx wait-on http://localhost:3000
        
      - name: Run axe tests
        run: npm run test:accessibility
        
      - name: Upload axe report
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: axe-report
          path: axe-results.json
```

#### Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: NodeTool@0
    inputs:
      versionSpec: '20.x'
    displayName: 'Install Node.js'
    
  - script: npm ci
    displayName: 'Install dependencies'
    
  - script: npm run build
    displayName: 'Build'
    
  - script: npm run start &
    displayName: 'Start server'
    
  - script: npx wait-on http://localhost:3000
    displayName: 'Wait for server'
    
  - script: npm run test:accessibility
    displayName: 'Run axe tests'
    
  - task: PublishTestResults@2
    condition: succeededOrFailed()
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: '**/axe-results.xml'
      mergeTestResults: true
      testRunTitle: 'Accessibility Tests'
```

### Output & Reporting

#### JSON Results Structure

```json
{
  "testEngine": {
    "name": "axe-core",
    "version": "4.11.1"
  },
  "testRunner": {
    "name": "axe"
  },
  "testEnvironment": {
    "userAgent": "Mozilla/5.0...",
    "windowWidth": 1920,
    "windowHeight": 1080
  },
  "timestamp": "2025-01-18T10:30:00.000Z",
  "url": "https://deltacrown.sharepoint.com/sites/portal",
  "violations": [
    {
      "id": "button-name",
      "impact": "critical",
      "tags": ["wcag2a", "wcag412"],
      "description": "Ensures buttons have discernible text",
      "help": "Buttons must have accessible names",
      "helpUrl": "https://dequeuniversity.com/rules/axe/4.11/button-name",
      "nodes": [
        {
          "html": "<button class=\"icon-only\"></button>",
          "target": ["button.icon-only"],
          "failureSummary": "Fix any of the following..."
        }
      ]
    }
  ],
  "passes": [...],
  "incomplete": [...],
  "inapplicable": [...]
}
```

#### HTML Report Generation

```javascript
// Generate HTML report from axe results
const fs = require('fs');
const axe = require('axe-core');

async function generateReport(results, outputPath) {
  const report = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Accessibility Report</title>
  <style>
    .critical { border-left: 4px solid #d13438; }
    .serious { border-left: 4px solid #ff6b35; }
    .moderate { border-left: 4px solid #ffb900; }
    .minor { border-left: 4px solid #00cc6a; }
  </style>
</head>
<body>
  <h1>Accessibility Report</h1>
  <p>Generated: ${new Date().toLocaleString()}</p>
  <p>Violations: ${results.violations.length}</p>
  
  ${results.violations.map(v => `
    <div class="violation ${v.impact}">
      <h2>${v.id}: ${v.impact}</h2>
      <p>${v.description}</p>
      <a href="${v.helpUrl}">Learn more</a>
      <h3>Affected Elements</h3>
      <ul>
        ${v.nodes.map(n => `<li><code>${n.html}</code></li>`).join('')}
      </ul>
    </div>
  `).join('')}
</body>
</html>`;

  fs.writeFileSync(outputPath, report);
}
```

---

## Pa11y 9.1.1

### Overview

**Maintainer**: Team Pa11y  
**License**: LGPL-3.0  
**WCAG Support**: 2.1/2.2 Level A, AA  
**GitHub**: https://github.com/pa11y/pa11y  
**Website**: https://pa11y.org/

### What Pa11y Can Detect

Pa11y uses HTML CodeSniffer and axe-core under the hood, supporting:

#### WCAG 2.1 Coverage

| Standard | Coverage | Notes |
|----------|----------|-------|
| WCAG 2.1 Level A | ~80% | Good coverage |
| WCAG 2.1 Level AA | ~70% | Good coverage |
| WCAG 2.2 | ~60% | Limited support |

#### Supported Rules

| Category | Rules | Detectable |
|----------|-------|------------|
| Text Alternatives | Alt text for images | ✅ |
| Adaptable | Info & relationships | ✅ |
| Distinguishable | Color contrast | ✅ |
| Keyboard Accessible | Keyboard functionality | ⚠️ Partial |
| Enough Time | Timing adjustable | ❌ Manual |
| Seizures | Flashing content | ⚠️ Partial |
| Navigable | Link purpose, headings | ✅ |
| Readable | Language, reading level | ⚠️ Partial |
| Predictable | Consistent navigation | ⚠️ Partial |
| Input Assistance | Labels, error prevention | ✅ |
| Compatible | Parsing, name/role/value | ✅ |

### Installation & Configuration

#### NPM Installation

```bash
# Install Pa11y
npm install --save-dev pa11y@9.1.1

# For CI integration
npm install --save-dev pa11y-ci@4.0

# For dashboard/reporter
npm install --save-dev pa11y-dashboard
```

#### Basic Configuration

```javascript
// pa11y.config.js
module.exports = {
  // WCAG 2.1 AA standard
  standard: 'WCAG2AA',
  
  // Timeout settings
  timeout: 30000,
  wait: 1000,
  
  // Viewport settings
  viewport: {
    width: 1280,
    height: 1024
  },
  
  // Actions to perform before test
  actions: [
    'set field #username to test@deltacrown.com',
    'set field #password to password',
    'click element #submit',
    'wait for url to be https://deltacrown.sharepoint.com/sites/portal'
  ],
  
  // Rules to ignore
  ignore: [
    'WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.BgImage',
    'WCAG2AA.Principle3.Guideline3_2.3_2_2.H32.2',
    'color-contrast'  // Run separately with specific tool
  ],
  
  // Headers to send
  headers: {
    'Accept-Language': 'en'
  },
  
  // Screen capture on failure
  screenCapture: './pa11y-screen-capture.png',
  
  // Log level
  log: {
    debug: console.log,
    error: console.error,
    info: console.info
  }
};
```

#### Pa11y-ci Configuration (Multiple URLs)

```json
{
  "pa11y": {
    "standard": "WCAG2AA",
    "timeout": 30000,
    "wait": 1000,
    "ignore": [
      "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.BgImage"
    ]
  },
  "urls": [
    "https://deltacrown.sharepoint.com/sites/portal",
    "https://deltacrown.sharepoint.com/sites/hub-operations",
    "https://deltacrown.sharepoint.com/sites/hub-training",
    "https://deltacrown.sharepoint.com/sites/hub-franchise",
    {
      "url": "https://deltacrown.sharepoint.com/sites/portal/login",
      "actions": [
        "set field #username to testuser",
        "set field #password to testpass",
        "click element #submit"
      ]
    }
  ]
}
```

### Integration Examples

#### Command Line Usage

```bash
# Test single URL
npx pa11y https://deltacrown.sharepoint.com/sites/portal

# Test with options
npx pa11y \
  --standard WCAG2AA \
  --timeout 60000 \
  --wait 2000 \
  --screen-capture screenshot.png \
  https://deltacrown.sharepoint.com/sites/portal

# Test multiple URLs
npx pa11y-ci --config .pa11yci.json

# Output as JSON
npx pa11y --reporter json https://deltacrown.sharepoint.com > results.json

# Output as CSV
npx pa11y --reporter csv https://deltacrown.sharepoint.com > results.csv
```

#### Programmatic API

```javascript
// pa11y-test.js
const pa11y = require('pa11y');

async function runTests() {
  try {
    // Test a page
    const results = await pa11y('https://deltacrown.sharepoint.com/sites/portal', {
      standard: 'WCAG2AA',
      timeout: 60000,
      wait: 2000,
      
      // Actions to perform
      actions: [
        'click element #accept-cookies'
      ],
      
      // Screenshot on failure
      screenCapture: './screenshots/pa11y-error.png'
    });
    
    // Output results
    console.log(`Issues: ${results.issues.length}`);
    
    results.issues.forEach(issue => {
      console.log(`\n${issue.type}: ${issue.code}`);
      console.log(`Message: ${issue.message}`);
      console.log(`Context: ${issue.context}`);
      console.log(`Selector: ${issue.selector}`);
    });
    
    // Generate report
    generateReport(results);
    
  } catch (error) {
    console.error('Pa11y error:', error);
    process.exit(1);
  }
}

function generateReport(results) {
  const report = {
    timestamp: new Date().toISOString(),
    documentTitle: results.documentTitle,
    pageUrl: results.pageUrl,
    issues: results.issues.map(issue => ({
      type: issue.type,
      code: issue.code,
      message: issue.message,
      context: issue.context,
      selector: issue.selector
    }))
  };
  
  require('fs').writeFileSync(
    'pa11y-report.json',
    JSON.stringify(report, null, 2)
  );
}

runTests();
```

### CI/CD Integration

#### GitHub Actions

```yaml
# .github/workflows/pa11y.yml
name: Pa11y Accessibility Tests

on: [push, pull_request]

jobs:
  pa11y:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Install Pa11y
        run: npm install -g pa11y-ci@4.0
        
      - name: Start dev server
        run: npm run dev &
        
      - name: Wait for server
        run: npx wait-on http://localhost:3000 --timeout 60000
        
      - name: Run Pa11y tests
        run: pa11y-ci --config .pa11yci.json
        
      - name: Upload Pa11y report
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: pa11y-report
          path: pa11y-report.json
```

### Output Formats

#### JSON Output

```json
{
  "documentTitle": "DCE Portal",
  "pageUrl": "https://deltacrown.sharepoint.com/sites/portal",
  "issues": [
    {
      "code": "WCAG2AA.Principle1.Guideline1_1.1_1_1.H30.2",
      "type": "error",
      "typeCode": 1,
      "message": "Img element missing an alt attribute.",
      "context": "<img src=\"logo.png\">",
      "selector": "img[src='logo.png']",
      "runner": "htmlcs"
    },
    {
      "code": "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail",
      "type": "error",
      "typeCode": 1,
      "message": "This element has insufficient contrast ratio.",
      "context": "<p class=\"text-muted\">Secondary content</p>",
      "selector": "p.text-muted",
      "runner": "axe"
    }
  ]
}
```

#### CSV Output

```csv
"type","code","message","context","selector"
"error","WCAG2AA.Principle1.Guideline1_1.1_1_1.H30.2","Img element missing an alt attribute.","<img src=""logo.png"">","img[src='logo.png']"
"error","WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail","This element has insufficient contrast ratio.","<p class=""text-muted""></p>","p.text-muted"
```

---

## Comparison Matrix

### Feature Comparison

| Feature | axe-core 4.11.1 | Pa11y 9.1.1 |
|---------|-----------------|-------------|
| **WCAG Support** | | |
| WCAG 2.1 Level A | ✅ Complete | ✅ Complete |
| WCAG 2.1 Level AA | ✅ Complete | ✅ Complete |
| WCAG 2.1 Level AAA | ✅ Complete | ⚠️ Partial |
| WCAG 2.2 | ✅ Good | ⚠️ Limited |
| **Testing Capabilities** | | |
| Single URL | ✅ | ✅ |
| Multiple URLs | ⚠️ Via CLI | ✅ Native |
| Authenticated Pages | ✅ | ✅ |
| JavaScript Execution | ✅ | ✅ |
| Actions/Workflows | ✅ | ✅ |
| Screenshots | ❌ | ✅ |
| **Integration** | | |
| Node.js API | ✅ | ✅ |
| Browser Extension | ✅ (DevTools) | ❌ |
| CI/CD Support | ✅ | ✅ |
| Docker Support | ✅ | ✅ |
| **Output** | | |
| JSON | ✅ | ✅ |
| HTML Report | ✅ (via tools) | ✅ (via tools) |
| CSV | ❌ | ✅ |
| JUnit XML | ✅ | ✅ |
| **Quality** | | |
| False Positive Rate | Near 0% | Low |
| Coverage | ~70% | ~60% |
| Performance | Fast | Moderate |
| Documentation | Excellent | Good |

### Rule Coverage Comparison

| Rule Category | axe-core 4.11.1 | Pa11y 9.1.1 | Best Tool |
|---------------|-----------------|-------------|-----------|
| ARIA | ✅ Excellent | ✅ Excellent | Tie |
| Color Contrast | ✅ Accurate | ⚠️ Some false positives | axe-core |
| Forms | ✅ Excellent | ✅ Good | axe-core |
| Headings | ✅ Excellent | ✅ Excellent | Tie |
| Images | ✅ Excellent | ✅ Excellent | Tie |
| Keyboard | ⚠️ Good | ⚠️ Partial | axe-core |
| Landmarks | ✅ Excellent | ✅ Good | axe-core |
| Links | ✅ Excellent | ✅ Good | axe-core |
| Tables | ✅ Excellent | ✅ Good | axe-core |

### Performance Comparison

| Metric | axe-core 4.11.1 | Pa11y 9.1.1 |
|--------|-----------------|-------------|
| Scan Time (single page) | ~500ms | ~2000ms |
| Memory Usage | Low | Moderate |
| Parallel Execution | ✅ | ⚠️ Limited |
| Large Site Scanning | ⚠️ Requires scripting | ✅ Native |
| Resource Impact | Minimal | Moderate |

---

## Recommended Setup

### For DCE Franchise Portals

#### Primary Configuration: axe-core

**Rationale**: 
- Zero false positive commitment from Deque
- Best-in-class WCAG 2.2 support
- Superior integration with React/SPFx
- Industry standard for Microsoft projects

```javascript
// axe.config.js - Recommended for DCE
module.exports = {
  // WCAG 2.2 AA compliance
  tags: ['wcag2a', 'wcag2aa', 'wcag22aa'],
  
  rules: [
    // Enable WCAG 2.2 target size
    { id: 'target-size', enabled: true }
  ],
  
  // Result types
  resultTypes: ['violations', 'incomplete'],
  
  // Reporter
  reporter: 'v2'
};
```

#### Secondary Configuration: Pa11y-ci

**Rationale**:
- Native multi-URL support for site-wide scanning
- Built-in screenshot capture
- CSV export for reporting

```json
{
  "pa11y": {
    "standard": "WCAG2AA",
    "timeout": 60000,
    "ignore": [
      "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.BgImage"
    ]
  },
  "urls": [
    "https://deltacrown.sharepoint.com/sites/portal",
    "https://deltacrown.sharepoint.com/sites/hub-operations",
    "https://deltacrown.sharepoint.com/sites/hub-training",
    "https://deltacrown.sharepoint.com/sites/hub-franchise"
  ]
}
```

### CI/CD Pipeline Integration

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  axe-core:
    name: axe-core Component Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run test:axe
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: axe-results
          path: axe-results/
          
  pa11y-site:
    name: Pa11y Site-wide Scan
    runs-on: ubuntu-latest
    needs: axe-core
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm install -g pa11y-ci@4.0
      - run: npm run dev &
      - run: npx wait-on http://localhost:3000 --timeout 120000
      - run: pa11y-ci --config .pa11yci.json
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: pa11y-results
          path: pa11y-report.json
```

### Package.json Scripts

```json
{
  "scripts": {
    "test:axe": "jest --config jest.axe.config.js",
    "test:axe:watch": "jest --config jest.axe.config.js --watch",
    "test:axe:coverage": "jest --config jest.axe.config.js --coverage",
    "test:pa11y": "pa11y-ci --config .pa11yci.json",
    "test:pa11y:single": "pa11y http://localhost:3000",
    "test:accessibility": "npm run test:axe && npm run test:pa11y",
    "a11y:report": "node scripts/generate-a11y-report.js"
  }
}
```

---

## Manual Audit Requirements

### What Cannot Be Automated

#### axe-core & Pa11y Cannot Detect:

| WCAG Criterion | Category | Manual Test Required |
|--------------|----------|---------------------|
| 1.3.1 Info and Relationships | Semantic accuracy | Expert review |
| 1.3.2 Meaningful Sequence | Content order | Screen reader |
| 1.3.3 Sensory Characteristics | Instructions | Expert review |
| 2.1.1 Keyboard | Complex interactions | Keyboard testing |
| 2.1.2 No Keyboard Trap | Focus management | Keyboard testing |
| 2.4.3 Focus Order | Tab order | Keyboard testing |
| 2.4.4 Link Purpose | Contextual meaning | Screen reader |
| 2.4.6 Headings and Labels | Descriptive text | Expert review |
| 2.4.11 Focus Not Obscured | Visual overlap | Manual inspection |
| 2.4.13 Focus Appearance | Focus indicator quality | Visual inspection |
| 2.5.7 Dragging Movements | Drag alternatives | Interaction testing |
| 3.2.6 Consistent Help | Help placement | Cross-page review |
| 3.3.7 Redundant Entry | Data persistence | Form testing |
| 3.3.8 Accessible Authentication | Auth alternatives | Auth flow testing |

### Manual Testing Schedule

| Test Type | Frequency | Tool |
|-----------|-----------|------|
| Automated (axe-core) | Every commit | CI/CD |
| Automated (Pa11y) | Daily | CI/CD |
| Keyboard Testing | Weekly | Manual |
| Screen Reader (NVDA) | Bi-weekly | Manual |
| Screen Reader (VoiceOver) | Bi-weekly | Manual |
| Full Manual Audit | Quarterly | Expert |
| User Testing | Bi-annually | Users with disabilities |

---

## Cost Analysis

### Tool Costs

| Tool | License | Cost | Notes |
|------|---------|------|-------|
| axe-core | Open Source (MPL-2.0) | Free | Can use freely |
| axe DevTools Premium | Commercial | ~$40/mo/user | Advanced features |
| Pa11y | Open Source (LGPL-3.0) | Free | Can use freely |
| axe DevTools Extension | Freemium | Free tier | Browser extension |

### Implementation Costs

| Cost Factor | axe-core | Pa11y |
|-------------|----------|-------|
| Setup Time | 2-4 hours | 1-2 hours |
| Training | 4-8 hours | 2-4 hours |
| Maintenance | Low | Low |
| CI/CD Integration | 2-4 hours | 1-2 hours |
| Custom Rules | Possible | Limited |

### ROI Calculation

```
Benefits:
- Reduced manual testing: 40% time savings
- Earlier bug detection: 70% cost reduction
- Compliance confidence: Reduced legal risk
- Developer productivity: Immediate feedback

Costs (Annual):
- Tool licenses: $0 (open source)
- Setup: ~20 hours
- Maintenance: ~10 hours/year
- Training: ~8 hours/year per developer

Break-even: ~2-3 months for typical project
```

---

## Migration from Pa11y to axe-core

### If Currently Using Pa11y

```javascript
// pa11y-to-axe-migration.js
const pa11y = require('pa11y');
const axe = require('axe-core');

// Map Pa11y rules to axe rules
const ruleMapping = {
  'WCAG2AA.Principle1.Guideline1_1.1_1_1.H30.2': 'image-alt',
  'WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail': 'color-contrast',
  'WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.Name': 'link-name'
  // ... more mappings
};

async function migrateToAxe(url) {
  // Run both tools and compare
  const pa11yResults = await pa11y(url);
  const axeResults = await axe.run(document);
  
  // Compare coverage
  console.log('Pa11y found:', pa11yResults.issues.length, 'issues');
  console.log('axe-core found:', axeResults.violations.length, 'issues');
  
  // Identify gaps
  const pa11yOnly = pa11yResults.issues.filter(issue => 
    !axeResults.violations.some(v => 
      ruleMapping[issue.code] === v.id
    )
  );
  
  console.log('Pa11y-only issues:', pa11yOnly.length);
}
```

---

## Summary Recommendations

### For DCE Franchise Portals

1. **Primary Tool**: axe-core 4.11.1
   - Best WCAG 2.2 support
   - Zero false positives
   - Excellent CI/CD integration
   - Microsoft/SharePoint standard

2. **Secondary Tool**: Pa11y 9.1.1
   - Site-wide scanning
   - Screenshot capture
   - Quick URL batch testing

3. **Manual Testing Required**
   - Screen reader testing (NVDA, VoiceOver)
   - Keyboard navigation testing
   - Cognitive accessibility review
   - User testing with disabled users

4. **Implementation Priority**
   - Phase 1: axe-core in unit tests
   - Phase 2: axe-core in E2E tests
   - Phase 3: Pa11y-ci for site scans
   - Phase 4: Manual audit process

---

## Source References

- axe-core GitHub: https://github.com/dequelabs/axe-core
- axe-core Docs: https://www.deque.com/axe/core/
- Pa11y GitHub: https://github.com/pa11y/pa11y
- Pa11y Docs: https://pa11y.org/
- WCAG-EM: https://www.w3.org/WAI/test-evaluate/conformance/wcag-em/
- Automated Testing Rules: https://www.w3.org/WAI/standards-guidelines/act/rules/
