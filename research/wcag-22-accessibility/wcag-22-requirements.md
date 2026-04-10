# WCAG 2.2 AA Compliance Requirements for Franchise Portals

## Overview

WCAG 2.2 was released in October 2023, introducing 9 new success criteria. This document details the 7 Level AA criteria most relevant to business portals, particularly SharePoint-based franchise operational platforms.

---

## Success Criterion 2.4.11: Focus Not Obscured (Minimum) - Level AA

### Official Requirement

**Success Criterion**: When a user interface component receives keyboard focus, the component is not entirely hidden by author-created content.

### Franchise Portal Impact

**High-Risk Areas:**
- Modal dialogs for document approvals
- Sticky headers on training content pages
- Cookie consent banners
- Notification toasts in operational dashboards
- Mega menus in navigation

### Implementation Requirements

```css
/* Required: Prevent focus obscuring by sticky headers/footers */
.sticky-header {
  position: sticky;
  top: 0;
  z-index: 100;
}

/* Use scroll-padding to ensure focused elements are visible */
html {
  scroll-padding-top: 80px; /* Match sticky header height */
  scroll-padding-bottom: 60px; /* Match sticky footer height */
}

/* Alternative: Ensure modals manage focus properly */
.modal[aria-hidden="false"] {
  /* Modal content visible */
}

.modal[aria-hidden="true"] * {
  visibility: hidden;
}
```

### SharePoint-Specific Considerations

- **Modern Site Headers**: SharePoint's app bar can obscure focus on hub navigation
- **Quick Launch**: Left navigation may need scroll-margin adjustment
- **Command Bar**: Top command bar in document libraries
- **Panel Overlays**: Side panels for metadata/properties

### Testing Checklist

- [ ] Tab through entire page with sticky header present
- [ ] Verify focused elements are at least partially visible
- [ ] Test with modal dialogs open
- [ ] Check notification banner behavior
- [ ] Verify with screen magnification (200%+)

### Failure Scenarios

❌ **Critical Failure**: Focused button completely hidden by sticky cookie banner  
❌ **Critical Failure**: Modal dialog opens but focus remains on obscured background element  
✅ **Pass**: Focused element partially visible (AA minimum requirement)

---

## Success Criterion 2.4.12: Focus Not Obscured (Enhanced) - Level AAA

### Official Requirement

**Success Criterion**: When a user interface component receives keyboard focus, no part of the component is hidden by author-created content.

### Key Differences from 2.4.11

| Aspect | 2.4.11 (AA) | 2.4.12 (AAA) |
|--------|-------------|--------------|
| Visibility | At least partially visible | Fully visible |
| Strictness | Minimum | Enhanced |
| Recommendation | Required | Recommended |

### Franchise Portal Implementation

**Recommended for:**
- Authentication pages
- Payment/credit card processing
- Critical operational workflows
- Training assessment interfaces

### Implementation

```css
/* AAA Implementation - full visibility guaranteed */
.scroll-container {
  scroll-snap-type: y proximity;
}

.focusable-element:focus {
  scroll-margin-top: 100px;
  scroll-margin-bottom: 80px;
}

/* Ensure modals scroll to show focused content */
.modal-content:focus-within {
  scroll-behavior: smooth;
}
```

---

## Success Criterion 2.4.13: Focus Appearance - Level AAA

### Official Requirement

**Success Criterion**: When the keyboard focus indicator is visible, an area of the focus indicator meets all the following:

1. Is at least as large as the area of a **2 CSS pixel thick perimeter** of the unfocused component or sub-component
2. Has a **contrast ratio of at least 3:1** between the same pixels in the focused and unfocused states

### Technical Specifications

#### Minimum Area Calculation

For rectangular components:
- Formula: `4 × height + 4 × width` (perimeter in px)
- Example: 90px × 30px button = 480px² minimum focus area

For circular components:
- Formula: `4 × π × radius` (perimeter in px)

#### Implementation Patterns

