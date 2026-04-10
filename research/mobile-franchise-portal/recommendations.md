# Mobile Design Recommendations for Franchise Portals

**Research ID**: web-puppy-b2215e  
**Date**: March 31, 2025  
**Audience**: Product Managers, UX Designers, Developers, Franchise Operations  
**Purpose**: Actionable mobile design recommendations for franchise owner/operator portals

---

## Executive Recommendations

### Top 5 Priorities

1. **Implement Tab-Based Navigation** (Impact: Very High)
   - Three primary tabs: Dashboard, News, Resources
   - Reduces cognitive load for field users
   - Based on 79% of mobile intranets serving field staff

2. **Design Card-Based Dashboard** (Impact: Very High)
   - Medium cards (2 per row) for quick actions
   - Large cards (1 per row) for detailed content
   - 48×48 dp minimum touch targets on all cards

3. **Ensure Offline Support** (Impact: High)
   - Critical resources available without connectivity
   - State preservation during interruptions
   - Background sync when connection restored

4. **Achieve WCAG 2.2 AA Compliance** (Impact: High)
   - 24×24 CSS px minimum touch targets
   - Screen reader optimization
   - Full keyboard navigation support

5. **Optimize for Quick Tasks** (Impact: High)
   - 30-second task completion goal
   - Progressive disclosure for detailed content
   - Minimize data entry requirements

---

## 1. Mobile-First Design Specifications

### Screen Real Estate Guidelines

#### Portrait Mode (Primary)

```
┌─────────────────────────────┐  ← Safe Area (status bar)
│         Status Bar          │  ~44pt/24dp
├─────────────────────────────┤
│     Navigation Bar/Title    │  ~44pt/56dp
├─────────────────────────────┤
│   ┌───────┐ ┌───────┐      │  ← Medium Cards
│   │ Card  │ │ Card  │      │  ~180×120 dp each
│   │  1    │ │  2    │      │  16dp padding
│   └───────┘ └───────┘      │
│                             │
│   ┌─────────────────────┐  │  ← Large Card
│   │                     │  │  ~376×200 dp
│   │      Card 3         │  │  16dp padding
│   │                     │  │
│   └─────────────────────┘  │
│                             │
├─────────────────────────────┤
│  Tab 1 │ Tab 2 │ Tab 3     │  ← Bottom Navigation
│  (56dp height)              │
├─────────────────────────────┤
│       Home Indicator        │  ~34pt (iPhone X+)
└─────────────────────────────┘
```

#### Content Area: 375×667 dp (iPhone standard)

### Typography Scale

| Element | Size (iOS) | Size (Android) | Weight | Line Height |
|---------|-----------|----------------|--------|-------------|
| **Navigation Title** | 17pt | 20sp | Semibold | 1.2 |
| **Card Title** | 17pt | 18sp | Semibold | 1.3 |
| **Card Body** | 15pt | 16sp | Regular | 1.4 |
| **Button Text** | 17pt | 16sp | Medium | 1.0 |
| **Caption** | 13pt | 14sp | Regular | 1.3 |
| **Tab Label** | 11pt | 12sp | Medium | 1.0 |

### Color & Contrast Requirements

| Element | Minimum Ratio | Recommended | Notes |
|---------|--------------|-------------|-------|
| **Body Text** | 4.5:1 | 7:1 | WCAG AA vs AAA |
| **Large Text** | 3:1 | 4.5:1 | 18pt+ or 14pt+ bold |
| **UI Components** | 3:1 | 4.5:1 | Buttons, form fields |
| **Graphical Objects** | 3:1 | 4.5:1 | Icons, charts |

---

## 2. Touch Target Specifications

### Minimum Touch Target Sizes

| Platform | Minimum | Comfortable | Notes |
|----------|---------|-------------|-------|
| **WCAG 2.2 AA** | 24×24 CSS px | 44×44 CSS px | Legal minimum |
| **iOS** | 44×44 pt | 60×60 pt | Apple HIG |
| **Android** | 48×48 dp | 56×56 dp | Material Design |

