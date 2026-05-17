# Raw findings — responsive nav/drawer as modal dialog

Source: W3C WAI-ARIA Authoring Practices Guide, Dialog (Modal) Pattern.  
URL: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/

Relevant extracted guidance:

- A modal dialog overlays the primary window; windows under a modal dialog are inert and users cannot interact with outside content.
- Modal dialogs contain their tab sequence; Tab and Shift+Tab do not move focus outside the dialog.
- Escape closes the dialog.
- When a dialog opens, focus moves to an element inside it; placement depends on content and task.
- When it closes, focus generally returns to the invoking element unless workflow requires a different logical target.
- It is strongly recommended that tab sequence includes a visible close/cancel button.
- Dialog container has role `dialog`, `aria-modal=true`, and label via `aria-labelledby` or `aria-label`.
- Warning: mark a dialog modal only when code prevents all users from interacting outside it and visual styling obscures outside content; otherwise assistive technology users can experience severe negative ramifications.

DCE implication:

A mobile nav drawer that dims/locks the page should behave like a modal dialog. If it simply expands inline, it should not use modal semantics. The manual review must verify focus entry, trapped tab sequence only when modal, Escape/close behavior, and focus return to the hamburger/menu button.