# Apple Human Interface Guidelines - Buttons

**Source**: Apple Developer Documentation - Official HIG
**URL**: https://developer.apple.com/design/human-interface-guidelines/buttons
**Date Retrieved**: March 31, 2025
**Source Tier**: Tier 1 (Highest - Official Apple Guidelines)

## Touch Target Requirements

### Minimum Hit Region
- **Standard**: 44×44 points minimum
- **visionOS**: 60×60 points minimum

This ensures people can select buttons easily, whether they use:
- Fingertip
- Pointer
- Eyes (visionOS)
- Remote

## Best Practices

### Button Spacing
- Include enough space around buttons for visual distinction
- Critical for various input methods
- Helps prevent accidental activation of adjacent controls

### Visual States
- Always include a press state for custom buttons
- Without press state, buttons feel unresponsive
- Users need feedback that input is accepted

### Button Roles
1. **Normal**: No specific meaning
2. **Primary**: Default button, most likely choice
3. **Cancel**: Cancels current action
4. **Destructive**: Results in data destruction

### Style Guidelines
- Use prominent style for most likely action (limit to 1-2 per view)
- Use style, not size, to distinguish preferred choice
- Avoid similar colors for button labels and backgrounds
- Keep button sizes consistent within option sets

## Platform-Specific Guidance

### iOS/iPadOS
- Configure activity indicators for non-instant actions
- Display alternative labels during delays (e.g., "Checkout" → "Checking out...")

### visionOS
- Three standard shapes: circular, capsule, rounded rectangle
- Sizes: Mini (28pt), Small (32pt), Regular (44pt), Large (52pt), Extra large (64pt)
- Prefer circular or capsule shapes for easier focus
- Place button centers at least 60 pts apart
- Use thin material background on glass windows
- Use glass material when floating in space

### watchOS
- All inline buttons use capsule shape
- Use full-width buttons for primary actions
- Toolbar buttons for navigation/contextual actions
- Maintain consistent heights in vertical stacks

## Content Guidelines

- Combine symbol/icon, text label, or both
- Use familiar icons for predictable actions
- Use text when it communicates more clearly than icons
- Write succinct descriptions (verb-first recommended, e.g., "Add to Cart")
- Use title-style capitalization

## Implementation for Franchise Portals

### Critical Requirements
- Minimum 44×44 point touch targets for all interactive elements
- Ensure adequate spacing between adjacent buttons
- Provide clear press/touch feedback states
- Use consistent button sizing within related action groups

### Recommendations
- Use primary button style for most common actions
- Include activity indicators for network operations
- Consider watchOS users who may need companion app access
- Design for one-handed thumb operation on mobile devices