### Recommended Implementation

**Use 48×48 dp as universal minimum** (meets all standards)

```css
/* Touch target specification */
.touch-target {
  min-width: 48dp;
  min-height: 48dp;
  padding: 12dp; /* Visual element can be smaller with padding */
}

/* Touch target spacing */
.touch-target + .touch-target {
  margin: 8dp; /* Minimum 8dp between targets */
}
```

### Visual Target vs Touch Target

```
Visual element: 24×24 dp (icon)
Touch target:   48×48 dp (with padding)
                ┌──────────────────┐
                │   ┌──────────┐   │
                │   │   Icon   │   │
                │   │  24×24   │   │
                │   └──────────┘   │
                │                  │
                │   Touch area     │
                │   48×48 dp       │
                └──────────────────┘
```

### High-Priority Touch Targets

| Element | Size | Spacing | Priority |
|---------|------|---------|----------|
| **Primary Buttons** | 48×48 dp min | 16dp | Critical |
| **Navigation Tabs** | 56dp height | 0dp | Critical |
| **Card Actions** | 48×48 dp | 8dp | High |
| **Form Fields** | 48dp height | 16dp | High |
| **List Items** | 48dp min height | 1dp | High |
| **Icon Buttons** | 48×48 dp | 8dp | Medium |
| **Links** | 44×44 dp | 8dp | Medium |

---

## 3. Viva Connections Mobile Implementation

### Dashboard Architecture

#### Card Types & Usage

**Medium Cards (180×120 dp, 2 per row)**
- Quick status updates
- Single-action buttons
- Mini forms (1-2 fields)
- Notification summaries

**Large Cards (376×200 dp, 1 per row)**
- Detailed content
- Multi-step forms
- Data visualizations
- Rich media

### Recommended Card Layout

```
┌─────────────────────────────────────┐
│ Dashboard Tab                       │
├─────────────────────────────────────┤
│                                     │
│ ┌──────────┐  ┌──────────┐         │
│ │ ⏰ Clock │  │ 📋 Tasks │         │
│ │   In     │  │  3 Due   │         │
│ │          │  │          │         │
│ │ [Button] │  │ [Button] │         │
│ └──────────┘  └──────────┘         │
│                                     │
│ ┌────────────────────────────────┐  │
│ │ 📰 Announcements               │  │
│ │                                │  │
│ │ • New promotion starting...   │  │
│ │ • Policy update: Hours of...  │  │
│ │ • Training required by...     │  │
│ │                                │  │
│ │ [View All]                     │  │
│ └────────────────────────────────┘  │
│                                     │
│ ┌──────────┐  ┌──────────┐         │
│ │ 📚 Train │  │ 📞 Quick │         │
│ │  85%     │  │ Contacts │         │
│ │ Complete │  │          │         │
│ │          │  │          │         │
│ │ [Continue]│  │ [Open]   │         │
│ └──────────┘  └──────────┘         │
│                                     │
└─────────────────────────────────────┘
```

### Quick View Implementation

For card interactions that don't require full page navigation:

```
┌─────────────────────────────────────┐
│                                     │
│ ┌────────────────────────────────┐  │
│ │ ╔════════════════════════════╗ │  │ ← Quick View Modal
│ │ ║  📋 Task Details            ║ │  │
│ │ ║                             ║ │  │
│ │ ║  Review daily checklist    ║ │  │
│ │ ║  Due: Today by 5 PM        ║ │  │
│ │ ║                             ║ │  │
│ │ ║  [✓ Complete] [Skip →]     ║ │  │
│ │ ║                             ║ │  │
│ │ ╚════════════════════════════╝ │  │
│ │                                 │  │
│ │      [Tap outside to close]     │  │
│ └────────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

### Mobile-Specific Viva Connections Considerations

1. **Fixed Portrait Layout**
   - Dashboard displays in portrait only
   - Cards reflow automatically
   - User can reorder cards (device-specific)

2. **Native Card UI**
   - iOS: Native iOS card rendering
   - Android: Material Design cards
   - Consistent behavior across platforms

3. **Tab Navigation**
   - Dashboard (default)
   - News
   - Resources
   - Consistent with Microsoft Teams mobile pattern

---

## 4. Franchise Owner-Specific Features

### Dashboard Cards for Franchise Operations

#### 1. Daily Operations Card (Medium)

```
┌──────────────────┐
│ ⏰ Daily Ops     │
│                  │
│ Clock In: 8:00 AM│
│ Status: Working  │
│                  │
│ [Clock Out]      │
└──────────────────┘
```

**Features:**
- Time tracking integration
- Shift status display
- Quick clock in/out
- Break tracking

#### 2. Announcements Card (Large)

```
┌──────────────────────────────┐
│ 📰 Announcements            │
│                              │
│ 🔴 Urgent: Weather alert    │
│    Severe storms expected...│
│                              │
│ 📢 Policy Update            │
│    New hours of operation...│
│                              │
│ 🎉 Congratulations!         │
│    Top performer this month │
│                              │
│ [View All Announcements →]  │
└──────────────────────────────┘
```

**Features:**
- Priority indicators (urgent, normal)
- Read/unread status
- Category filtering
- Push notification integration

#### 3. Training & Compliance Card (Medium)

```
┌──────────────────┐
│ 📚 Training      │
│                  │
│ ████████████░░░ │
│ 85% Complete    │
│                  │
│ 2 Due This Week │
│                  │
│ [Continue]      │
└──────────────────┘
```

**Features:**
- Progress visualization
- Due date reminders
- Quick access to current module
- Certification tracking

#### 4. Quick Resources Card (Medium)

```
┌──────────────────┐
│ 📞 Quick Links   │
│                  │
│ Operations       │
│ Support          │
│ Marketing        │
│                  │
│ [View All]       │
└──────────────────┘
```

**Features:**
- Favorite resources
- Recently accessed
- Quick search
- Offline access indicator

### Mobile Workflow Optimizations

#### Quick Task Completion (< 30 seconds)

| Task | Target Time | Key Optimizations |
|------|-------------|-------------------|
| **Clock In/Out** | 5 seconds | One-tap with biometric confirmation |
| **Check Announcements** | 10 seconds | Scannable list, expandable summaries |
| **Complete Training Module** | 30 seconds | Bite-sized content, progress save |
| **Access Resource** | 10 seconds | Smart search, favorites, offline cache |
| **Submit Incident** | 30 seconds | Quick forms, photo attachment, GPS |
| **Contact Support** | 10 seconds | Quick dial, chat, email options |

### On-the-Go Use Cases

#### Scenario 1: Opening Store

1. **Clock In** (Dashboard card - 1 tap)
2. **Check Announcements** (Dashboard card - 30 seconds)
3. **Review Daily Checklist** (Quick view - 2 minutes)
4. **Access Operations Manual** (Resources tab - if needed)

**Total Time Target: < 5 minutes**

#### Scenario 2: Incident Reporting

1. **Quick Actions** → Report Incident
2. **Photo Capture** (auto-attach)
3. **Category Selection** (dropdown)
4. **Brief Description** (voice input supported)
5. **GPS Location** (auto-captured)
6. **Submit** (one tap)

**Total Time Target: < 2 minutes**

#### Scenario 3: Training During Downtime

1. **Training Card** → Continue
2. **Progressive Module** (5-10 minute segments)
3. **Auto-save Progress**
4. **Resume Later** (exact position)

**Session Length: 5-15 minutes**

---

## 5. Mobile Accessibility Implementation

### WCAG 2.2 Compliance Checklist

#### Level A Requirements (Must Have)

- [ ] **1.1.1 Non-text Content**: Alt text for all images
- [ ] **1.3.1 Info and Relationships**: Semantic markup
- [ ] **2.1.1 Keyboard**: Full keyboard navigation
- [ ] **2.2.2 Pause, Stop, Hide**: Control over auto-playing content
- [ ] **2.4.4 Link Purpose**: Descriptive link text
- [ ] **3.1.1 Language of Page**: Lang attribute set
- [ ] **4.1.2 Name, Role, Value**: Accessible names for components

#### Level AA Requirements (Must Have)

- [ ] **1.4.3 Contrast**: 4.5:1 for normal text
- [ ] **1.4.4 Resize Text**: Support 200% zoom
- [ ] **1.4.10 Reflow**: No horizontal scroll at 320px
- [ ] **1.4.11 Non-text Contrast**: 3:1 for UI components
- [ ] **2.4.6 Headings and Labels**: Descriptive headings
- [ ] **2.4.7 Focus Visible**: Visible focus indicator
- [ ] **2.5.5 Target Size**: 44×44 CSS px (enhanced)

#### Level AAA Recommendations (Should Have)

- [ ] **1.4.6 Contrast**: 7:1 for normal text
- [ ] **2.4.9 Link Purpose**: Link text alone describes purpose
- [ ] **2.5.5 Target Size**: 44×44 CSS px minimum

### Screen Reader Optimization

#### iOS VoiceOver

```swift
// Proper accessibility label
button.accessibilityLabel = "Clock In"
button.accessibilityHint = "Records your start time for the day"
button.accessibilityTraits = .button

