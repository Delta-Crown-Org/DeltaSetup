# Raw Findings: Microsoft Learn - Information Barriers

**Source**: https://learn.microsoft.com/en-us/purview/information-barriers  
**Date Extracted**: April 2025

---

## What are Information Barriers?

Information Barriers (IB) are policies that restrict communication and collaboration between specific groups of users in Microsoft 365.

---

## Use Cases and Examples

### 1. Financial Services
- A SharePoint site for Day Trader group can't be shared or accessed by anyone outside of the Day Trader group

### 2. Legal Sector
- A lawyer's data obtained from one client can't be accessed by a lawyer at the same firm who represents a different client

### 3. Government
- Government information access and control are limited across departments and groups

### 4. Customer Engagement
- A group of people in a company can only chat with a client or specific customer via guest access during customer engagement

---

## Critical Limitation: Two-Way Only

### Important Constraint
> Information Barriers **only supports two-way communication and collaboration restrictions**.

### What This Means
- Scenario A: Marketing can communicate with Day Traders, but Day Traders can't communicate with Marketing
- **This is NOT supported** - Information Barriers cannot create one-way restrictions

- Supported: Both groups are restricted from each other (two-way)
- Not Supported: One group restricted, other group allowed (one-way)

---

## Microsoft Teams Integration

In Microsoft Teams, IB policies determine and prevent:
- Searching for a user
- Adding a member to a team
- Starting a chat session with someone
- Starting a call with someone
- Sharing a screen
- And more unauthorized communications

---

## SharePoint and OneDrive Integration

Information Barriers also apply to:
- SharePoint site access
- OneDrive file sharing
- File and folder permissions

Users subject to IB policies cannot:
- Share files with restricted users
- Access sites they're restricted from

---

## Other Supported Services

- Microsoft Teams
- SharePoint Online
- OneDrive
- Microsoft Planner
- Exchange Online

---

## Licensing Requirements

### Critical Note for M365 Business Premium
**Information Barriers are NOT included in Microsoft 365 Business Premium**

### Required Licensing
- Microsoft 365 E5
- Microsoft 365 E5 Compliance
- Microsoft 365 E5 Information Protection and Governance
- Office 365 E5
- Or corresponding add-on licenses

### Business Premium Alternative
For M365 Business Premium environments, alternative approaches must be used:
- Permission-based isolation
- Sensitivity labels
- DLP policies
- Separate site collections

---

## Multi-Brand Franchise Implications

### If Information Barriers Were Available (E5 License)
Pros:
- Strong separation between brands
- Prevents accidental cross-brand collaboration
- Regulatory compliance support

Cons:
- Two-way restriction only - can't have asymmetric access
- Complex policy management
- Requires significant administrative overhead

### For M365 Business Premium (Without IB)
Must implement alternative isolation strategies:
1. **Permission-based isolation** - Separate site collections with distinct permissions
2. **Hub site organization** - Separate hubs per brand with no cross-association
3. **Sensitivity labels** - Classify content by brand/restriction level
4. **DLP policies** - Prevent unauthorized sharing
5. **Site design governance** - Control site creation and templates

---

## Key Takeaways

1. **Not available in Business Premium** - Requires E5 or compliance add-ons
2. **Two-way restrictions only** - Cannot create one-way communication blocks
3. **Comprehensive coverage** - Applies to Teams, SharePoint, OneDrive, Planner, Exchange
4. **Strict isolation** - Once implemented, restricted groups cannot communicate or share at all
5. **Alternative required** - Business Premium customers need permission-based isolation approach

---

*Extracted from Microsoft Learn - Information Barriers*
*URL: https://learn.microsoft.com/en-us/purview/information-barriers*