```css
/* Pattern 1: Solid 2px outline (Recommended) */
.button:focus {
  outline: 2px solid #005A9C;
  outline-offset: 2px;
}

/* Pattern 2: Inset border */
.button:focus {
  border: 2px solid #005A9C;
  /* Button must be at least 2px larger to accommodate */
}

/* Pattern 3: Background color change */
.button:focus {
  background-color: #E6F2FF; /* Must contrast 3:1 with unfocused state */
}

/* Pattern 4: Two-color indicator for variable backgrounds */
.button:focus {
  outline: 3px double black;
  outline-offset: 2px;
}
```

### Contrast Requirements

**Critical**: Focus Appearance measures **change of contrast** between focused/unfocused states, not adjacent contrast.

```
❌ FAIL: White button → Light gray focus (1.5:1 change)
✅ PASS: White button → Blue focus (4.5:1 change)
```

### SharePoint-Specific Styling

```css
/* Override SharePoint's default focus styles */
.ms-Fabric button:focus,
.ms-Fabric a:focus,
.ms-Fabric [tabindex]:focus {
  outline: 2px solid #0078D4;
  outline-offset: 2px;
}

/* Ensure focus visible in command bar */
.ms-CommandBar button:focus {
  outline: 2px solid #0078D4;
  outline-offset: -2px; /* Inset for command bar */
}

/* Focus in document libraries */
.ms-DetailsRow:focus {
  border: 2px solid #0078D4;
}
```

### Testing Requirements

- [ ] Calculate focus indicator area (must meet minimum)
- [ ] Verify 3:1 contrast ratio for focus change
- [ ] Test with various background colors
- [ ] Verify focus visible for all interactive elements
- [ ] Check focus on compound components (tablists, grids)

---

## Success Criterion 2.5.7: Dragging Movements - Level AA

### Official Requirement

**Success Criterion**: All functionality that uses a dragging movement for operation can be achieved by a single pointer without dragging, unless dragging is essential or the functionality is determined by the user agent.

### Franchise Portal Applications

**Common Drag Operations:**
- Document reordering in libraries
- Kanban board cards (training status tracking)
- Sortable lists (procedures, checklists)
- Image cropping/adjustment
- File upload ordering

### Implementation Patterns

```html
<!-- Drag Alternative Pattern: Buttons -->
<div class="sortable-list" role="list">
  <div role="listitem" class="sortable-item">
    <span>Training Module 1</span>
    <div class="reorder-controls">
      <button aria-label="Move up" class="move-up">↑</button>
      <button aria-label="Move down" class="move-down">↓</button>
      <button aria-label="Move to top" class="move-top">⇈</button>
      <button aria-label="Move to bottom" class="move-bottom">⇊</button>
    </div>
  </div>
</div>

<!-- Kanban Alternative Pattern: Move Menu -->
<div class="kanban-card">
  <h3>Document Review</h3>
  <div class="card-actions">
    <button aria-haspopup="listbox" aria-expanded="false">
      Move to column...
    </button>
    <!-- Dropdown with columns: Draft, Review, Approved -->
  </div>
</div>
```

### JavaScript Implementation

```javascript
// Alternative to drag - button-based reordering
class AccessibleSortable {
  constructor(container) {
    this.container = container;
    this.items = container.querySelectorAll('.sortable-item');
    this.setupAlternatives();
  }
  
  setupAlternatives() {
    this.items.forEach((item, index) => {
      const controls = item.querySelector('.reorder-controls');
      
      // Move Up
      controls.querySelector('.move-up').addEventListener('click', () => {
        if (index > 0) this.swap(index, index - 1);
      });
      
      // Move Down
      controls.querySelector('.move-down').addEventListener('click', () => {
        if (index < this.items.length - 1) this.swap(index, index + 1);
      });
    });
  }
  
  swap(fromIndex, toIndex) {
    // Implementation for reordering
    // Maintain focus management
    const item = this.items[fromIndex];
    // ... swap logic ...
    
    // Return focus to moved item
    item.focus();
  }
}
```

### SharePoint Integration

**Document Library Sorting:**
- Use column headers for sorting
- Provide "Move to position" dialog
- Support keyboard shortcuts (Ctrl+Arrow keys)

