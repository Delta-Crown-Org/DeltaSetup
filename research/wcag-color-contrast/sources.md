# WCAG 2.2 Color Contrast Research Sources

## Source Credibility Evaluation

### Tier 1 (Highest) - Official Documentation

#### 1. W3C WCAG 2.2 Understanding: Contrast (Minimum)
**URL:** https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html  
**Type:** Official W3C Technical Documentation  
**Date:** Updated 31 October 2025  
**Credibility:** ⭐⭐⭐⭐⭐ **Tier 1 - Highest**

**Content Summary:**
- Official explanation of Success Criterion 1.4.3: Contrast (Minimum) Level AA
- Detailed formula for contrast ratio calculation
- Definition of relative luminance
- Large text specifications (18pt or 14pt bold)
- Rationale for 4.5:1 and 3:1 thresholds
- Complete mathematical formulas for sRGB conversion

**Key Information Extracted:**
- Contrast ratio formula: `(L1 + 0.05) / (L2 + 0.05)`
- Relative luminance: `L = 0.2126 × R + 0.7152 × G + 0.0722 × B`
- RGB conversion with gamma correction
- Normal text: 4.5:1 minimum
- Large text: 3:1 minimum
- Values should NOT be rounded when comparing to thresholds

**Validation:** ✅ Cross-referenced with WCAG 2.2 specification

---

#### 2. W3C WCAG 2.2 Understanding: Non-text Contrast
**URL:** https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html  
**Type:** Official W3C Technical Documentation  
**Date:** Updated 23 February 2026  
**Credibility:** ⭐⭐⭐⭐⭐ **Tier 1 - Highest**

**Content Summary:**
- Official explanation of Success Criterion 1.4.11: Non-text Contrast Level AA
- Requirements for UI components and graphical objects
- 3:1 contrast requirement for visual information
- Focus indicator requirements
- Testing principles for user interface components

**Key Information Extracted:**
- UI components require 3:1 contrast against adjacent colors
- Focus indicators must have sufficient contrast
- Inactive components are exempt
- Graphical objects need 3:1 contrast if required for understanding
- Same relative luminance formula as text contrast

**Validation:** ✅ Cross-referenced with WCAG 2.2 specification

---

#### 3. W3C WCAG 2.2 Specification - Contrast Minimum
**URL:** https://www.w3.org/TR/WCAG22/#contrast-minimum  
**Type:** Official W3C Recommendation (Normative)  
**Date:** October 2023  
**Credibility:** ⭐⭐⭐⭐⭐ **Tier 1 - Highest**

**Content Summary:**
- Normative specification of Success Criterion 1.4.3
- Official requirements text
- Definitions of key terms (contrast ratio, relative luminance)
- References to related success criteria

**Key Information Extracted:**
- "The visual presentation of text and images of text has a contrast ratio of at least 4.5:1"
- "Large-scale text and images of large-scale text have a contrast ratio of at least 3:1"
- Logotypes are exempt
- Incidental text is exempt

**Validation:** ✅ This is the authoritative source

---

### Tier 2 (High) - Supporting Resources

#### 4. W3C WCAG 2.2 Specification - Non-text Contrast
**URL:** https://www.w3.org/TR/WCAG22/#non-text-contrast  
**Type:** Official W3C Recommendation (Normative)  
**Date:** October 2023  
**Credibility:** ⭐⭐⭐⭐⭐ **Tier 1 - Highest**

**Content Summary:**
- Success Criterion 1.4.11 requirements
- User interface component contrast requirements
- Graphical object contrast requirements

**Key Information Extracted:**
- "The visual presentation of the following have a contrast ratio of at least 3:1 against adjacent color(s)"
- Applies to: User Interface Components and Graphical Objects
- Essential exception for specific presentations

---

## Source Reliability Summary

| Source | Tier | Authority | Currency | Validation | Status |
|--------|------|-----------|----------|------------|--------|
| W3C Understanding Contrast (Minimum) | 1 | Official | Oct 2025 | Cross-checked | ✅ Used |
| W3C Understanding Non-text Contrast | 1 | Official | Feb 2026 | Cross-checked | ✅ Used |
| WCAG 2.2 Specification | 1 | Official | Oct 2023 | Primary source | ✅ Used |

**Total Tier 1 Sources:** 3  
**Total Sources Consulted:** 3  
**All sources verified and cross-referenced**

---

## Related WCAG 2.2 Success Criteria

### Primary Criteria (Directly Applicable)

| Criterion | Level | Description | Requirement |
|-----------|-------|-------------|-------------|
| 1.4.3 Contrast (Minimum) | AA | Text contrast | 4.5:1 (normal), 3:1 (large) |
| 1.4.11 Non-text Contrast | AA | UI components | 3:1 against adjacent |

### Related Criteria (Context)

| Criterion | Level | Description | Relation |
|-----------|-------|-------------|----------|
| 1.4.1 Use of Color | A | Color not sole indicator | Color must have other distinguishing features |
| 1.4.6 Contrast (Enhanced) | AAA | Enhanced contrast | 7:1 for normal text |
| 2.4.7 Focus Visible | AA | Focus indicators | Must meet non-text contrast |
| 2.4.13 Focus Appearance | AAA | Focus indicator appearance | Size and contrast requirements |

---

## References Cited in WCAG Documentation

The W3C documentation references these authoritative sources for the contrast formulas:

1. **IEC/4WD 61966-2-1** - sRGB color space specification
2. **ISO 9241-3** - Ergonomic requirements for visual displays
3. **ANSI/HFS 100-1988** - Human factors engineering standards
4. **Arditi & Faye (2004)** - Visual acuity and contrast sensitivity research
5. **Gittings & Fozard (1986)** - Age-related visual acuity changes

These sources validate the 4.5:1 and 3:1 thresholds based on empirical research with users with visual impairments.

---

## Verification Methodology

1. **Primary Source Verification**
   - Consulted official W3C WCAG 2.2 specification
   - Cross-referenced with Understanding documents
   - Verified formulas match sRGB standards

2. **Formula Validation**
   - Tested with known WCAG examples
   - Verified gamma correction calculations
   - Confirmed rounding behavior (no rounding at threshold)

3. **Threshold Confirmation**
   - 4.5:1 for normal text (backed by 20/40 vision research)
   - 3:1 for large text (based on ANSI standards)
   - 3:1 for UI components (equivalent to large text)

---

## Notes on Source Quality

All sources used are:
- ✅ **Authoritative:** Official W3C/WAI documentation
- ✅ **Current:** WCAG 2.2 is the latest recommendation
- ✅ **Primary:** Original specification documents
- ✅ **Unbiased:** Standards body with no commercial interest
- ✅ **Validated:** Cross-referenced multiple official sources

No Tier 3 or Tier 4 sources were needed for this research as the official documentation provides complete technical specifications.
