# WCAG 2.2 AA Color Contrast Recommendations
## Delta Crown Design System

---

## Quick Reference

### ✅ APPROVED Color Combinations (WCAG 2.2 AA Compliant)

| Usage | Foreground | Background | Ratio | Safe For |
|-------|------------|------------|-------|----------|
| Primary Dark Text | `#1A2A3A` (Dark Navy) | `#FFFFFF` (White) | 14.62:1 | All text sizes |
| Primary Dark Text | `#1A2A3A` (Dark Navy) | `#F5F3EF` (Cream) | 13.19:1 | All text sizes |
| Primary Light Text | `#006B5E` (Deep Teal) | `#FFFFFF` (White) | 6.43:1 | All text sizes |
| Inverse Light Text | `#FFFFFF` (White) | `#006B5E` (Deep Teal) | 6.43:1 | All text sizes |

### ⚠️ RESTRICTED Color Combinations

| Usage | Foreground | Background | Ratio | Status |
|-------|------------|------------|-------|--------|
| **PROHIBITED** | `#D4A84B` (Royal Gold) | `#FFFFFF` (White) | 2.21:1 | ❌ Fails all levels |
| **PROHIBITED** | `#D4A84B` (Royal Gold) | `#006B5E` (Deep Teal) | 2.91:1 | ❌ Fails all levels |

---

## Priority 1: Immediate Actions (This Week)

### 1.1 Update CSS Design System

**File:** `presentation/css/design-system.css`

Add accessibility annotations to color variables:

```css
:root {
  /* ============================================
     ACCESSIBILITY APPROVED COLOR COMBINATIONS
     All combinations below pass WCAG 2.2 AA
     ============================================ */
  
  /* ✅ SAFE: All text sizes (4.5:1+) */
  --color-primary: #006B5E;
  --color-text: #1A2A3A;
  --color-text-inverse: #FFFFFF;
  --color-background: #F5F3EF;
  --color-background-alt: #FFFFFF;
  
  /* ⚠️ RESTRICTED: See usage guidelines below */
  --color-secondary: #D4A84B;
}

/* ============================================
   ACCESSIBILITY USAGE GUIDELINES
   WCAG 2.2 AA Compliant
   ============================================ */

/* 
 * ROYAL GOLD (#D4A84B) USAGE RESTRICTIONS:
 * 
 * ❌ DO NOT USE FOR:
 *    - Body text or paragraphs
 *    - Small headings (< 18pt)
 *    - Form labels or inputs
 *    - Navigation items
 *    - Buttons (unless with 3px+ stroke)
 *    - Links or interactive elements
 *    - Icons smaller than 24x24px
 *    - Error messages or alerts
 *    - Data visualization text
 * 
 * ✅ APPROVED USES:
 *    - Large headings (18pt / 24px+ or 14pt / 18.5px bold+)
 *    - Decorative borders and dividers
 *    - Background accents
 *    - Large icons (24x24px+)
 *    - Logo and wordmark (exempt per WCAG)
 *    - Charts and graphs (if not the only indicator)
 *    - Award badges and seals
 * 
 * ⚠️ USE WITH CAUTION:
 *    - Component accents (verify 3:1 minimum)
 *    - Hover states (must maintain contrast)
 *    - Focus indicators (must meet 1.4.11)
 */
```

### 1.2 Create Color Usage Matrix

Create a visual reference for the team:

| Color Pair | Normal Text | Large Text | UI Components | Decorative |
|------------|-------------|------------|---------------|------------|
| Dark Navy / White | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Dark Navy / Cream | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Deep Teal / White | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| White / Deep Teal | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Royal Gold / White | ❌ No | ❌ No | ❌ No | ✅ Yes |
| Royal Gold / Deep Teal | ❌ No | ❌ No | ❌ No | ⚠️ Maybe |

### 1.3 Update Component Library

**Buttons:**
```css
/* ✅ APPROVED: Primary Button */
.btn-primary {
  background-color: var(--color-primary); /* Deep Teal */
  color: var(--color-text-inverse); /* White */
  /* Ratio: 6.43:1 - PASSES WCAG AA */
}

/* ✅ APPROVED: Secondary Button */
.btn-secondary {
  background-color: transparent;
  border: 2px solid var(--color-text); /* Dark Navy */
  color: var(--color-text); /* Dark Navy */
  /* Ratio on white: 14.62:1 - PASSES WCAG AA */
}

/* ❌ PROHIBITED: Do not create gold text buttons */
.btn-gold-text {
  /* color: var(--color-secondary); DO NOT USE */
}
```

**Text Styles:**
```css
/* ✅ APPROVED: Body Text */
.body-text {
  color: var(--color-text); /* Dark Navy */
  font-size: 1rem; /* 16px */
  /* Ratio: 14.62:1 on white - PASSES WCAG AA */
}

/* ✅ APPROVED: Headings */
.heading {
  color: var(--color-primary); /* Deep Teal */
  /* Ratio: 6.43:1 on white - PASSES WCAG AA */
}

/* ⚠️ RESTRICTED: Large Accent Headings Only */
.heading-gold {
  color: var(--color-secondary); /* Royal Gold */
  font-size: 1.5rem; /* 24px - Minimum for large text */
  font-weight: 700;
  /* Ratio: 2.21:1 - FAILS WCAG AA for normal text */
  /* Only use for decorative headings 18pt+ */
}
```

