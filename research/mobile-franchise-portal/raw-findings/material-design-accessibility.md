# Material Design Accessibility Guidelines - Touch Targets

**Source**: Google Material Design - Official Documentation
**URL**: https://m2.material.io/design/usability/accessibility.html
**Date Retrieved**: March 31, 2025
**Source Tier**: Tier 1 (Highest - Official Google Guidelines)

## Touch Targets

Touch targets are the parts of the screen that respond to user input. They extend **beyond the visual bounds** of an element.

### Example
An icon may appear to be 24×24 dp, but the padding surrounding it comprises the full **48×48 dp touch target**.

### Minimum Touch Target Size

- **Standard**: At least **48×48 dp**
- **Physical size**: Results in about 9mm, regardless of screen size
- **Recommended target size**: 7-10mm for touchscreen elements
- **iOS specific**: 44×44 pt recommended

### Touch Target Spacing

Touch targets separated by **8dp of space or more** promote balanced information density and usability.

**Example Layout:**
- Touch target height: 48dp
- Button height: 36dp
- Padding creates the additional touch target area

### Pointer Targets

Similar to touch targets but apply to motion-tracking pointer devices (mouse or stylus):
- Minimum: **44×44 dp**

## Visual Example

```
Android target sizes are 48 x 48 dp.

Avatar: 40dp visible
Icon: 24dp visible  
Touch target on both: 48dp (includes padding)
```

## Screen Reader Navigation

### Navigation Methods

1. **Explore by Touch** (TalkBack)
   - Users run finger over screen to hear content
   - Double-tap to select items
   - Quick sense of entire interface
   - Muscle memory navigation

2. **Linear Navigation**
   - Swipe backwards/forwards to read top-to-bottom
   - Allows users to focus on specific elements

### Navigation by Landmark

Assistive technologies allow navigation between page landmarks (headings) when using appropriate semantic markup.

## Color and Contrast

### Contrast Ratios (W3C Recommendations)

| Text Type | Color Contrast Ratio |
|-----------|---------------------|
| Large text (14pt bold/18pt regular and up) and graphics | 3:1 against background |
| Small text | 4.5:1 against background |

### Alternative Visual Cues

For colorblind users (red-green, blue-yellow, monochromatic):
- Use strokes, indicators, patterns, texture, or text
- Multiple visual cues communicate important states
- Don't rely solely on color

## Typography

### Scalable Text
- Mobile devices allow system-wide font size adjustment
- Android: Mark text and containers in **scalable pixels (sp)**
- Ensure sufficient space for large and foreign language fonts

### Line Height
- Recommended sizes for foreign language fonts (see Material Design typography guidelines)

## Accessibility Text

### Visible and Nonvisible Text
- **Visible text**: Labels, button text, links, forms
- **Nonvisible text**: Alternative text for images, descriptions

### Alternative Text (Alt Text)

**Guidelines:**
- Maximum 125 characters (screen reader limit)
- Don't start with "image of" or "picture of" (screen readers announce this)
- Be concise but informative
- Include targeted keywords
- Focus on what the image shows

**Examples:**

✅ **Good**: "A rooftop view of the Tokyo Tower and skyline at night"
❌ **Too short**: "Skyline"
❌ **Too long**: Detailed paragraphs (gets truncated)
❌ **SEO stuffing**: Keyword spam instead of description

### Captions vs Alt Text

**Use captions for:**
- Long descriptions (who, what, when, where)
- Contextual information
- Available to all users

**Use alt text for:**
- Short image descriptions (under 125 characters)
- Characteristics not explained in captions/adjacent text
- Color, size, location descriptions

**Avoid:** Repeating the same content in both captions and alt text

## Control Types and States

### Accessibility Roles
- Set buttons as buttons, checkboxes as checkboxes
- Extend native UI elements when possible
- For web: use ARIA labels
- For Android: use AccessibilityNodeInfo

### State Changes
Screen readers automatically announce control types or states:
- "on" or "off" for toggles
- "selected" for selected items
- Control names for custom elements

### Hint Speech
- Provides extra information for unclear actions
- Example: "double-tap to select"
- Android TalkBack announces custom actions

## Imagery

### Decorative vs Informative Images

**Decorative Images:**
- Don't add information to page content
- Don't need captions
- Don't need to meet contrast guidelines
- Use null alt tag: `alt=""`

**Informative Images:**
- Convey concepts in short, digestible manner
- Need captions for long descriptions
- Need alt text if not explained by adjacent text
- Must meet color contrast guidelines for essential items

### Essential vs Non-Essential Elements

**Essential information:**
- Text meeting contrast ratios and size requirements
- Illustrative representations following contrast guidelines

**Non-essential elements:**
- Decorative background elements
- Elements that don't relay information
- Don't need to meet contrast requirements

### Functional Images

Logos, icons, images within buttons, actionable images:
- Alt text depicts the **function**, not content or appearance
- Use action verbs

**Example:**
- Logo linking to home: Alt text "Link to Google Search home"

## Motion Considerations

### Accessibility Requirements (W3C)

1. Enable content that moves, scrolls, or blinks automatically to be **paused, stopped, or hidden** if it lasts more than five seconds
2. Limit flashing content to **three times in one-second period** (flash/red flash thresholds)
3. Avoid flashing large central regions of the screen

### Motion Sensitivity
- Material Design uses motion to guide focus
- Support users with motion and vision sensitivities
- Provide options to reduce motion

## Implementation Guidelines

### Testing Checklist

- [ ] Test full task completion with assistive technologies
- [ ] Test with TalkBack/screen readers
- [ ] Change reading speeds during testing
- [ ] Have users with impairments test the app
- [ ] Verify primary tasks work for wide range of users

### Label UI Elements

Enable screen readers to read component names:
- Add `contentDescription` attribute (Android)
- Add `aria-label` (Web)
- Label icons without visible text

### Responsive Design

- Scale UI to work with magnification and large text
- Avoid content overlap or cutoff with large text
- Test with various assistive settings enabled

## Implementation for Franchise Portals

### Critical Requirements

1. **Touch Targets**: Minimum 48×48 dp for all interactive elements
2. **Spacing**: At least 8dp between adjacent touch targets
3. **Contrast**: 4.5:1 for small text, 3:1 for large text/graphics
4. **Alt Text**: Concise descriptions (under 125 characters)
5. **Semantic HTML**: Proper heading structure and landmark navigation

### Android-Specific
- Use `sp` units for scalable text
- Implement AccessibilityNodeInfo for custom views
- Support TalkBack "explore by touch" and linear navigation

### Design Considerations
- Use multiple visual cues (not just color)
- Provide pause/stop controls for auto-playing content
- Test with screen magnification enabled
- Ensure keyboard-only navigation works
- Allow users to reduce motion
