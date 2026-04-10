# Manual Accessibility Testing Checklist

## Overview

Automated tools can detect approximately **60-70%** of WCAG failures. The remaining **30-40%** require manual testing and expert review. This checklist identifies requirements that **cannot be fully automated** and must be tested manually.

---

## Requirements That Cannot Be Automated

### Summary Statistics

| WCAG Version | Total Level AA Criteria | Automatable | Manual Only |
|--------------|------------------------|-------------|-------------|
| WCAG 2.1 | 50 | ~35 (70%) | ~15 (30%) |
| WCAG 2.2 | 58 | ~40 (69%) | ~18 (31%) |

**Key Insight**: Manual testing is required for all cognitive accessibility, meaningful sequence, and complex interaction patterns.

---

## Level A Criteria Requiring Manual Testing

### 1.3.1 Info and Relationships

**Automated Testing Limitation**: Tools can detect programmatic relationships but cannot assess semantic accuracy.

**Manual Testing Required**:
- [ ] Verify heading hierarchy reflects document structure
- [ ] Check that lists (`<ul>`, `<ol>`) are used for true lists, not layout
- [ ] Confirm tables are used for data, not layout (when appropriate)
- [ ] Verify form labels correctly describe their inputs
- [ ] Check that ARIA relationships match visual relationships

**Testing Procedure**:
```
1. Turn off CSS (browser dev tools)
2. Verify reading order matches logical order
3. Check that structural elements (h1-h6) create outline
4. Screen reader: Navigate by headings and verify hierarchy
5. Verify tables read logically when linearized
```

### 1.3.2 Meaningful Sequence

**Automated Limitation**: Cannot determine if sequence is meaningful without human judgment.

**Manual Testing Required**:
- [ ] Read content in source order
- [ ] Verify understanding without visual layout
- [ ] Check complex layouts (magazine-style, grid)
- [ ] Test responsive design at different breakpoints

**Testing Tools**:
- CSS Bookmarklet: Disable CSS (`javascript:document.styleSheets[0].disabled=true;`)
- Screen reader linear reading mode

### 1.3.3 Sensory Characteristics

**Automated Limitation**: Requires human judgment about instructions.

**Manual Testing Required**:
- [ ] Instructions don't rely solely on shape, size, visual location
- [ ] "Click the red button" → "Click the Delete button"
- [ ] "Use the menu on the left" → "Use the Navigation menu"
- [ ] "Click the circular icon" → "Click the Settings icon"

**Checklist for Franchise Portals**:
- [ ] Training module navigation doesn't rely on color alone
- [ ] Document status indicators include text labels
- [ ] Form error messages reference field names, not just position
- [ ] Icon buttons have visible text labels or accessible names

### 2.1.1 Keyboard

**Automated Limitation**: Can detect focusable elements but not keyboard operability.

**Manual Testing Required**:
- [ ] All functionality operable with keyboard only
- [ ] No keyboard traps (can Tab out of all components)
- [ ] Custom widgets work with expected keys (Enter, Space, Arrows)
- [ ] Focus order is logical
- [ ] Complex interactions work (drag-drop alternatives, sliders)

**Keyboard Testing Matrix**:

| Key | Expected Action | Test Cases |
|-----|-----------------|------------|
| Tab | Move to next focusable | All interactive elements |
| Shift+Tab | Move to previous | All interactive elements |
| Enter | Activate control | Buttons, links |
| Space | Toggle/select | Checkboxes, buttons |
| Arrow Keys | Navigate within widget | Menus, tabs, lists |
| Escape | Close/cancel | Modals, menus, dialogs |
| Home/End | Jump to beginning/end | Lists, text fields |

### 2.1.2 No Keyboard Trap

**Manual Testing**:
- [ ] Tab through entire page
- [ ] Verify can Tab out of all components
- [ ] Test modal dialogs (focus must return on close)
- [ ] Check rich text editors (often trap focus)
- [ ] Verify iframe navigation

### 2.4.3 Focus Order

**Manual Testing Required**:
- [ ] Tab through page following visual layout
- [ ] Focus order matches visual/logical order
- [ ] No unexpected focus jumps
- [ ] Focus doesn't move unexpectedly without user action
- [ ] Check complex layouts: sidebars, grids, multi-column

### 2.4.4 Link Purpose (In Context)

**Automated Limitation**: Can check for generic text but not contextual meaning.

