# Mobile Intranet Design Case Studies - Nielsen Norman Group

**Source**: Nielsen Norman Group - UX Research
**URL**: https://www.nngroup.com/articles/mobile-intranet/
**Author**: Jakob Nielsen
**Date**: August 18, 2013
**Source Tier**: Tier 1 (Highest - Peer-Reviewed UX Research)

## Key Findings

### Enterprise Mobile Adoption

Mobile intranets emerged in enterprise computing with adoption rates:
- 2010: First mobile intranets in Intranet Design Annual winners
- Early years: Only 20-30% of winning intranets had mobile component
- Current state: Sufficient adoption to establish design trends

### Research Methodology

- **Survey Size**: More than 200 mobile intranet projects
- **Case Studies**: In-depth analysis of 9 projects
- **Scope**: Mobile enterprise applications and content design trends

## Mobile Intranet Use Cases

### Mission-Critical Applications

1. **Inventory management**
2. **Customer records lookup**
3. **Presentations, room calendars, contact lists, electronic visit reports**
4. **Class schedules** (students and teachers)
5. **Scheduling and tracking medical activity**
6. **Support tickets and inventory lookup** (field engineers)
7. **Updating staff about policy changes, payments, etc.**

### Secondary Uses
- News updates
- Internal social networking among employees
- Note: Mobile social features require different design than desktop social features

## Multi-Device Support

### Platform Statistics
- **Average platforms optimized**: 2.2 different platforms
- **Primary platforms**: iOS and Android
- **Additional platforms**: Windows Mobile and others

### BYOD (Bring Your Own Device) Impact
- Employees access company content on personal devices
- Major reason mobile intranets can't be designed for single device
- End of monoculture enterprise computing

## Budget Realities

### Mobile Intranet Budgets by Company Size

| Company Size | Average Budget |
|--------------|---------------|
| Large (50,000+ employees) | $228,000 |
| Mid-size (1,000-10,000 employees) | $42,000 |

### Key Insight
- $42,000 is insufficient for serious development effort
- Low budgets drive partial-function mobile sites
- Only **27% of companies** offer full-featured mobile intranet (same features as desktop)
- Majority offer limited functionality or different functionality for field staff

## Primary Motivation: Field Staff Support

**79% of surveyed projects** cited supporting people in the field as the biggest motivation for mobile intranet.

### Case Study Examples

1. **ZON's mTec**
   - Supports field technicians making house calls
   - Type-ahead search functionality
   - Reduces data-entry burden for mobile users

2. **SEI Mobile Field Service Ticketing**
   - Supports field service engineers repairing equipment in data centers
   - Web-based application

3. **CommunicateHealth's Show Me**
   - Native app for first responders
   - Helps communicate with people who have communication challenges
   - Designed for emergency situations

4. **Applified's 12View**
   - Municipal inspection teams
   - Android tablets for sewer system checks
   - Reports on incidents and maintenance from above ground

### Runner-Up Goals
- **51%**: Keep pace with user expectations
- **49%**: Improve employee productivity

Note: These goals require bigger budgets and better mobile UX than most companies currently provide.

## Value of Reduced Functionality

**Quote**: *"People liked 'less.' Simplifying down to just a few options helped people not get confused by having a new interface, which would be scary for doctors."*

A reduced, targeted mobile feature set is not necessarily bad—it can improve usability and reduce confusion.

## 7 Design Strategies to Reduce Errors and Boost Productivity

### 1. Plan for Offline Viewing

**Challenge**: Connectivity outages in metropolitan areas and developing countries

**Solutions**:
- Design sites/apps that store data locally
- Save state when signals drop
- Remember what users are doing during outages

**Examples**:
- **Suma**: Accommodates users losing signals between library stacks
- **Show Me**: Assumes emergency workers lose signals during disasters

### 2. Optimize Load Times

**Requirements**:
- Pages must be both great and lightweight
- Minimize server calls
- Critical for users with decreasing bandwidth and increasing mobile charges

### 3. Minimize Data Input

**Problem**: "Typing on glass is no picnic" even for proficient users

**Solutions**:
- Let users select from lists instead of typing
- Search set list of options
- Provide auto-suggestions
- Use type-ahead functionality

**Example**: ZON's mTec search uses type-ahead instead of long lists

### 4. Design Workflows for Common Tasks

**Benefits**:
- Forces design team to analyze steps and task order
- Creates logical flows that reduce user burden

**Warning**: If offline/desktop workflow is broken, mobile design will be too
- Redesign the process first, then take it mobile

### 5. Make Smart Assumptions

**Advantage**: Constrained enterprise environment makes assumptions easier than open web

**Example**: Show Me app
- Targets first responders in specific emergency situations
- Drives users through one scenario at a time
- Remembers selected scenario for 24 hours (no repeated login)

### 6. Focus on Specific Design Decisions

**Critical Decisions**:
- Font size (bigger is better)
- How much text to display per screen
- Full headline vs. truncated labels
- When to use ellipsis
- How many icons/stories fit in a row

**Shortcuts for Text**:
- Use icons and color-coding

**Example**: ZON's 4Sales
- Colors indicate "on time" vs. "late"

**Example**: 12View inspection app
- Uses icons in mobile interface for codes spelled out in desktop view
- Workers don't want to read too much in field
- Note: Unlabeled icons work in enterprise (trained users) but cause problems for general public (zero training assumed)

### 7. Write for Mobile

**Content Requirements**:
- Mobile content must be short
- Mobile intranets have advantage: can teach conciseness to staff writers

**Example**: Splash encourages "bit-sized" content
- Revised company style guide for mobile communications

**Progressive Disclosure Strategy**:
- Hide content behind extra tap
- Only users who want details get them

**Examples**:
- **12View**: Shows only 10 nearby locations by default (minimize download time)
- **mTec**: Relies heavily on progressive disclosure
- **Show Me**: Most useful icons by default, quick list of 10 most recently used

**Key Principle**: Don't hide information that ALL users need behind extra step

## Implications for Franchise Portals

### Field Staff Alignment

Franchise owner/operators are essentially "field staff" with similar needs:
- On-the-go access to operational information
- Limited time for complex navigation
- Need for offline functionality in locations with poor connectivity
- Quick lookup tasks rather than deep research

### Design Priorities

1. **Offline Support**
   - Cache critical resources and forms
   - Save state during connectivity interruptions
   - Sync when connection restored

2. **Simplified Workflows**
   - Reduce feature set to essential operations
   - Streamline common franchise tasks
   - Progressive disclosure for detailed information

3. **Touch-Optimized Input**
   - Minimize typing requirements
   - Use selection lists and auto-suggestions
   - Smart defaults and assumptions

4. **Visual Efficiency**
   - Icons + color-coding for trained users
   - Larger fonts for mobile readability
   - Truncate appropriately with clear indicators

5. **Performance**
   - Lightweight pages
   - Minimized server calls
   - Fast load times for impatient users

### Content Strategy

- "Bit-sized" content approach
- Mobile-first writing guidelines
- Train franchise owners on mobile content consumption patterns

### Budget Considerations

Realistic budget planning needed—$42,000 is insufficient for comprehensive mobile experience. Consider:
- Phased rollout (essential features first)
- Progressive enhancement
- Hybrid approaches (web app with native components)
