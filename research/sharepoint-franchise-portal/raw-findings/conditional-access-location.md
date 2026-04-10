# Conditional Access: Location and Device Policies

## Source: Microsoft Learn - Conditional Access Location Conditions
**URL**: https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network
**Credibility**: Tier 1 - Official Microsoft Documentation
**Date Retrieved**: March 2025

## Location Condition Configuration

### Available Options

| Option | Description |
|--------|-------------|
| **Any network or location** | All IP addresses including internet |
| **All trusted networks and locations** | Locations marked as trusted + MFA trusted IPs |
| **All Compliant Network locations** | Global Secure Access compliant networks |
| **Selected networks and locations** | Specific named locations |

### Named Locations

#### IPv4/IPv6 Address Ranges
- Define corporate office IP ranges
- CIDR notation support
- Multiple ranges per location
- Country/region-based locations

#### Trusted Locations
- Mark specific locations as trusted
- Used for conditional logic
- Can exclude from MFA requirements
- Cannot be used to block access

### Common Location Policies

#### Policy: Block Access from Non-Trusted Locations
```
IF: Location = Any location EXCEPT trusted locations
THEN: Block access OR Require MFA
```

#### Policy: Require Compliant Device Outside Office
```
IF: Location = Any location EXCEPT trusted locations
THEN: Require device compliance
```

## Device Compliance

### Compliance Policies (Intune)
- Device encryption required
- OS version requirements
- Password/PIN complexity
- Jailbreak/root detection
- Anti-malware status

### Conditional Access Integration

| Grant Control | Behavior |
|--------------|----------|
| **Require device compliance** | Device must meet Intune compliance policies |
| **Require Hybrid Azure AD joined** | Domain-joined and registered |
| **Require approved app** | Specific client apps only |

## Franchise Portal Use Cases

### Use Case 1: Corporate Office Access
- Define franchise corporate office IP ranges
- Mark as trusted location
- Reduce friction for on-site users
- Still enforce MFA for privileged roles

### Use Case 2: Remote Franchisee Access
- Franchisees access from various locations
- Require device compliance
- May require MFA based on risk
- Block high-risk locations

### Use Case 3: Kiosk/Shared Device Access
- Shared devices at franchise locations
- Require compliant device (managed)
- Session timeout policies
- No persistent credentials

### Use Case 4: Mobile Franchise Management
- Mobile device management required
- App protection policies
- Conditional launch (jailbreak detection)
- Offline access controls

## Implementation Recommendations

### Phase 1: Baseline
1. Require MFA for all users
2. Block legacy authentication
3. Require compliant device for sensitive apps

### Phase 2: Franchise-Specific
1. Define franchise office IP ranges
2. Configure location-based policies
3. Device compliance for franchise devices

### Phase 3: Advanced
1. Risk-based policies
2. Real-time session controls
3. Custom controls integration

## Important Considerations

### IPv6 Support
- Many mobile devices use IPv6
- Must include IPv6 ranges in named locations
- Can be complex for dynamic/mobile users

### VPN Considerations
- VPN egress IPs may be different
- Plan for VPN scenarios
- Consider conditional access for VPN

### Shared Networks
- Franchisees may share networks
- IP-based location less reliable
- Combine with device compliance