**Manual Testing Required**:
- [ ] Link text makes sense in context
- [ ] "Read More" links have surrounding context
- [ ] Multiple "Click Here" links are distinguishable
- [ ] Same link text leads to same destination

**Bad Examples**:
```html
❌ <a href="...">Read More</a> (without context)
❌ <a href="...">Click Here</a> (vague)
❌ <a href="...">Download</a> (what is being downloaded?)
```

**Good Examples**:
```html
✅ <a href="...">Read more about Safety Training</a>
✅ <a href="...">Download Operations Manual (PDF)</a>
✅ <a href="...">View Franchise Agreement</a>
```

### 2.4.6 Headings and Labels

**Manual Testing Required**:
- [ ] Headings describe topic/purpose accurately
- [ ] Labels describe the purpose of associated controls
- [ ] No skipped heading levels (h1 → h3 without h2)
- [ ] No heading-like text that's not semantically a heading

**Testing with Screen Reader**:
```
1. Open screen reader
2. Navigate by headings (H key in NVDA/JAWS)
3. Verify each heading describes its section
4. Check heading levels create logical outline
```

### 2.5.1 Pointer Gestures

**Manual Testing**:
- [ ] Verify all pointer gestures have single-pointer alternatives
- [ ] Multi-point gestures (pinch, zoom, swipe) have alternatives
- [ ] Drag operations can be completed without dragging (2.5.7)

### 3.1.1 Language of Page

**Manual Verification**:
- [ ] Primary language is correctly identified
- [ ] `lang` attribute matches actual content language
- [ ] Multi-language pages have correct primary language

### 3.1.2 Language of Parts

**Manual Testing Required**:
- [ ] Foreign language phrases marked with `lang` attribute
- [ ] Screen reader announces language changes
- [ ] Check for: product names, quotes, foreign terms

### 3.2.1 On Focus

**Manual Testing**:
- [ ] Focus doesn't trigger context changes automatically
- [ ] No new windows/popups on focus
- [ ] No form submission on focus
- [ ] Focus doesn't trigger navigation

### 3.2.2 On Input

**Manual Testing**:
- [ ] Changing input doesn't auto-submit form
- [ ] No unexpected context changes on input
- [ ] User notified if input causes automatic changes
- [ ] Check select menus that auto-navigate (bad practice)

### 3.3.1 Error Identification

**Manual Testing Required**:
- [ ] Errors clearly identified
- [ ] Error messages are specific
- [ ] Error location is indicated
- [ ] Screen reader announces errors

**Testing Procedure**:
```
1. Submit form with errors
2. Verify error is clearly identified
3. Check error is programmatically associated
4. Verify screen reader announces errors
```

### 3.3.2 Labels or Instructions

**Manual Testing**:
- [ ] Labels are visible and descriptive
- [ ] Required fields are indicated
- [ ] Format requirements are provided
- [ ] Instructions are clear and available

### 4.1.2 Name, Role, Value

**Manual Testing Required**:
- [ ] Custom components expose correct role
- [ ] Accessible names describe purpose
- [ ] State changes announced (expanded/collapsed)
- [ ] Values update correctly

**Screen Reader Testing**:
```
1. Navigate to custom widget
2. Verify screen reader announces role (button, link, etc.)
3. Verify accessible name is clear
4. Trigger state change
5. Verify state is announced
```

---

## Level AA Criteria Requiring Manual Testing

### 1.4.3 Contrast (Minimum)

**Automated Limitation**: Can detect calculated contrast but not human perception.

**Manual Testing Required**:
- [ ] Text remains readable in different lighting conditions
- [ ] Anti-aliasing doesn't affect readability
- [ ] Contrast is sufficient for small text (4.5:1)
- [ ] Contrast is sufficient for large text (3:1)
- [ ] Focus indicators meet contrast requirements

**Testing Tools**:
- Color contrast analyzer (browser extension)
- Grayscale mode (accessibility settings)

### 1.4.4 Resize Text

**Manual Testing**:
- [ ] Text resizes to 200% without assistive technology
- [ ] No horizontal scrolling at 200% (unless required)
- [ ] All functionality available at 200%
- [ ] Content doesn't overlap or truncate

**Testing Procedure**:
```
1. Set browser zoom to 200%
2. Navigate through entire site
3. Check for horizontal scrolling
4. Verify all content is accessible
5. Test interactive elements
```

### 1.4.10 Reflow

**Manual Testing Required**:
- [ ] Content reflows without horizontal scrolling at 320px
- [ ] Content order is preserved
- [ ] No functionality lost on narrow screens
- [ ] Tables reflow or horizontal scroll is available