---

## Priority 2: Documentation Updates (This Month)

### 2.1 Design System Documentation

Create `docs/accessibility-color-guidelines.md`:

```markdown
# Color Accessibility Guidelines

## Approved Color Combinations

### For Normal Text (< 18pt or < 14pt bold)
| Foreground | Background | Contrast | Usage |
|------------|------------|----------|-------|
| #1A2A3A | #FFFFFF | 14.62:1 | Primary text |
| #1A2A3A | #F5F3EF | 13.19:1 | Text on cream |
| #006B5E | #FFFFFF | 6.43:1 | Accent text, headings |
| #FFFFFF | #006B5E | 6.43:1 | Text on dark backgrounds |

### For Large Text (≥ 18pt or ≥ 14pt bold)
Same as above, plus:
| Foreground | Background | Contrast | Usage |
|------------|------------|----------|-------|
| #D4A84B | #1A2A3A | ~5:1* | Gold headings on dark |

*Requires verification with specific dark background

### Prohibited Combinations
❌ Royal Gold (#D4A84B) on White - 2.21:1 (Fails AA)
❌ Royal Gold (#D4A84B) on Deep Teal - 2.91:1 (Fails AA)
```

### 2.2 Figma/Design Tool Updates

**Color Library Organization:**
```
🎨 Color Palette
├── ✅ Text Safe (4.5:1+)
│   ├── Dark Navy
│   ├── Deep Teal
│   └── White (on dark)
├── ✅ Large Text Safe (3:1+)
│   ├── (Same as above)
│   └── [Empty - no additional colors pass]
├── ⚠️ Decorative Only
│   └── Royal Gold
└── 🔲 Backgrounds
    ├── White
    ├── Cream
    └── Deep Teal
```

**Component Annotations:**
Add accessibility badges to components:
- ✅ WCAG AA - All text sizes
- ⚠️ WCAG AA - Large text only (18pt+)
- ❌ WCAG AA - Decorative use only

---

## Priority 3: Process Integration (Ongoing)

### 3.1 Design Review Checklist

Add to design review template:

```markdown
## Accessibility Review

### Color Contrast
- [ ] All text uses approved color combinations
- [ ] Body text passes 4.5:1 minimum
- [ ] UI components pass 3:1 minimum
- [ ] Focus indicators pass 3:1 minimum
- [ ] Royal Gold only used decoratively or 18pt+

### Testing
- [ ] Checked with WebAIM Contrast Checker
- [ ] Tested with Windows High Contrast mode
- [ ] Tested with macOS Increase Contrast
```

### 3.2 Development Checklist

Add to PR template:

```markdown
## Accessibility

### Color Contrast Verification
- [ ] No new color combinations without contrast check
- [ ] All text colors from approved palette
- [ ] Royal Gold usage documented and approved

### Tools Used
- [ ] axe DevTools - no contrast violations
- [ ] WAVE - no contrast errors
- [ ] Lighthouse Accessibility - 100% score
```

### 3.3 Automated Testing

**CI/CD Integration:**
```yaml
# .github/workflows/accessibility.yml
name: Accessibility Checks

on: [pull_request]

jobs:
  contrast-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install axe-core
        run: npm install -g @axe-core/cli
      - name: Run contrast checks
        run: axe presentation/*.html --tags wcag2aa
```

**Pre-commit Hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check for unsafe color combinations
grep -r "color.*#D4A84B" --include="*.css" --include="*.scss" .
if [ $? -eq 0 ]; then
  echo "⚠️  Warning: Royal Gold detected. Ensure 18pt+ or decorative use."
fi
```

---

## Priority 4: Royal Gold Alternatives (If Needed)

### 4.1 Accessible Gold Alternatives

If Royal Gold must be used for text:

**Option A: Darken Royal Gold**
```css
/* Current: #D4A84B - 2.21:1 on white */
/* Target: 4.5:1 minimum */

/* Calculate required darkness */
/* For 4.5:1 on white, need L ≤ 0.1833 */
/* Current Royal Gold: L = 0.4284 */
/* Required reduction: 57% */

--color-secondary-accessible: #A67C00; /* Estimated */
/* Verify: Should achieve ~4.5:1 on white */
```

**Option B: Use with Text Stroke**
```css
.gold-text-with-stroke {
  color: var(--color-secondary);
  -webkit-text-stroke: 1px var(--color-text);
  text-shadow: 0 0 2px var(--color-text);
  font-size: 1.125rem; /* 18px minimum */
  font-weight: 700;
}
```

**Option C: Background Treatment**
```css
.gold-text-container {
  background-color: var(--color-text); /* Dark Navy */
  padding: 0.5rem 1rem;
}