**Training Content Organization:**
- Implement reorder buttons in content management
- Provide "Insert at position" dropdown
- Support bulk move operations

---

## Success Criterion 2.5.8: Target Size (Minimum) - Level AA

### Official Requirement

**Success Criterion**: The size of the target for pointer inputs is at least **24 × 24 CSS pixels**, except when:

- **Spacing**: The target is less than 24 × 24 CSS pixels but has sufficient spacing (equivalent to 24×24px with no overlap)
- **Inline**: The target is in a sentence or block of text
- **User agent**: The size is determined by the user agent and not modified
- **Essential**: A particular presentation is essential

### Implementation Guidelines

```css
/* Minimum target size */
.clickable-target {
  min-width: 24px;
  min-height: 24px;
}

/* Recommended: 44px for mobile-friendly */
.mobile-target {
  min-width: 44px;
  min-height: 44px;
}

/* Spacing exception */
.icon-button {
  width: 20px;
  height: 20px;
  margin: 2px; /* Provides 24px effective target */
}

/* Touch-optimized for training portals */
.training-button {
  min-height: 44px;
  padding: 12px 24px;
}
```

### Franchise Portal Applications

**High-Priority Elements:**
- Document action buttons (download, share, edit)
- Navigation menu items
- Form submission buttons
- Close buttons on modals
- Checkboxes in bulk operations
- Training module navigation

### SharePoint Modern Customization

```css
/* Override SharePoint's small touch targets */
.ms-Button--icon {
  min-width: 44px;
  min-height: 44px;
}

/* Document library row actions */
.ms-DetailsRow-actions .ms-Button {
  min-width: 24px;
  min-height: 24px;
}

/* Command bar items */
.ms-CommandBar-item {
  min-height: 44px;
}

/* Form controls */
.ms-TextField-field,
.ms-Dropdown-title,
.ms-Checkbox {
  min-height: 24px;
}
```

### Spacing Exception Formula

```
If target < 24×24px:
  Required spacing = (24 - width) / 2 horizontal
  Required spacing = (24 - height) / 2 vertical

Example: 16×16px icon button
  Horizontal spacing: (24-16)/2 = 4px each side
  Vertical spacing: (24-16)/2 = 4px each side
```

---

## Success Criterion 3.2.6: Consistent Help - Level A

### Official Requirement

**Success Criterion**: If a web page contains any of the following help mechanisms, and those mechanisms are repeated on multiple web pages within a set of web pages, they occur in the **same order relative to other page content**:

- Human contact details
- Human contact mechanism
- Self-help option
- Fully automated contact mechanism

### Franchise Portal Implementation

**Required Help Mechanisms:**

| Mechanism | Example | Placement |
|-----------|---------|-----------|
| Contact Details | "Support: support@deltacrown.com" | Header or Footer |
| Contact Form | "Contact Operations" link | Consistent position |
| Self-Help | "Knowledge Base" link | Navigation |
| Chatbot | "Ask a Question" button | Bottom-right corner |

### Implementation Pattern

```html
<!-- Consistent Header Help Placement -->
<header class="site-header">
  <nav aria-label="Primary">
    <!-- Navigation items -->
  </nav>
  <div class="help-section" aria-label="Help">
    <!-- ALWAYS in this order: -->
    <a href="#contact-form">Contact Support</a>
    <a href="#knowledge-base">Knowledge Base</a>
    <button id="chatbot">Chat with us</button>
  </div>
</header>

<!-- Consistent Footer Help -->
<footer>
  <div class="footer-help" aria-label="Help and Support">
    <!-- Same order as header -->
    <a href="#contact-form">Contact Support</a>
    <a href="#knowledge-base">Knowledge Base</a>
    <button id="chatbot">Chat with us</button>
    <p>Phone: 1-800-SUPPORT</p>
  </div>
</footer>
```

### SharePoint Hub Site Implementation