### 1.4.11 Non-text Contrast

**Manual Testing**:
- [ ] Icons have 3:1 contrast against background
- [ ] Form field boundaries have 3:1 contrast
- [ ] Focus indicators have 3:1 contrast
- [ ] Custom UI components meet contrast

### 1.4.12 Text Spacing

**Manual Testing**:
- [ ] Content remains functional with increased spacing:
  - Line height: 1.5
  - Paragraph spacing: 2x font size
  - Letter spacing: 0.12em
  - Word spacing: 0.16em
- [ ] No content cut off or overlapping

### 1.4.13 Content on Hover or Focus

**Manual Testing**:
- [ ] Hover content is dismissible (Escape key)
- [ ] Hover content doesn't disappear on hover
- [ ] Hover content remains visible until dismissed
- [ ] Content doesn't trigger unexpectedly

### 2.4.5 Multiple Ways

**Manual Testing**:
- [ ] Multiple ways to find pages (search, navigation, sitemap)
- [ ] Exceptions: multi-step processes, exclusive content
- [ ] Check for search functionality availability
- [ ] Verify navigation consistency

### 2.4.7 Focus Visible

**Manual Testing Required**:
- [ ] Focus indicator is visible on all interactive elements
- [ ] Focus indicator visible on custom widgets
- [ ] Focus indicator has sufficient contrast
- [ ] Check with different browsers

**Important**: Automated tools often miss focus visibility issues on custom components.

### 2.4.11 Focus Not Obscured (WCAG 2.2)

**Manual Testing**:
- [ ] Tab through page with sticky headers/footers
- [ ] Verify focused element is at least partially visible
- [ ] Test with modals open
- [ ] Check with notification banners
- [ ] Verify with screen magnification

### 2.4.13 Focus Appearance (WCAG 2.2)

**Manual Testing Required**:
- [ ] Calculate focus indicator area (2px thick perimeter minimum)
- [ ] Verify 3:1 contrast change between focused/unfocused
- [ ] Test focus indicators on complex backgrounds
- [ ] Check focus on compound components (tablists, grids)

### 2.5.7 Dragging Movements (WCAG 2.5.7)

**Manual Testing**:
- [ ] Identify all drag operations (drag-drop, sliders)
- [ ] Verify single-pointer alternatives exist
- [ ] Test alternatives work without dragging
- [ ] Check touch screen compatibility

### 2.5.8 Target Size (WCAG 2.5.8)

**Manual Testing**:
- [ ] Measure clickable targets (minimum 24×24px)
- [ ] Verify spacing exception applied correctly
- [ ] Test on touch devices
- [ ] Check inline link exception

### 3.2.6 Consistent Help (WCAG 3.2.6)

**Manual Testing**:
- [ ] Verify help in consistent location across pages
- [ ] Check help order is maintained
- [ ] Test across page variations (mobile/desktop)
- [ ] Verify within "set of web pages"

### 3.3.3 Error Suggestion

**Manual Testing Required**:
- [ ] Error messages suggest corrections
- [ ] Suggestions are specific and helpful
- [ ] Security exception respected (no suggestion for password)
- [ ] Check: spelling errors, format errors, missing required

### 3.3.4 Error Prevention (Legal, Financial, Data)

**Manual Testing**:
- [ ] Critical submissions are reversible
- [ ] Data can be checked before final submission
- [ ] Confirmation available before completing action
- [ ] Test: financial transactions, legal commitments

### 3.3.7 Redundant Entry (WCAG 3.3.7)

**Manual Testing**:
- [ ] Multi-step processes don't require re-entry
- [ ] Auto-population works correctly
- [ ] "Same as" options function properly
- [ ] Previously entered data available for selection

### 3.3.8 Accessible Authentication (WCAG 3.3.8)

**Manual Testing Required**:
- [ ] Verify paste works in password fields
- [ ] Check for cognitive function tests (CAPTCHA, puzzles)
- [ ] Verify alternatives available
- [ ] Test with password manager
- [ ] Check MFA flow accessibility

---

## Cognitive Accessibility Testing

**Not covered by WCAG 2.2 specifically** - requires expert review.

### Manual Testing Areas