// Dynamic type support
label.font = UIFont.preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true
```

#### Android TalkBack

```kotlin
// Proper content description
button.contentDescription = "Clock In, records your start time"
button.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES

// Dynamic text sizing
TextViewCompat.setAutoSizeTextTypeWithDefaults(textView, 
    TextViewCompat.AUTO_SIZE_TEXT_TYPE_UNIFORM)
```

### Touch Target Accessibility

```css
/* Ensure touch targets are accessible */
.interactive-element {
  min-width: 48px;
  min-height: 48px;
  
  /* Visual element can be smaller */
  display: flex;
  align-items: center;
  justify-content: center;
}

.interactive-element .icon {
  width: 24px;
  height: 24px;
}
```

### Focus Management

#### Visible Focus Indicator

```css
/* High contrast focus ring */
:focus-visible {
  outline: 3px solid #005A9C;
  outline-offset: 2px;
  border-radius: 4px;
}

/* Touch devices - show focus on keyboard navigation only */
@media (hover: none) {
  :focus:not(:focus-visible) {
    outline: none;
  }
}
```

#### Focus Order

1. Top navigation (left to right)
2. Dashboard cards (top to bottom, left to right)
3. Bottom navigation
4. Modal/dialog content (when open)

---

## 6. Performance Optimization

### Load Time Budgets

| Metric | Budget | Maximum | Notes |
|--------|--------|---------|-------|
| **First Contentful Paint** | <1.5s | <2.5s | First visible content |
| **Largest Contentful Paint** | <2.5s | <4s | Main content loaded |
| **Time to Interactive** | <3.5s | <5s | Fully interactive |
| **Cumulative Layout Shift** | <0.1 | <0.25 | Visual stability |

### Image Optimization

#### Responsive Images

```html
<picture>
  <source media="(max-width: 600px)" 
          srcset="image-small.webp">
  <source media="(min-width: 601px)" 
          srcset="image-large.webp">
  <img src="image-fallback.jpg" 
       alt="Description"
       loading="lazy">
</picture>
```

#### Format Priorities

1. **WebP** (primary) - 30% smaller than JPEG
2. **AVIF** (modern browsers) - 50% smaller than JPEG
3. **JPEG** (fallback) - Universal support

### Code Optimization

#### Bundle Size Budgets

| Resource | Budget | Notes |
|----------|--------|-------|
| **JavaScript** | <200KB (gzipped) | Core bundle |
| **CSS** | <50KB (gzipped) | Critical CSS inlined |
| **Images** | <500KB total | Per page |
| **Total Page Weight** | <1MB | Initial load |

#### Lazy Loading Strategy

```javascript
// Intersection Observer for lazy loading
const imageObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const img = entry.target;
      img.src = img.dataset.src;
      img.classList.remove('lazy');
      imageObserver.unobserve(img);
    }
  });
});