```javascript
// Consistent help in SharePoint Framework extensions
export default class HelpExtension extends BaseApplicationCustomizer {
  public onInit(): Promise<void> {
    // Inject help component in consistent location
    this._renderHelp();
    return Promise.resolve();
  }
  
  private _renderHelp(): void {
    const helpContainer = document.createElement('div');
    helpContainer.className = 'consistent-help';
    helpContainer.setAttribute('role', 'complementary');
    helpContainer.setAttribute('aria-label', 'Help and Support');
    
    helpContainer.innerHTML = `
      <a href="/SitePages/Contact.aspx">Contact Support</a>
      <a href="/SitePages/Help.aspx">Knowledge Base</a>
      <button id="chat-widget">Live Chat</button>
    `;
    
    // Always insert in same location
    const header = document.querySelector('.ms-Header');
    if (header) {
      header.appendChild(helpContainer);
    }
  }
}
```

---

## Success Criterion 3.3.7: Redundant Entry - Level A

### Official Requirement

**Success Criterion**: Information previously entered by or provided to the user that is required to be entered again in the same process is either:

- Auto-populated, OR
- Available for the user to select

**Exceptions:**
- Re-entering is essential (e.g., password confirmation)
- Required for security
- Previously entered information is no longer valid

### Franchise Portal Applications

**Common Scenarios:**

| Scenario | Solution | Implementation |
|----------|----------|----------------|
| Franchisee address | Auto-fill shipping/billing | Same address checkbox |
| Manager info | Copy from previous step | "Same as primary" button |
| Document metadata | Carry from upload | Auto-fill form fields |
| Training enrollment | Pre-fill profile data | Auto-populate from profile |

### Implementation Patterns

```html
<!-- Redundant Entry Solution: Copy Function -->
<fieldset>
  <legend>Franchise Location Address</legend>
  <!-- Address fields -->
</fieldset>

<label class="copy-option">
  <input type="checkbox" id="sameAddress" 
         aria-controls="shipping-address">
  Shipping address is the same as franchise location
</label>

<fieldset id="shipping-address" aria-label="Shipping Address">
  <!-- Auto-populated when checkbox checked -->
</fieldset>

<script>
document.getElementById('sameAddress').addEventListener('change', (e) => {
  if (e.target.checked) {
    // Auto-populate shipping from franchise address
    copyAddressValues('franchise-address', 'shipping-address');
  }
});
</script>
```

```html
<!-- Multi-Step Form with Data Persistence -->
<form id="training-enrollment">
  <div class="step" data-step="1">
    <h2>Personal Information</h2>
    <input type="text" name="name" id="name" 
           autocomplete="name" required>
    <input type="email" name="email" id="email"
           autocomplete="email" required>
  </div>
  
  <div class="step" data-step="2">
    <h2>Emergency Contact</h2>
    <!-- Pre-fill with name from step 1 -->
    <select id="contact-relation">
      <option value="">Select contact...</option>
      <option value="self">Myself (same as above)</option>
      <option value="other">Other</option>
    </select>
    
    <div id="self-contact" hidden>
      <p>Emergency contact: <span id="copied-name"></span></p>
      <input type="hidden" name="emergency-name" id="emergency-name">
    </div>
  </div>
</form>
```

---

## Success Criterion 3.3.8: Accessible Authentication (Minimum) - Level AA

### Official Requirement

**Success Criterion**: A cognitive function test (such as remembering a password or solving a puzzle) is not required for any step in an authentication process unless that step provides at least one of:

- **Alternative**: Another authentication method that doesn't rely on cognitive function test
- **Mechanism**: Available to assist the user in completing the cognitive function test
- **Object Recognition**: Cognitive function test is to recognize objects
- **Personal Content**: Cognitive function test is to identify non-text content the user provided

### Franchise Portal Implementation

**Cognitive Function Tests to Avoid:**
- CAPTCHA puzzles
- Pattern/gesture unlock
- Security questions requiring recall
- Manual transcribing of one-time codes
- Complex password requirements

**Acceptable Alternatives:**
- Password managers (paste support)
- Magic links (email-based)
- OAuth/SSO integration
- Biometric authentication
- Hardware security keys
- Object recognition CAPTCHA

### Implementation Requirements

