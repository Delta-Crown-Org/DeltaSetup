#!/usr/bin/env python3
"""
WCAG 2.2 Color Contrast Ratio Calculator
Calculates exact contrast ratios according to WCAG 2.2 specifications

Formula from W3C:
- Contrast Ratio = (L1 + 0.05) / (L2 + 0.05)
- Where L = relative luminance
- L = 0.2126 * R + 0.7152 * G + 0.0722 * B
- For each color channel:
  - If RsRGB <= 0.04045: R = RsRGB/12.92
  - Else: R = ((RsRGB + 0.055) / 1.055) ^ 2.4
  - RsRGB = R8bit / 255

Reference: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
"""

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple (0-255)"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def calculate_relative_luminance(rgb):
    """
    Calculate relative luminance according to WCAG 2.2
    L = 0.2126 * R + 0.7152 * G + 0.0722 * B
    """
    def normalize_component(c):
        # Convert 8-bit to sRGB (0-1)
        srgb = c / 255.0
        # Apply gamma correction
        if srgb <= 0.04045:
            return srgb / 12.92
        else:
            return pow((srgb + 0.055) / 1.055, 2.4)
    
    r, g, b = rgb
    R = normalize_component(r)
    G = normalize_component(g)
    B = normalize_component(b)
    
    luminance = 0.2126 * R + 0.7152 * G + 0.0722 * B
    return luminance

def calculate_contrast_ratio(color1_hex, color2_hex):
    """
    Calculate WCAG 2.2 contrast ratio between two colors
    Returns: (ratio, luminance1, luminance2)
    """
    rgb1 = hex_to_rgb(color1_hex)
    rgb2 = hex_to_rgb(color2_hex)
    
    l1 = calculate_relative_luminance(rgb1)
    l2 = calculate_relative_luminance(rgb2)
    
    # Ensure L1 is the lighter color
    lighter = max(l1, l2)
    darker = min(l1, l2)
    
    # Contrast ratio formula: (L1 + 0.05) / (L2 + 0.05)
    ratio = (lighter + 0.05) / (darker + 0.05)
    
    return ratio, l1, l2

def evaluate_wcag_compliance(ratio):
    """
    Evaluate WCAG 2.2 AA compliance levels
    """
    results = {
        'normal_text_aaa': ratio >= 7.0,
        'normal_text_aa': ratio >= 4.5,
        'large_text_aa': ratio >= 3.0,
        'ui_components_aa': ratio >= 3.0,
        'enhanced_aaa': ratio >= 7.0
    }
    return results

# Define brand colors
COLORS = {
    'Deep Teal': '#006B5E',
    'Royal Gold': '#D4A84B',
    'Dark Navy': '#1A2A3A',
    'White': '#FFFFFF',
    'Cream': '#F5F3EF'
}

# Color combinations to test
COMBINATIONS = [
    ('Deep Teal (#006B5E)', 'White (#FFFFFF)', '#006B5E', '#FFFFFF'),
    ('White (#FFFFFF)', 'Deep Teal (#006B5E)', '#FFFFFF', '#006B5E'),
    ('Royal Gold (#D4A84B)', 'White (#FFFFFF)', '#D4A84B', '#FFFFFF'),
    ('Royal Gold (#D4A84B)', 'Deep Teal (#006B5E)', '#D4A84B', '#006B5E'),
    ('Dark Navy (#1A2A3A)', 'Cream (#F5F3EF)', '#1A2A3A', '#F5F3EF'),
    ('Dark Navy (#1A2A3A)', 'White (#FFFFFF)', '#1A2A3A', '#FFFFFF'),
]

# WCAG 2.2 Requirements
print("=" * 80)
print("WCAG 2.2 COLOR CONTRAST ANALYSIS")
print("Delta Crown Brand Colors")
print("=" * 80)
print()

print("COLOR PALETTE:")
for name, hex_code in COLORS.items():
    print(f"  {name}: {hex_code}")
print()