// Observe all lazy images
document.querySelectorAll('img.lazy').forEach(img => {
  imageObserver.observe(img);
});
```

### Offline Support Implementation

#### Service Worker Strategy

```javascript
// Cache-first for static assets
workbox.routing.registerRoute(
  ({request}) => request.destination === 'image',
  new workbox.strategies.CacheFirst({
    cacheName: 'images',
    plugins: [
      new workbox.expiration.ExpirationPlugin({
        maxEntries: 60,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
      }),
    ],
  })
);

// Network-first for API calls with offline fallback
workbox.routing.registerRoute(
  ({url}) => url.pathname.startsWith('/api/'),
  new workbox.strategies.NetworkFirst({
    cacheName: 'api-cache',
    plugins: [
      new workbox.backgroundSync.BackgroundSyncPlugin('api-queue', {
        maxRetentionTime: 24 * 60, // Retry for 24 hours
      }),
    ],
  })
);
```

#### Offline Data Storage

```javascript
// IndexedDB for offline data
const db = await openDB('franchise-portal', 1, {
  upgrade(db) {
    db.createObjectStore('resources', { keyPath: 'id' });
    db.createObjectStore('announcements', { keyPath: 'id' });
    db.createObjectStore('pending-actions', { keyPath: 'timestamp' });
  },
});