```javascript
// Enable paste in password fields (CRITICAL)
// NEVER block paste
const passwordInput = document.getElementById('password');
// DON'T DO THIS:
// passwordInput.addEventListener('paste', e => e.preventDefault());

// DO: Allow browser autofill and password managers
passwordInput.setAttribute('autocomplete', 'current-password');

// Input purpose for autofill (WCAG 1.3.5)
const inputs = {
  'email': 'username',
  'password': 'current-password',
  'new-password': 'new-password'
};

Object.entries(inputs).forEach(([id, purpose]) => {
  document.getElementById(id)?.setAttribute('autocomplete', purpose);
});
```

```html
<!-- Accessible Login Form -->
<form method="POST" action="/login">
  <div class="form-group">
    <label for="email">Email</label>
    <input type="email" 
           id="email" 
           name="email"
           autocomplete="username email"
           required>
  </div>
  
  <div class="form-group">
    <label for="password">Password</label>
    <input type="password"
           id="password"
           name="password"
           autocomplete="current-password"
           required>
    <!-- Paste explicitly allowed -->
  </div>
  
  <div class="form-options">
    <label>
      <input type="checkbox" name="remember">
      Remember me
    </label>
    <a href="/forgot-password">Forgot password?</a>
  </div>
  
  <button type="submit">Sign In</button>
  
  <!-- Alternative authentication -->
  <div class="auth-alternatives">
    <p>Or sign in with:</p>
    <button type="button" class="sso-microsoft">
      Microsoft Work Account
    </button>
    <button type="button" class="magic-link">
      Email me a sign-in link
    </button>
  </div>
</form>
```

### Multi-Factor Authentication Considerations

**For SMS/Authenticator Codes:**
```html
<!-- Allow paste for verification codes -->
<div class="mfa-inputs">
  <input type="text" 
         inputmode="numeric"
         pattern="[0-9]*"
         autocomplete="one-time-code"
         maxlength="6"
         aria-label="6-digit verification code">
</div>

<!-- Allow paste from clipboard -->
<script>
// Support paste of entire code
const mfaInput = document.querySelector('[autocomplete="one-time-code"]');
mfaInput.addEventListener('paste', (e) => {
  const pasted = e.clipboardData.getData('text');
  // Handle full code paste
  if (pasted.length === 6 && /^\d{6}$/.test(pasted)) {
    mfaInput.value = pasted;
    e.preventDefault();
  }
});
</script>
```

---

## Success Criterion 3.3.9: Accessible Authentication (Enhanced) - Level AAA

### Additional Requirements

Beyond 3.3.8, this criterion requires that cognitive function tests are not required at all (no object recognition or personal content exceptions).

**Implications:**
- No image-based CAPTCHA
- No pattern recognition
- No "select all images with traffic lights"
- Requires alternative authentication methods

---

## Compliance Matrix for Franchise Portals

| Criterion | Implementation Effort | Risk Level | Testing Priority |
|-----------|----------------------|------------|------------------|
| 2.4.11 Focus Not Obscured | Medium | High | Critical |
| 2.4.13 Focus Appearance | Low | Medium | High |
| 2.5.7 Dragging Movements | High | Medium | Medium |
| 2.5.8 Target Size | Low | High | Critical |
| 3.2.6 Consistent Help | Low | Low | Medium |
| 3.3.7 Redundant Entry | Medium | Low | Low |
| 3.3.8 Accessible Authentication | Medium | Critical | Critical |

---

## Source References

- W3C WCAG 2.2 Understanding: https://www.w3.org/WAI/WCAG22/Understanding/
- Focus Not Obscured (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum
- Focus Not Obscured (Enhanced): https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-enhanced
- Focus Appearance: https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance
- Dragging Movements: https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements
- Target Size (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum
- Consistent Help: https://www.w3.org/WAI/WCAG22/Understanding/consistent-help
- Redundant Entry: https://www.w3.org/WAI/WCAG22/Understanding/redundant-entry
- Accessible Authentication: https://www.w3.org/WAI/WCAG22/Understanding/accessible-authentication-minimum
