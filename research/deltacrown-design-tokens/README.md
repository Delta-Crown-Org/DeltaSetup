# Delta Crown Design Tokens & Brand Guidelines Research

**Research Date:** March 31, 2024  
**Source:** https://www.crownextensionstudio.com/ (primary)  
**Secondary Source:** https://franchise.deltacrown.com/  

---

## Executive Summary

Delta Crown Extensions is a premium hair extension salon franchise based in Colorado Springs, Colorado. The brand operates under the corporate umbrella of **Head to Toe Brands** and positions itself as a luxury, professional beauty service provider. The visual identity combines sophisticated elegance with approachable warmth, targeting affluent clients seeking high-quality hair extension services.

### Key Findings
- **Brand Style:** Luxury, professional, elegant, warm
- **Primary Palette:** Deep teal/green, gold/amber, cream/off-white
- **Typography:** Mix of elegant serif and clean sans-serif fonts
- **Design Philosophy:** "Crown" metaphor - empowering clients, royal treatment
- **Target Audience:** Women seeking premium hair extension services

---

## 1. Primary Brand Colors

### Main Palette

| Color Name | Hex Code | Usage | Visual Description |
|------------|----------|-------|-------------------|
| **Deep Teal** | `#006B5E` | Primary brand color, CTAs, headers, footer | Rich, sophisticated teal-green |
| **Royal Gold** | `#D4A84B` | Accents, buttons, highlights, awards | Warm, luxurious golden amber |
| **Cream/Off-White** | `#F5F3EF` | Backgrounds, sections, cards | Soft, warm neutral |
| **Pure White** | `#FFFFFF` | Primary backgrounds, text on dark | Clean, crisp white |
| **Dark Navy** | `#1A2A3A` | Text, headers, footer text | Deep, professional navy |

### Secondary/Accent Colors

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| **Soft Sage** | `#7A9B8A` | Subtle accents, icons |
| **Warm Beige** | `#E8E4DC` | Section backgrounds |
| **Gold Light** | `#E8C989` | Hover states, highlights |
| **Teal Light** | `#4A9B8E` | Secondary buttons, links |

