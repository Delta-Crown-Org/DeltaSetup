# Teams Configuration Specification — Delta Crown Operations

## Team Configuration

| Property | Value |
|----------|-------|
| **Display Name** | Delta Crown Operations |
| **Description** | Daily operations hub for Delta Crown Extensions franchise |
| **Visibility** | Private |
| **Mail Nickname** | dce-operations |
| **Owners** | Members of SG-DCE-Leadership |
| **Members** | Members of SG-DCE-AllStaff |
| **Guest Access** | Disabled |
| **Fun Settings** | Giphy: Off, Stickers: Off, Custom Memes: Off |
| **Messaging Settings** | Owner can delete messages: Yes |
| **Member Settings** | Create channels: Off, Add apps: Off, Add tabs: Off |

---

## Channel Specifications

### Channel 1: General (Auto-Created)
| Property | Value |
|----------|-------|
| **Type** | Standard |
| **Description** | Team announcements and general coordination |
| **Files Location** | /sites/dce-operations/Shared Documents/General |
| **Moderation** | Off |

**Tabs**:
| Tab | Type | Source |
|-----|------|--------|
| Staff Schedule | SharePoint List | /sites/dce-operations/Lists/Staff Schedule |
| Tasks | Planner | Auto-created Planner board |
| Wiki | Wiki | Default wiki (remove after setup) |

---

### Channel 2: Daily Ops
| Property | Value |
|----------|-------|
| **Type** | Standard |
| **Description** | Shift reports, daily checklists, incident reports |
| **Files Location** | /sites/dce-operations/Daily Ops/ |
| **Moderation** | Off |

**Tabs**:
| Tab | Type | Source |
|-----|------|--------|
| Inventory | SharePoint List | /sites/dce-operations/Lists/Inventory |

**Usage Pattern**: 
- Morning: Previous shift posts handover notes
- During day: Incident logging, stock alerts
- Evening: End-of-day checklist completion

---

### Channel 3: Bookings
| Property | Value |
|----------|-------|
| **Type** | Standard |
| **Description** | Client booking coordination and scheduling |
| **Files Location** | /sites/dce-operations/Shared Documents/Bookings |
| **Moderation** | Off |

**Tabs**:
| Tab | Type | Source |
|-----|------|--------|
| Booking Tracker | SharePoint List | /sites/dce-operations/Lists/Bookings |
| Calendar | SharePoint Calendar | /sites/dce-operations/Lists/Calendar |

**Usage Pattern**:
- New bookings discussed and confirmed
- Schedule conflicts resolved
- No-show follow-up coordination
- Walk-in availability updates

---

### Channel 4: Marketing
| Property | Value |
|----------|-------|
| **Type** | Standard |
| **Description** | Marketing campaigns, social media, brand coordination |
| **Files Location** | /sites/dce-operations/Shared Documents/Marketing |
| **Moderation** | Off |

**Tabs**:
| Tab | Type | Source |
|-----|------|--------|
| Brand Assets | SharePoint Library | /sites/dce-marketing/Brand Assets |
| Campaigns | SharePoint List | /sites/dce-marketing/Lists/Campaigns |
| Social Calendar | SharePoint List | /sites/dce-marketing/Lists/Social Calendar |

**Usage Pattern**:
- Campaign planning and approvals
- Social media content review before posting
- Brand asset sharing and feedback
- Promotion coordination

---

### Channel 5: Leadership (PRIVATE)
| Property | Value |
|----------|-------|
| **Type** | Private |
| **Description** | Management discussions — financials, HR, strategy |
| **Members** | SG-DCE-Leadership ONLY |
| **Files Location** | /sites/dce-operations-Leadership/ (SEPARATE SPO SITE) |

**⚠️ IMPORTANT**: Private channels automatically create a separate SharePoint site collection. This site must be:
1. Manually associated with DCE Hub
2. Have unique permissions verified
3. Be included in weekly permission audit scope

**Tabs**:
| Tab | Type | Source |
|-----|------|--------|
| Client Records | SharePoint List | /sites/dce-clientservices/Lists/Client Records |
| Docs & Policies | SharePoint Library | /sites/dce-docs/Policies |
| Financial Reports | (Future) | Power BI dashboard |

**Usage Pattern**:
- Weekly management meetings
- HR discussions (hiring, performance)
- Financial reviews
- Strategic planning
- Sensitive client issues

---

## Shared Mailbox Configuration

### Mailbox 1: operations@deltacrown.com
| Property | Value |
|----------|-------|
| **Display Name** | DCE Operations |
| **Email** | operations@deltacrown.com |
| **Send-As Permissions** | SG-DCE-AllStaff |
| **Full Access** | SG-DCE-Leadership |
| **Auto-Reply** | Off |
| **Teams Integration** | Forward to General channel email |

