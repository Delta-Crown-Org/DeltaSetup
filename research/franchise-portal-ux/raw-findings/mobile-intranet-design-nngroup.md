# Mobile Intranet Design Case Studies - NN/G
**Source**: https://www.nngroup.com/articles/mobile-intranet/  
**Author**: Jakob Nielsen  
**Date**: August 18, 2013  
**Source Tier**: Tier 1 (Nielsen Norman Group - UX Research Authority)

## Executive Summary
Study surveyed 200+ mobile intranet projects and conducted in-depth case studies with 9 organizations. Critical findings for franchise/mobile workforce scenarios.

## Mobile Intranet Applications Found

### Mission-Critical Apps
- Inventory management
- Customer records lookup
- Presentations, room calendars, contact lists, electronic visit reports
- Class schedules (students/teachers)
- Scheduling and tracking medical activity
- Support tickets and inventory lookup (field engineers)
- Policy changes, payments, updates to staff

### Social/Collaboration Features
- News updates (frequently used on mobile)
- Internal social networking
- Employee connections
- Note: Mobile social features require new design (Facebook learned this the hard way)

## Mobile Adoption Statistics

### Historical Context
- 2010: First mobile intranets among Design Annual winners
- 2010-2013: Only 20-30% of winning intranets had mobile component
- Growing but not overheated (positive - quality over hype)

### Multi-Device Support
- **Average**: 2.2 platforms optimized
- Primary platforms: iOS and Android
- Additional: Windows Mobile and others
- **BYOD Trend**: Major driver for multi-platform support

## Budget Reality Check

### Average Mobile Intranet Budgets by Organization Size
| Organization Size | Average Budget |
|-------------------|---------------|
| 50,000+ employees | $228,000 |
| 1,000-10,000 employees | $42,000 |

**Critical Finding**: $42,000 insufficient for serious development - leads to partial-function mobile sites.

### Feature Coverage
- **27%** of companies offered full-featured mobile intranet (same as desktop)
- **73%** offered limited or different functionality
- Most focused on field staff needs who rarely use desktop

## Primary Mobile Intranet Motivations

### #1: Support Field Staff (79%)
**Examples**:
- ZON's mTec: House-call field technicians
- SEI Mobile Field Service: Engineers repairing data center equipment
- CommunicateHealth's Show Me: First responders in emergencies
- Applified's 12View: Municipal sewer inspection teams

### #2: Keep Pace with User Expectations (51%)

### #3: Improve Employee Productivity (49%)

**Insight**: To meet productivity/expectation goals, bigger budgets and better UX needed.

## Key Insight on Feature Reduction
> "People liked 'less.' Simplifying down to just a few options helped people not get confused by having a new interface, which would be scary for doctors."

**Franchise Application**: Reduced feature sets can actually improve adoption - focus on core tasks, not feature parity.

## 7 Design Strategies for Mobile Intranets

### 1. Plan for Offline Viewing
**Challenge**: Cellular connectivity tenuous even in metropolitan areas; poor service in developing countries
**Solutions**:
- Store data locally
- Save state when signals drop
- Remember user context during outages

**Examples**:
- Suma: Accommodates signal loss between library stacks
- Show Me: Assumes emergency workers lose signals during disasters

### 2. Optimize Load Times
**Mobile Reality**: Decreasing bandwidth, increasing charges
**Strategy**: Minimize server calls
**Critical for**: Field workers in areas with poor connectivity

### 3. Minimize Data Input
**Reality**: "Typing on glass is no picnic" even for proficient users
**Strategies**:
- Selection lists over typing
- Auto-suggestions
- Type-ahead functionality
- Leave data-intensive work for desktop

**Example**: ZON's mTec uses type-ahead vs. long lists

### 4. Design Workflows for Common Tasks
**Critical**: Analyze steps and task order to complete work
**Warning**: Mobile design based on broken offline process will also be broken
**Best Practice**: Redesign process first, then mobilize

### 5. Make Smart Assumptions
**Advantage**: Enterprise environment more constrained than open web
**Strategies**:
- Drive users through one scenario at a time
- Remember selections (e.g., 24-hour memory for scenario)
- Pre-populate based on context

**Example**: Show Me remembers selected emergency scenario for 24 hours

### 6. Focus on Typography and Display
**Key Decisions**:
- Font size (bigger is better on mobile)
- Truncation strategy (headlines vs. full names)
- Ellipsis usage
- Icon density (how many per row)

**Visual Shortcuts**:
- Icons to represent codes (spelled out on desktop)
- Color coding for status (on-time vs. late)
- **Note**: Enterprise context different from consumer - can assume training on icons

**Examples**:
- ZON's 4Sales: Colors indicate on-time vs. late
- 12View (sewer inspection): Icons replace codes, minimal reading desired

### 7. Write for Mobile
**Principle**: Content must be short
**Enterprise Advantage**: Can teach conciseness to staff writers
**Strategies**:
- "Bite-sized" content
- Revise style guides for mobile
- Progressive disclosure (hide behind extra tap)

**Progressive Disclosure Examples**:
- 12View: Shows 10 nearby locations by default (more on demand)
- mTec: Heavy reliance on progressive disclosure
- Show Me: Most useful icons default, quick list of 10 recently used
**Critical**: Don't hide information ALL users need behind extra steps

## Special Considerations for Field Workers

### Environmental Factors
- Variable connectivity (urban vs. rural)
- Time-sensitive situations (emergencies, appointments)
- Limited attention (while working with customers/equipment)
- One-handed operation needs

### Task Characteristics
- Interrupt-driven workflow
- Need quick status checks
- Data lookup more than data entry
- Coordination with dispatch/office

## Franchise/Field Worker Application

### Mobile Use Cases for Franchisees
1. **Operational Updates**: Check inventory, orders, delivery status
2. **Training Access**: Bite-sized training modules, just-in-time learning
3. **Communication**: Quick updates from franchisor, peer connection
4. **Support**: Access troubleshooting guides, submit tickets
5. **Reporting**: Time tracking, incident reports, compliance checklists
6. **Marketing**: Access promotional materials, social media content

### Design Priorities
1. **Speed**: Fast load, minimal taps
2. **Offline Capability**: Work without constant connectivity
3. **Task-Focused**: Clear workflows for common tasks
4. **Progressive Disclosure**: Essential info first, details on demand
5. **Minimal Input**: Selection over typing, defaults, smart assumptions
6. **Visual Status**: Color coding, icons for quick scanning

### Content Strategy
- Short, scannable content
- Bite-sized training modules
- Visual over text where possible
- Consistent iconography (train once, use everywhere)

## Success Metrics to Track
- Task completion rates on mobile vs. desktop
- Time-to-complete for key workflows
- Offline usage patterns
- Error rates (indicates workflow clarity)
- User satisfaction (especially field/franchisee users)

## Critical Success Factors
1. **Budget Appropriately**: $42K insufficient for full-featured solution
2. **Focus Field Staff**: Mobile intranet is a tool, not a fad
3. **Process Before Technology**: Fix broken processes before mobilizing
4. **Test in Real Conditions**: Poor connectivity, one-handed use, interruptions
5. **Train on Conventions**: Leverage enterprise context for icon/abbreviation usage