| Aspect | Testing Method | Priority |
|--------|----------------|----------|
| Clear Language | Readability assessment (Flesch-Kincaid) | High |
| Consistent Navigation | Task completion testing | High |
| Error Prevention | Usability testing with diverse users | High |
| Memory Support | Multi-step task testing | Medium |
| Attention Management | Distraction elimination | Medium |
| Understanding | Comprehension testing | High |

### Cognitive Testing Checklist

- [ ] **Plain Language**: Content at 8th-grade reading level or below
- [ ] **Jargon**: Technical terms explained or avoided
- [ ] **Instructions**: Clear, step-by-step, numbered
- [ ] **Consistency**: Same labels mean same thing across site
- [ ] **Predictability**: Actions have expected results
- [ ] **Error Recovery**: Clear path forward from errors
- [ ] **Cognitive Load**: No information overload
- [ ] **Reading Level**: Test with readability tools

**Testing Tools**:
- Hemingway Editor (readability)
- Grammarly (clarity)
- User testing with cognitive disability focus groups

---

## Screen Reader Testing Requirements

### Critical for Manual Testing

| Screen Reader | Platform | Priority |
|---------------|----------|----------|
| NVDA | Windows | Critical |
| JAWS | Windows | Critical |
| VoiceOver | macOS/iOS | High |
| TalkBack | Android | High |
| Narrator | Windows | Medium |

### Testing Scenarios

**Navigation Testing**:
- [ ] Navigate by headings (H key)
- [ ] Navigate by landmarks (D key)
- [ ] Navigate by form fields (F key)
- [ ] Navigate by links (L key)
- [ ] Navigate by tables (T key)
- [ ] Navigate by lists (I key)
- [ ] Navigate by buttons (B key)

**Reading Testing**:
- [ ] Continuous reading (Insert + Down)
- [ ] Character-by-character review
- [ ] Word-by-word review
- [ ] Line-by-line review

**Interaction Testing**:
- [ ] Form completion with screen reader
- [ ] Error message announcements
- [ ] Dynamic content updates (ARIA live regions)
- [ ] Modal dialog navigation
- [ ] Alert and notification reading

### Key Screen Reader Checks

```
1. Turn on screen reader
2. Close eyes or look away
3. Navigate using keyboard only
4. Complete common tasks (login, find document, submit form)
5. Verify understanding of page structure
6. Check that dynamic content is announced
7. Verify error recovery is possible
```

---

## Manual Testing Schedule

### Frequency Recommendations

| Testing Type | Sprint | Release | Quarterly | Annual |
|--------------|--------|---------|-----------|--------|
| Automated | ✅ | ✅ | ✅ | ✅ |
| Keyboard | ✅ | ✅ | ✅ | ✅ |
| Screen Reader | - | ✅ | ✅ | ✅ |
| Cognitive | - | - | ✅ | ✅ |
| Full Audit | - | - | - | ✅ |

### Testing Team

**Minimum Team**:
- 1 accessibility specialist
- 1 QA engineer with accessibility training
- 1 user with disabilities (testing)

**Recommended Team**:
- 2+ accessibility specialists
- QA team trained on manual testing
- Regular user testing with disabled users
- Automated testing in CI/CD

---

## Testing Documentation

### Manual Test Report Template

```markdown
## Manual Accessibility Test Report

**Date**: [Date]
**Tester**: [Name]
**Page/Feature**: [URL/Feature]
**WCAG Version**: 2.2 Level AA

### Test Results

#### Keyboard Testing
- [ ] Pass
- [ ] Fail
- [ ] N/A

**Notes**:

#### Screen Reader Testing
- [ ] Pass
- [ ] Fail
- [ ] N/A

**Notes**:

#### Focus Management
- [ ] Pass
- [ ] Fail
- [ ] N/A

**Notes**:

#### Cognitive Accessibility
- [ ] Pass
- [ ] Fail
- [ ] N/A

**Notes**:

### Issues Found

| Severity | WCAG Criterion | Issue Description | Remediation |
|----------|----------------|-------------------|-------------|
| Critical | 2.1.1 | Keyboard trap in modal | Add focus management |

### Sign-off
- [ ] Ready for release
- [ ] Requires remediation
- [ ] Conditional release with known issues
```

---

## Source References

- W3C WCAG-EM: https://www.w3.org/WAI/test-evaluate/conformance/wcag-em/
- WebAIM Cognitive Guide: https://webaim.org/articles/cognitive/
- WCAG Testing Rules: https://www.w3.org/WAI/standards-guidelines/act/rules/
- Screen Reader Testing Guide: https://webaim.org/articles/screenreader_testing/