### Mailbox 2: bookings@deltacrown.com
| Property | Value |
|----------|-------|
| **Display Name** | DCE Bookings |
| **Email** | bookings@deltacrown.com |
| **Send-As Permissions** | SG-DCE-AllStaff |
| **Full Access** | SG-DCE-AllStaff |
| **Auto-Reply** | "Thank you for contacting Delta Crown Extensions. We will confirm your booking within 24 hours." |
| **Teams Integration** | Forward to Bookings channel email |

### Mailbox 3: info@deltacrown.com
| Property | Value |
|----------|-------|
| **Display Name** | DCE Info |
| **Email** | info@deltacrown.com |
| **Send-As Permissions** | SG-DCE-AllStaff |
| **Full Access** | SG-DCE-Leadership |
| **Auto-Reply** | "Thank you for contacting Delta Crown Extensions. We will respond within 48 hours." |
| **Teams Integration** | Group mailbox (team-level) |

---

## Teams App Policies

### Allowed Apps
| App | Purpose | Policy |
|-----|---------|--------|
| SharePoint | Site integration | Allowed (built-in) |
| Planner | Task management | Allowed (built-in) |
| OneNote | Meeting notes | Allowed (built-in) |
| Forms | Client surveys | Allowed (built-in) |
| Approvals | Leave/expense approval | Allowed (built-in) |

### Blocked Apps
| Category | Reason |
|----------|--------|
| Third-party connectors | Security (data leakage risk) |
| Custom bots | Not needed; governance overhead |
| External apps | Minimize attack surface |

---

## Teams Governance Policies

### Meeting Policies
| Setting | Value | Reason |
|---------|-------|--------|
| Cloud recording | On (Leadership only) | Meeting documentation |
| Transcription | Off | Privacy / cost |
| External participants | Off | Brand isolation |
| Lobby bypass | Organization users only | Security |

### Messaging Policies
| Setting | Value | Reason |
|---------|-------|--------|
| Delete sent messages | Off | Audit trail |
| Edit sent messages | On | Corrections allowed |
| Read receipts | On | Operational awareness |
| URL previews | On | Convenience |

---

## Provisioning Script Reference

The Teams configuration is deployed by `3.2-Teams-Provisioning.ps1` using these Graph API calls:

```powershell
# 1. Create M365 Group
$group = New-MgGroup -DisplayName "Delta Crown Operations" `
    -Description "Daily operations hub for DCE" `
    -MailEnabled:$true `
    -SecurityEnabled:$true `
    -MailNickname "dce-operations" `
    -GroupTypes @("Unified") `
    -Visibility "Private"

# 2. Create Team from Group
$team = New-MgTeam -GroupId $group.Id `
    -MemberSettings @{ AllowCreateUpdateChannels = $false } `
    -GuestSettings @{ AllowCreateUpdateChannels = $false; AllowDeleteChannels = $false } `
    -FunSettings @{ AllowGiphy = $false; AllowStickersAndMemes = $false }

# 3. Create Standard Channels
$channels = @(
    @{ DisplayName = "Daily Ops"; Description = "Shift reports and daily operations" }
    @{ DisplayName = "Bookings"; Description = "Client booking coordination" }
    @{ DisplayName = "Marketing"; Description = "Marketing campaigns and social media" }
)
foreach ($ch in $channels) {
    New-MgTeamChannel -TeamId $team.Id -DisplayName $ch.DisplayName -Description $ch.Description
}

# 4. Create Private Channel
New-MgTeamChannel -TeamId $team.Id `
    -DisplayName "Leadership" `
    -Description "Management discussions" `
    -MembershipType "Private"

# 5. Add Owners (SG-DCE-Leadership members)
# 6. Add Members (SG-DCE-AllStaff members)
# 7. Configure Tabs per channel
```

---

## Verification Checklist

After deployment, verify:
- [ ] Team appears in Teams admin center
- [ ] All 5 channels visible (4 standard + 1 private)
- [ ] General channel has Staff Schedule and Tasks tabs
- [ ] Daily Ops channel has Inventory tab
- [ ] Bookings channel has Booking Tracker and Calendar tabs
- [ ] Marketing channel has Brand Assets and Campaigns tabs
- [ ] Leadership channel accessible only to SG-DCE-Leadership
- [ ] Leadership channel has Client Records and Docs tabs
- [ ] Private channel SPO site associated with DCE Hub
- [ ] Shared mailboxes sending/receiving correctly
- [ ] Mailbox forwarding to channels working
- [ ] Guest access confirmed disabled
- [ ] File sync between channels and SharePoint working
- [ ] Team members match SG-DCE-AllStaff membership
- [ ] Team owners match SG-DCE-Leadership membership