print("WCAG 2.2 AA REQUIREMENTS:")
print("  • Normal text (Level AA): 4.5:1 minimum")
print("  • Large text (Level AA): 3:1 minimum (18pt+ or 14pt bold)")
print("  • UI components (Level AA): 3:1 minimum (1.4.11 Non-text Contrast)")
print("  • Enhanced contrast (AAA): 7:1 minimum")
print()

print("=" * 80)
print("CONTRAST RATIO CALCULATIONS")
print("=" * 80)
print()

results = []

for i, (fg_name, bg_name, fg_hex, bg_hex) in enumerate(COMBINATIONS, 1):
    ratio, l1, l2 = calculate_contrast_ratio(fg_hex, bg_hex)
    compliance = evaluate_wcag_compliance(ratio)
    
    results.append({
        'num': i,
        'fg': fg_name,
        'bg': bg_name,
        'ratio': ratio,
        'l1': l1,
        'l2': l2,
        'compliance': compliance
    })
    
    print(f"{i}. {fg_name} on {bg_name}")
    print(f"   Exact Contrast Ratio: {ratio:.4f}:1")
    print(f"   Relative Luminance - Foreground: {l1:.6f}, Background: {l2:.6f}")
    print()
    
    # WCAG AA Compliance
    print("   WCAG 2.2 AA COMPLIANCE:")
    
    status_normal = "✅ PASS" if compliance['normal_text_aa'] else "❌ FAIL"
    print(f"   • Normal Text (4.5:1):     {status_normal} ({ratio:.2f}:1)")
    
    status_large = "✅ PASS" if compliance['large_text_aa'] else "❌ FAIL"
    print(f"   • Large Text (3:1):         {status_large} ({ratio:.2f}:1)")
    
    status_ui = "✅ PASS" if compliance['ui_components_aa'] else "❌ FAIL"
    print(f"   • UI Components (3:1):      {status_ui} ({ratio:.2f}:1)")
    
    status_aaa = "✅ PASS" if compliance['normal_text_aaa'] else "❌ FAIL"
    print(f"   • Enhanced AAA (7:1):       {status_aaa} ({ratio:.2f}:1)")
    
    print()

# Summary table
print("=" * 80)
print("SUMMARY TABLE")
print("=" * 80)
print()

print(f"{'#':<3} {'Combination':<45} {'Ratio':<10} {'Normal':<8} {'Large':<8} {'UI':<8}")
print("-" * 80)

for r in results:
    combo = f"{r['fg'].split('(')[0]} on {r['bg'].split('(')[0]}"
    normal = "✅" if r['compliance']['normal_text_aa'] else "❌"
    large = "✅" if r['compliance']['large_text_aa'] else "❌"
    ui = "✅" if r['compliance']['ui_components_aa'] else "❌"
    print(f"{r['num']:<3} {combo:<45} {r['ratio']:.2f}:1   {normal:<8} {large:<8} {ui:<8}")

print()
print("=" * 80)
print("RECOMMENDATIONS")
print("=" * 80)
print()

pass_normal = sum(1 for r in results if r['compliance']['normal_text_aa'])
pass_large = sum(1 for r in results if r['compliance']['large_text_aa'])
pass_ui = sum(1 for r in results if r['compliance']['ui_components_aa'])

print(f"Passing WCAG 2.2 AA Normal Text: {pass_normal}/6 combinations")
print(f"Passing WCAG 2.2 AA Large Text:  {pass_large}/6 combinations")
print(f"Passing WCAG 2.2 AA UI Components: {pass_ui}/6 combinations")
print()

# Identify issues
failing_normal = [r for r in results if not r['compliance']['normal_text_aa']]
if failing_normal:
    print("COMBINATIONS FAILING NORMAL TEXT (4.5:1):")
    for r in failing_normal:
        print(f"  • {r['num']}. {r['fg']} on {r['bg']} ({r['ratio']:.2f}:1)")
    print()

failing_large = [r for r in results if not r['compliance']['large_text_aa']]
if failing_large:
    print("COMBINATIONS FAILING LARGE TEXT/UI (3:1):")
    for r in failing_large:
        print(f"  • {r['num']}. {r['fg']} on {r['bg']} ({r['ratio']:.2f}:1)")
    print()

print("=" * 80)
