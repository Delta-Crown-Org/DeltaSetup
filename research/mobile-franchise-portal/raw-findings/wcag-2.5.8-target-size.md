# WCAG 2.2: Target Size (Minimum) - SC 2.5.8

**Source**: W3C Web Accessibility Initiative (WAI) - Official Documentation
**URL**: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
**Date Retrieved**: March 31, 2025
**Source Tier**: Tier 1 (Highest - Official W3C Standards)

## Success Criterion (Level AA)

The size of the target for pointer inputs is at least **24 by 24 CSS pixels**, except when:

### Exceptions

1. **Spacing**: Undersized targets (less than 24×24 CSS pixels) are positioned so that if a 24 CSS pixel diameter circle is centered on the bounding box of each, the circles do not intersect another target or the circle for another undersized target

2. **Equivalent**: The function can be achieved through a different control on the same page that meets this criterion

3. **Inline**: The target is in a sentence or its size is otherwise constrained by the line-height of non-target text

4. **User Agent Control**: The size of the target is determined by the user agent and is not modified by the author

5. **Essential**: A particular presentation of the target is essential or is legally required for the information being conveyed

## Key Intent

The intent is to help ensure targets can be easily activated without accidentally activating an adjacent target. Users with dexterity limitations and those who have difficulty with fine motor movement find it difficult to accurately activate small targets when there are other targets that are too close.

### Disabilities Addressed
- Hand tremors
- Spasticity
- Quadriplegia
- Reduced fine motor control
- Touchscreen users with large fingers
- One-handed device operation

## Important Notes

1. **Zoom Independence**: The requirement is independent of the zoom factor of the page; when users zoom in, the CSS pixel size of elements does not change

2. **Best Practice Recommendation**: While 24×24 CSS pixels is the minimum, authors are encouraged to meet this minimum regardless of spacing. For important links/controls, consider aiming for the stricter 2.5.5 Target Size (Enhanced - 44×44 CSS pixels)

3. **Target Definition**: Targets that allow for values to be selected spatially based on position within the target are considered one target (e.g., sliders, color pickers, editable areas)

## Implementation for Franchise Portals

### Critical Touch Targets
- Navigation buttons
- Action buttons (Submit, Save, Cancel)
- Form inputs and controls
- Card actions
- Quick action buttons

### Design Considerations
- Use minimum 24×24 CSS pixel touch targets
- Consider 44×44 CSS pixels for frequently-used controls (enhanced standard)
- Ensure adequate spacing between adjacent targets
- Account for users operating devices with gloved hands or in mobile environments

## Benefits

- People using mobile devices with touchscreens
- People with mobility impairments (hand tremors)
- People using devices in shaking environments (public transportation)
- Mouse users with difficulty in fine motor movements
- People accessing devices using one hand
- People with large fingers or operating with partial finger/knuckle