// Store critical resources offline
async function cacheCriticalResources() {
  const resources = await fetchResources();
  const tx = db.transaction('resources', 'readwrite');
  resources.forEach(resource => {
    tx.store.put(resource);
  });
  await tx.done;
}
```

---

## 7. Implementation Roadmap

### Phase 1: Foundation (Months 1-3)

**Goals:**
- Basic tab navigation
- Dashboard with 4 core cards
- News reader
- Resources list
- Offline support for critical content

**Deliverables:**
- [ ] Tab-based navigation structure
- [ ] Dashboard with Clock In, Announcements, Training, Resources cards
- [ ] News feed with filtering
- [ ] Resources directory with search
- [ ] Offline caching for static content
- [ ] WCAG 2.2 AA compliance audit

**Success Metrics:**
- Page load < 3 seconds on 3G
- Touch targets 100% compliant
- Screen reader navigable
- 70% of franchise owners can complete basic tasks

### Phase 2: Enhancement (Months 4-6)

**Goals:**
- Advanced dashboard features
- Training module integration
- Push notifications
- Enhanced offline support
- Performance optimization

**Deliverables:**
- [ ] Customizable dashboard cards
- [ ] Training progress tracking
- [ ] Push notification system
- [ ] Background sync for offline actions
- [ ] Image optimization implementation
- [ ] Advanced search with filters

**Success Metrics:**
- Page load < 2 seconds on 4G
- Offline task completion rate > 90%
- Push notification delivery > 95%
- User satisfaction score > 4.0/5.0

### Phase 3: Expansion (Months 7-9)

**Goals:**
- Advanced features
- Integrations
- Analytics
- Admin capabilities

**Deliverables:**
- [ ] Performance analytics dashboard
- [ ] Integration with franchise management system
- [ ] Admin content management
- [ ] Advanced reporting
- [ ] Multi-language support
- [ ] Dark mode

**Success Metrics:**
- 80% active user rate
- < 5% error rate
- 4.5+ user satisfaction score
- 50% reduction in support tickets

---

## 8. Testing Requirements

### Device Testing Matrix

| Device | OS Version | Priority | Testing Type |
|--------|-----------|----------|--------------|
| iPhone 15 Pro | iOS 17 | Critical | Full regression |
| iPhone 14 | iOS 17 | Critical | Full regression |
| iPhone SE | iOS 17 | High | Smoke + critical paths |
| Samsung S24 | Android 14 | Critical | Full regression |
| Google Pixel 8 | Android 14 | Critical | Full regression |
| Samsung A54 | Android 13 | High | Smoke + critical paths |
| iPad Pro | iPadOS 17 | Medium | Basic functionality |
| Various tablets | Android 12+ | Low | Smoke test |

### Accessibility Testing

#### Automated Testing
- [ ] Lighthouse accessibility audit (>90 score)
- [ ] axe-core automated testing
- [ ] Color contrast analyzer
- [ ] Touch target size validator

#### Manual Testing
- [ ] Screen reader navigation (VoiceOver, TalkBack)
- [ ] Keyboard-only navigation
- [ ] Zoom to 200% functionality
- [ ] Voice control (iOS) / Voice Access (Android)
- [ ] Switch control testing

#### Testing with Real Users
- [ ] 5 franchise owners with disabilities
- [ ] Task completion testing
- [ ] Think-aloud protocol
- [ ] Satisfaction survey

### Performance Testing

| Metric | Tool | Target | Frequency |
|--------|------|--------|-----------|
| **Core Web Vitals** | Lighthouse | Meet targets | Per release |
| **Bundle Size** | webpack-bundle-analyzer | <200KB JS | Per build |
| **Load Time** | WebPageTest | <3s 3G | Weekly |
| **Memory Usage** | Chrome DevTools | <100MB | Monthly |
| **Battery Impact** | Xcode/Android Studio | Minimal | Per release |

---

## 9. Success Metrics

### User Experience Metrics

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| **Task Completion Rate** | - | >90% | Usability testing |
| **Task Completion Time** | - | <30 sec avg | Analytics |
| **Error Rate** | - | <5% | Error tracking |
| **User Satisfaction (CSAT)** | - | >4.5/5 | Survey |
| **Net Promoter Score (NPS)** | - | >50 | Survey |

### Engagement Metrics

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| **Daily Active Users (DAU)** | - | 70% of franchisees | Analytics |
| **Session Duration** | - | 5-10 minutes | Analytics |
| **Sessions per Week** | - | 5+ per user | Analytics |
| **Feature Adoption** | - | 80% use 3+ features | Analytics |
| **Offline Usage** | - | 20% of sessions | Analytics |

### Technical Metrics

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| **App Store Rating** | - | >4.5/5 | App Store |
| **Crash Rate** | - | <0.5% | Crash reporting |
| **API Response Time** | - | <500ms | Monitoring |
| **Uptime** | - | 99.9% | Monitoring |
| **WCAG Compliance** | - | 100% AA | Audit |

---

## Appendix: Quick Reference

### Touch Target Quick Reference

```
┌─────────────────────────────────────────┐
│  MINIMUM: 48×48 dp (universal standard) │
│  SPACING: 8dp between targets           │
│  COMFORTABLE: 56×56 dp (high-use items)│
└─────────────────────────────────────────┘
```

### Color Contrast Quick Reference

```
Normal text (<18pt):  4.5:1 minimum (7:1 recommended)
Large text (18pt+):   3:1 minimum (4.5:1 recommended)
UI Components:        3:1 minimum (4.5:1 recommended)
```

### Performance Quick Reference

```
Load Time Budgets:
├─ First Contentful Paint: <1.5s
├─ Largest Contentful Paint: <2.5s
├─ Time to Interactive: <3.5s
└─ Total Page Weight: <1MB

Bundle Size Budgets:
├─ JavaScript: <200KB gzipped
├─ CSS: <50KB gzipped
└─ Images: <500KB per page
```

---

**Document Owner**: web-puppy-b2215e  
**Last Updated**: March 31, 2025  
**Review Cycle**: Monthly during implementation, quarterly post-launch  
**Questions**: Refer to detailed analysis in `analysis.md` and source documentation in `raw-findings/`
