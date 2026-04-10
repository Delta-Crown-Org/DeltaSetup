# Project-Specific Recommendations: Delta Crown Extensions Presentation

## Context

The Delta Crown Extensions presentation is an HTML/CSS/JS slide deck (`presentation/index.html`) using Material 3 design system with a luxury brand aesthetic (Playfair Display + Tenor Sans typography, royal gold accents, deep teal primary). It presents a Microsoft 365 / SharePoint architecture proposal to executive stakeholders.

---

## Priority 1: Structural Improvements (Highest Impact)

### 1.1 Apply the 12-Slide Framework

Map the current presentation to the research-validated executive structure:

| Slide # | Purpose | Current Status | Action Needed |
|---------|---------|----------------|---------------|
| 1 | Title | ✅ Exists | Keep — sets brand tone |
| 2 | Executive Summary | ❓ Check if exists | **Add if missing** — 60-second overview with recommendation, 3 key points, and the ask |
| 3 | Situation | Likely exists as context | Ensure it states current reality concisely |
| 4 | Problem/Opportunity | May be embedded | Make it a standalone slide — quantify the cost of the status quo |
| 5 | Recommendation | Architecture slides | Lead with "what" before "how" |
| 6 | Implementation Plan | May exist | Focus on phases and timeline |
| 7 | Resource Requirements | May exist | Clear budget and staffing needs |
| 8 | Risk Assessment | Check | Top 3-5 risks with mitigation |
| 9 | Timeline | Check | Milestones, not Gantt charts |
| 10 | Success Metrics | Check | How you'll measure ROI |
| 11 | Governance | Check | Who's accountable |
| 12 | The Ask | ❓ Check | **Must exist** — specific decision/approval needed |

### 1.2 Ensure Every Slide Title is an Assertion

**Current pattern observed in HTML:**
```
"SharePoint Hub & Spoke Architecture"     ← Topic phrase (WEAK)
"Operational Efficiency Gains"             ← Topic phrase (WEAK)
```

**Research-validated pattern:**
```
"Hub & Spoke Architecture Cuts Per-Brand IT Costs to Zero"     ← Assertion (STRONG)
"Unified Operations Save 15+ Hours/Week Across 5 Brands"      ← Assertion (STRONG)
```

**Validation test:** Read only the slide titles in sequence. Do they make the full case for approval? If yes, you've nailed it.

### 1.3 Add a Decision Slide at the End

The presentation must end with a specific, unambiguous ask:

```
Recommendation: Approve Phase 1 Implementation

Investment: $X | Timeline: Y weeks | Risk: Mitigated

Specific ask: [Budget approval / Go-ahead / Resource allocation]
Deadline: [Why this needs to happen now]
Next step: [What happens immediately upon approval]
```

---

## Priority 2: Cognitive Load Optimization (High Impact)

### 2.1 Apply the 3-Second Rule to Every Slide

For each slide in `index.html`, verify:
- [ ] Can the main point be grasped in 3 seconds?
- [ ] Is there a single dominant visual element?
- [ ] Is the slide title an assertion (not a topic phrase)?
- [ ] Are there ≤3 supporting points?

### 2.2 Reduce Text Density