### Color Psychology
- **Deep Teal (#006B5E):** Represents trust, sophistication, and the "Delta" (water) aspect of the brand name. Suggests calm professionalism.
- **Royal Gold (#D4A84B):** Evokes luxury, premium quality, and the "Crown" aspect. Reinforces the royal treatment positioning.
- **Cream/Off-White:** Creates warmth and approachability while maintaining elegance.

---

## 2. Typography System

### Font Families

Based on visual analysis and CSS inspection:

#### Primary Heading Font
- **Font:** Likely **Playfair Display** or similar elegant serif
- **Characteristics:** High contrast, sophisticated, editorial feel
- **Usage:** H1 headings, hero text, brand statements
- **Style:** Regular to medium weight, elegant letterforms

#### Secondary/Body Font
- **Font:** **Tenor Sans** (confirmed via Google Fonts link)
- **Source:** Google Fonts - `https://fonts.googleapis.com/css2?family=Tenor+Sans:ital,wght@0,400`
- **Characteristics:** Clean, modern, highly legible
- **Usage:** Body text, navigation, buttons, descriptions

#### Accent/Script Font
- **Font:** Appears to be a decorative script or italic serif
- **Usage:** Quotes, special callouts (e.g., "'Specialty Salon of the Year'")
- **Style:** Cursive/elegant, adds personality and warmth

### Typography Hierarchy

| Element | Font Family | Weight | Size (Estimated) | Color |
|---------|-------------|--------|------------------|-------|
| **H1 - Hero** | Elegant Serif | 400-500 | 48-64px | White (on image) or Dark |
| **H2 - Section** | Elegant Serif | 400 | 36-42px | Deep Teal or Dark |
| **H3 - Subsection** | Elegant Serif | 400 | 28-32px | Deep Teal |
| **Body Text** | Tenor Sans | 400 | 16-18px | Dark Navy |
| **Buttons** | Tenor Sans | 400 | 14-16px | White on Gold/Teal |
| **Navigation** | Tenor Sans | 400 | 14-16px | Dark Navy |
| **Small/Caption** | Tenor Sans | 400 | 12-14px | Muted gray |

### Typography Patterns
- **Uppercase Text:** Used for navigation items, button labels (e.g., "RESERVE YOUR CONSULTATION")
- **Letter Spacing:** Generous tracking on navigation and buttons
- **Line Height:** Comfortable, readable spacing (approximately 1.5-1.6)

---

## 3. Design Style & Philosophy

### Overall Aesthetic
**"Modern Luxury with Warmth"**

The design balances:
- **Sophistication** (serif fonts, gold accents, elegant imagery)
- **Approachability** (warm colors, genuine photography, clear CTAs)
- **Professionalism** (clean layouts, consistent spacing, quality indicators)

### Design Characteristics

#### Visual Language
- **Royal/Crown Motif:** Logo features a crown icon, reinforcing the "Crown" in the brand name
- **Nature/Organic Elements:** Teal color suggests water/delta connection
- **Clean Lines:** Minimal ornamentation, focus on content
- **Generous Whitespace:** Creates breathing room and luxury feel

#### Imagery Style
- **Photography:** High-quality, professional lifestyle photography
- **Subjects:** Women with beautiful hair transformations
- **Tone:** Warm, confident, aspirational but accessible
- **Treatment:** Natural lighting, authentic moments

#### Iconography
- **Star Ratings:** 5-star rating system for testimonials (★★★★★)
- **Social Icons:** Instagram and Facebook in footer
- **Arrow Indicators:** For CTAs and navigation hints

### Brand Positioning Statement (Inferred)
*"Premium hair extension services that make every client feel like royalty, combining luxury experience with professional expertise and genuine care."*

---

## 4. Spacing & Layout Patterns

### Layout System

#### Container Widths
- **Maximum Width:** Approximately 1200-1400px for main content
- **Full-Width Sections:** Hero, testimonials, footer
- **Contained Sections:** Content areas with consistent padding

#### Spacing Scale (Estimated)

| Token | Value | Usage |
|-------|-------|-------|
| **Space XS** | 8px | Tight spacing, icon gaps |
| **Space S** | 16px | Button padding, small gaps |
| **Space M** | 24px | Card padding, element spacing |
| **Space L** | 32-48px | Section internal padding |
| **Space XL** | 64-80px | Between major sections |
| **Space XXL** | 100-120px | Major section separations |

### Section Patterns

#### Hero Section
- Full-width background image
- Centered content overlay
- Large H1 heading
- Prominent CTA button (gold)
- Semi-transparent overlays on images

#### Content Sections
- Alternating backgrounds (white/cream)
- Centered or two-column layouts
- Generous vertical padding (80-100px)

#### Card Patterns
- Testimonial cards with white backgrounds
- Shadow effects: subtle, soft shadows
- Border radius: minimal or none (clean edges)

#### Grid Systems
- **3-Column:** For process steps (01, 02, 03)
- **2-Column:** For service descriptions
- **1-Column:** For testimonials flow

### Responsive Behavior
- Mobile-first approach
- Stacked layouts on smaller screens
- Hamburger navigation on mobile

---

## 5. Component Library

### Buttons

#### Primary Button (Gold)
```
Background: #D4A84B
Text: #FFFFFF
Padding: 16px 32px
Border-radius: 0 (square edges)
Font: Tenor Sans, uppercase, 14-16px
Hover: Slightly darker gold
```

#### Secondary Button (Outline)
```
Background: transparent
Border: 1-2px solid #006B5E
Text: #006B5E
Padding: 12px 24px
```

#### Ghost Button
```
Background: transparent
Text: #006B5E or #D4A84B
Padding: 12px 24px
```

### Cards

#### Testimonial Card
```
Background: #FFFFFF
Padding: 24-32px
Shadow: 0 2px 8px rgba(0,0,0,0.1)
Border-radius: 0-4px
```

### Forms

#### Input Fields
```
Background: #FFFFFF
Border: 1px solid #E0E0E0
Border-radius: 0-2px
Padding: 12-16px
Font: Tenor Sans
```

---

## 6. Brand Voice & Tone

### Voice Characteristics

#### 1. **Empowering & Uplifting**
- Language that builds confidence
- Focus on transformation and self-improvement
- Example: "Premium Hair Extension Salon" - positioning as premium service

#### 2. **Professional yet Warm**
- Expert terminology ("Crown Weft Transformation", "Fusion Hair Extensions")
- Accessible explanations
- Balances technical expertise with approachability

#### 3. **Community-Focused**
- Strong emphasis on testimonials and real client stories
- Named testimonials with photos
- "Meet our guests" section humanizes the brand

#### 4. **Awards & Credibility**
- Prominent display of awards ("Specialty Salon of the Year 2024")
- Badge/award imagery
- Media mentions and recognition

#### 5. **Socially Conscious**
- "Hair to Stay" initiative for cancer patients
- "16 WOMEN save their hair through chemotherapy treatments"
- Community giving emphasis

### Key Messaging Themes

| Theme | Examples |
|-------|----------|
| **Transformation** | "Before & After", transformation stories |
| **Quality/Premium** | "Premium Hair Extension Salon", awards |
| **Experience** | "The New Guest Experience", numbered steps |
| **Trust** | Testimonials, reviews, "4.9/5 Google rating" |
| **Expertise** | Specialties explained, professional terminology |

### Copy Patterns

#### Headlines
- Short, impactful statements
- Mix of serif elegance and clear messaging
- Often use possessive: "Your Crown", "Your Consultation"

#### Body Copy
- Concise paragraphs
- Benefit-focused language
- Clear calls-to-action

#### CTAs
- Action-oriented: "Reserve Your Consultation"
- Urgency without pressure: "Explore", "Discover"
- Consistent uppercase styling

---

## 7. Design Tokens Summary

### Color Tokens
```css
--color-primary: #006B5E;        /* Deep Teal */
--color-secondary: #D4A84B;      /* Royal Gold */
--color-background: #F5F3EF;      /* Cream */
--color-background-alt: #FFFFFF;  /* White */
--color-text-primary: #1A2A3A;    /* Dark Navy */
--color-text-secondary: #7A9B8A;  /* Soft Sage */
--color-accent: #E8C989;          /* Light Gold */
```

### Typography Tokens
```css
--font-heading: 'Playfair Display', serif;  /* or similar elegant serif */
--font-body: 'Tenor Sans', sans-serif;
--font-size-h1: 48-64px;
--font-size-h2: 36-42px;
--font-size-h3: 28-32px;
--font-size-body: 16-18px;
--font-size-small: 14px;
--line-height-body: 1.6;
```

### Spacing Tokens
```css
--space-xs: 8px;
--space-sm: 16px;
--space-md: 24px;
--space-lg: 32-48px;
--space-xl: 64-80px;
--space-xxl: 100-120px;
```

### Shadow Tokens
```css
--shadow-card: 0 2px 8px rgba(0,0,0,0.1);
--shadow-elevated: 0 4px 16px rgba(0,0,0,0.15);
```

---

## 8. Recommendations for Implementation

### High Priority
1. **Use the Deep Teal (#006B5E) as primary** for headers, footers, and primary CTAs
2. **Royal Gold (#D4A84B) for accent buttons** and premium highlights
3. **Tenor Sans for all UI text** - it's confirmed and freely available
4. **Maintain generous whitespace** - it's key to the luxury feel

### Medium Priority
1. **Source an elegant serif** similar to Playfair Display for headings
2. **Implement the 3-step process pattern** - it's central to the brand experience
3. **Use testimonial cards** with white backgrounds and subtle shadows
4. **Maintain uppercase for CTAs** and navigation

### Brand Voice Guidelines
1. **Lead with empowerment** - "your crown", "your transformation"
2. **Balance expertise with warmth** - technical terms with accessible explanations
3. **Feature real testimonials** prominently
4. **Highlight social impact** - the "Hair to Stay" initiative

---

## 9. Corporate Structure Notes

Delta Crown Extensions operates under:
- **Parent Company:** Head to Toe Brands
- **Partnership:** The Riverside Company (private equity)
- **Franchise Model:** Available nationwide
- **Tagline:** "Backed by Head to Toe Brands"

This corporate backing informs the professional, scalable design approach while maintaining local salon warmth.

---

**Research Completed:** March 31, 2024  
**Next Steps:** Verify exact hex codes with brand team, obtain brand guidelines PDF if available
