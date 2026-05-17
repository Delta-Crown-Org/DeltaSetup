# Raw findings — automated accessibility coverage limits

## W3C WAI — Selecting Web Accessibility Evaluation Tools

URL: https://www.w3.org/WAI/test-evaluate/tools/selecting/

Extracted findings:

- Evaluation tools help quickly identify potential accessibility issues.
- Tools can provide fully automated checks and help with manual review.
- Tools cannot check all accessibility aspects automatically.
- Human judgement is required.
- Tools can produce false or misleading results.
- Evaluation tools cannot determine accessibility; they can only assist.
- Teams often benefit from a combination of tools across stages/roles.

## W3C WAI — WCAG-EM Overview

URL: https://www.w3.org/WAI/test-evaluate/conformance/wcag-em/

Extracted findings:

- Effective conformance evaluation requires expertise in accessibility standards, accessible design/development, assistive technologies, and how people with disabilities use the Web.
- WCAG-EM steps include defining scope, exploring website assets, selecting representative samples, evaluating samples, and reporting findings.
- WCAG-EM recommends involving real users with disabilities to address real-life experience.
- Accessibility should be integrated throughout planning, design, and development rather than left until evaluation.

## Deque — Axe Platform FAQ

URL: https://www.deque.com/axe/

Extracted findings:

- Accessibility testing types include automated, semi-automated, and manual.
- Manual testing uses assistive technology and expertise/lived experience to identify complex barriers automation cannot detect.
- Axe-core is the automated rules engine; additional products add reporting/guided/manual capabilities.

DCE implication:

The repo’s static/axe/browser smoke audits should remain mandatory gates, but review conclusions must include manual keyboard, focus, drawer, target-size, and contrast observations. Automated pass is not equivalent to WCAG conformance.