.gold-text-container .text {
  color: var(--color-secondary); /* Royal Gold */
  /* Ratio on Dark Navy: ~5:1 (estimated) */
}
```

### 4.2 Royal Gold Safe Uses

**✅ Recommended:**
1. **Large Headings (24px+)**
   - Page titles
   - Section headers
   - Hero text

2. **Decorative Elements**
   - Borders and dividers
   - Background patterns
   - Accent shapes

3. **Graphics and Icons**
   - Large icons (32px+)
   - Illustrations
   - Charts (if labeled)

4. **Brand Elements**
   - Logo (exempt per WCAG)
   - Wordmark
   - Awards/badges

**❌ Avoid:**
- Body text
- Form labels
- Navigation
- Small buttons
- Data tables
- Captions
- Footnotes

---

## Priority 5: Training & Education

### 5.1 Team Training

**Session 1: WCAG 2.2 Fundamentals (30 min)**
- Why contrast matters
- WCAG 2.2 AA requirements
- How to use contrast checkers
- Delta Crown color palette review

**Session 2: Design System Updates (20 min)**
- New color restrictions
- Approved combinations
- Component library changes
- Documentation location

**Session 3: Tools & Testing (20 min)**
- WebAIM Contrast Checker
- Browser DevTools
- axe DevTools
- Figma plugins

### 5.2 Quick Reference Cards

Create wallet cards for designers:

```
┌─────────────────────────────────┐
│  DELTA CROWN                    │
│  Color Accessibility Guide      │
├─────────────────────────────────┤
│  ✅ SAFE (All Text)             │
│  • Dark Navy / White            │
│  • Dark Navy / Cream            │
│  • Deep Teal / White            │
│  • White / Deep Teal            │
├─────────────────────────────────┤
│  ⚠️ RESTRICTED                  │
│  • Royal Gold: 18pt+ only       │
│                                 │
│  Check: webaim.org/resources/   │
│  contrastchecker/               │
└─────────────────────────────────┘
```

---

## Priority 6: Existing Content Audit

### 6.1 Presentation Audit Checklist

Review `presentation/index.html` and `presentation/index-material3.html`:

```markdown
## Slide Audit

### Slide-by-Slide Review
- [ ] Slide 1 - Title slide
  - [ ] Heading: Deep Teal on White ✅
  - [ ] Subheading: Dark Navy on White ✅
  
- [ ] Slide 2 - Content slide
  - [ ] Body text: Dark Navy on White ✅
  - [ ] Accent: Verify no Royal Gold text ❓
  
- [ ] Slide 3 - Data slide
  - [ ] Chart text: Verify contrast ❓
  - [ ] Legend: Verify colors ❓

[Continue for all slides...]
```

### 6.2 Remediation Plan

**Critical Issues (Fix Immediately):**
- Any Royal Gold text < 18pt
- Any Royal Gold on white/deep teal backgrounds
- Any low contrast focus indicators

**High Priority (Fix This Week):**
- Review all headings for proper size/contrast
- Verify button contrast ratios
- Check icon colors

**Medium Priority (Fix This Month):**
- Update style guide documentation
- Add accessibility notes to components
- Create training materials

---

## Success Metrics

### Month 1 Targets
- [ ] 100% of new designs use approved combinations
- [ ] 0 Royal Gold text violations in new work
- [ ] All team members trained
- [ ] Documentation complete

### Month 3 Targets
- [ ] 100% of existing presentations audited
- [ ] All critical issues remediated
- [ ] Automated testing in CI/CD
- [ ] Zero contrast violations in automated scans

### Month 6 Targets
- [ ] WCAG 2.2 AA compliance across all materials
- [ ] Regular accessibility reviews scheduled
- [ ] Team self-sufficient in contrast checking
- [ ] Accessibility integrated into design process

---

## Resources

### Tools
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [WAVE Browser Extension](https://wave.webaim.org/extension/)
- [axe DevTools](https://www.deque.com/axe/devtools/)
- [Stark Figma Plugin](https://www.getstark.co/)
- [Colour Contrast Analyser (CCA)](https://www.tpgi.com/color-contrast-checker/)

### Documentation
- [WCAG 2.2 Specification](https://www.w3.org/TR/WCAG22/)
- [Understanding SC 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- [Understanding SC 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)

### Internal Files
- `./research/wcag-color-contrast/README.md` - Executive summary
- `./research/wcag-color-contrast/detailed-results.md` - Complete calculations
- `./contrast-calculator.py` - Python calculation script

---

## Contact & Questions

**Accessibility Questions:**
- Design System: [Design Team Lead]
- WCAG Technical: [Development Lead]
- Legal/Compliance: [Legal Team]

**Emergency Contrast Issues:**
- Check immediately with WebAIM Contrast Checker
- Default to Dark Navy/Deep Teal combinations if unsure
- Document any exceptions for review

---

*Last Updated: 2025*  
*WCAG Version: 2.2*  
*Compliance Level: AA*