From the HTML review, the presentation uses Material 3 cards with text content. Ensure:
- **Maximum 20 words of body text per card** (Duarte's guideline)
- **Icons + short labels** over paragraph descriptions
- **One key metric per card** for metric cards
- **Remove any text that repeats what the speaker will say** (Redundancy Principle)

### 2.3 Optimize the Architecture Diagrams

The Hub & Spoke slide (Slide 5b/6) uses a visual diagram approach — this is good. Verify:
- [ ] The diagram communicates the concept without reading any text
- [ ] Labels are placed directly on/near elements (Spatial Contiguity Principle)
- [ ] The visual hierarchy guides the eye: Hub → Connection → Spokes
- [ ] The "so what?" is in the slide title (assertion), not in the diagram text

### 2.4 Eliminate Extraneous Elements

Per Reynolds' Signal-to-Noise principle and Tufte's data-ink ratio:
- [ ] Remove decorative gradients/effects that don't serve comprehension
- [ ] Minimize logo repetition (once is enough if not in header bar)
- [ ] Reduce grid lines in any data tables to lightest possible
- [ ] Ensure every chip/badge/icon conveys distinct meaning

---

## Priority 3: Progress & Status Framing (Medium Impact)

### 3.1 Reframe Completion Metrics

If the presentation includes project progress/timeline slides:

**Replace abstract percentages with milestone language:**
```css
/* Instead of a progress bar at 12.5% */
/* Use a milestone checklist with Phase 1 checked */
```

**Recommended markup pattern:**
```html
<!-- Phase completion card -->
<div class="md-card">
  <h3>Implementation Progress</h3>
  <div class="phase complete">✅ Phase 1: Foundation — COMPLETE</div>
  <div class="phase active">🔵 Phase 2: Migration — IN PROGRESS</div>
  <div class="phase future">Phase 3-8: On track for Q4 delivery</div>
  <p class="insight">Foundation phase (highest complexity) delivered on schedule.</p>
</div>
```

### 3.2 Use Velocity Language

When discussing timeline/progress, use phrases like:
- "On track" / "Ahead of schedule"
- "Foundation complete — execution phases ahead"
- "Highest-risk decisions made — remaining work is incremental"
- "Phase 1 delivered in X weeks — Phase 2 targeting Y weeks"

### 3.3 Visual Progress Indicators

- **Use checkmarks** (✅) for completed phases — more impactful than filled progress bars
- **RAG status** (Red/Amber/Green) for at-a-glance health — executives know this language
- **Reduce visual weight of future phases** — grey them out, don't give them equal prominence
- **Show declining risk curve** if applicable — most risk is in early architecture decisions

---

## Priority 4: Technical-to-Executive Translation (Medium Impact)

### 4.1 Audit All Technical Language

Review every slide for jargon and replace:

| In the HTML | Should Say |
|-------------|-----------|
| "User provisioning" | "Automatic employee setup" |
| "RBAC" | "Role-based security" or just "automatic access control" |
| "Tenant architecture" | "Digital headquarters" |
| "SharePoint Hub" | "Central command site" |
| "License optimization" | "Eliminating wasted software spend" |
| "SSO" | "One login for everything" |

### 4.2 Lead With Business Value, Not Technology

Each technical slide should answer: **"So what? Why should an executive care?"**

```
WEAK:  "Microsoft 365 Multi-Tenant Architecture"
       → Describes technology

STRONG: "One Digital Headquarters: 5 Brands, Zero Duplicate Costs"
        → Describes business outcome
```

### 4.3 Use the SCR Framework for Complex Slides

For any slide explaining technical architecture:
1. **Situation:** "Today, each brand operates its own IT setup"
2. **Complication:** "This costs $X/year in duplicate licenses and creates security gaps"
3. **Resolution:** "A unified platform eliminates duplication while giving each brand its own workspace"

---

## Priority 5: Design System Alignment (Lower Impact)

### 5.1 Leverage the Existing Material 3 System Well

The presentation already uses:
- ✅ Card-based layout (good for chunking information)
- ✅ Icon system (Material Symbols)
- ✅ Consistent typography hierarchy
- ✅ Dark/light slide variants
- ✅ Brand color system

### 5.2 Design Enhancements Based on Research

| Principle | Current State | Enhancement |
|-----------|--------------|-------------|
| **Contrast** | Good (dark/light variants) | Ensure the ONE key element per slide has the strongest visual weight |
| **White space** | Check density | May need more breathing room — especially on data-heavy slides |
| **Progressive disclosure** | Slide transitions exist | Consider build animations for complex diagrams (reveal components one by one) |
| **Color purpose** | Brand colors applied | Ensure color is used semantically (green = success/complete, gold = highlight, red = risk) |

### 5.3 Pre-Read Consideration

Nancy Duarte recommends "Slidedocs" for pre-reads. Consider:
- Adding a CSS `@media print` stylesheet that reformats slides as a readable document
- Or creating a separate document version with more text context
- Send 24-48 hours before the meeting

---

## Implementation Checklist

### Before the Presentation
- [ ] Recommendation visible within 60 seconds (Slide 2)
- [ ] Executive summary contains: situation, recommendation, 3 supporting points, ask
- [ ] 12 slides or fewer (excluding appendix)
- [ ] Slide titles tell the story when read in sequence
- [ ] 3 supporting points maximum per argument
- [ ] All technical jargon translated to business language
- [ ] Risks addressed with mitigation strategies
- [ ] Clear ask on final slide
- [ ] Progress framed with milestones, not percentages
- [ ] Appendix ready for detailed questions
- [ ] Pre-read sent 24-48 hours in advance
- [ ] First 30 seconds of spoken delivery memorized

### The 60-Second Slide Test (per Hazeldine)
For each slide, time yourself:
1. Can you explain the point in under 10 seconds?
2. Does the title alone convey 80% of the message?
3. Is the visual evidence immediately clear?
4. Is there a "so what?" that connects to the decision?

If any answer is "no" — simplify the slide.
