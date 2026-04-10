# 🧪 Delta Crown Extensions QA Test Suite

Quick reference for running QA tests on the DCE SharePoint Hub & Spoke implementation.

## 📋 Test Scripts Overview

| Script | Purpose | Execution Time | Priority |
|--------|---------|--------------|----------|
| `Run-InfrastructureTests.ps1` | Phase 2 infrastructure validation | ~5 min | P0 |
| `Run-SecurityTests.ps1` | Security & compensating controls | ~10 min | P0 |
| `Run-Phase2-SmokeTests.ps1` | Daily smoke tests | ~2 min | P1 |
| `Invoke-RegressionTests.ps1` | Full regression suite | ~15 min | P0 |

## 🚀 Quick Start

### Run All Phase 2 Tests
```powershell
# From repo root
.\tests\qa\Invoke-RegressionTests.ps1 -Phase 2 -GenerateReport
```

### Run Individual Test Suites

**Infrastructure Tests:**
```powershell
.\tests\qa\Run-InfrastructureTests.ps1 -TenantName "deltacrown" -GenerateReport
```

**Security Tests:**
```powershell
# With fail-fast (stop on first failure)
.\tests\qa\Run-SecurityTests.ps1 -TenantName "deltacrown" -FailFast -GenerateReport

# Continue on failures
.\tests\qa\Run-SecurityTests.ps1 -TenantName "deltacrown" -GenerateReport
```

**Daily Smoke Tests:**
```powershell
.\tests\qa\Run-Phase2-SmokeTests.ps1 -TenantName "deltacrown"
```

## 📊 Test Categories

### Phase 2: Infrastructure + Identity (Current)

| Test Category | Coverage | Status |
|--------------|----------|--------|
| Hub Site Provisioning | ✅ Full | Automated |
| Hub Registration | ✅ Full | Automated |
| Hub Association | ✅ Full | Automated |
| Navigation | ✅ Full | Automated |
| Associated Sites | ✅ Full | Automated |
| Azure AD Groups | ⚠️ Partial | Semi-Auto |
| Permission Inheritance | ✅ Full | Automated |
| Dangerous Groups | ✅ Full | Automated |
| External Sharing | ✅ Full | Automated |
| Cross-Brand Isolation | ✅ Full | Automated |

### Phase 3: Collaboration + SharePoint (Upcoming)

| Test Category | Coverage | Status |
|--------------|----------|--------|
| Site Creation from Template | 📋 Planned | - |
| Lists/Libraries | 📋 Planned | - |
| Content Types | 📋 Planned | - |
| Teams Integration | 📋 Planned | - |
| Template Parameterization | 📋 Planned | - |

### Phase 4: Governance + Go-Live (Upcoming)

| Test Category | Coverage | Status |
|--------------|----------|--------|
| Access Reviews | 📋 Planned | - |
| Backup/Recovery | 📋 Planned | - |
| Performance Benchmarks | 📋 Planned | - |

## 🔧 Prerequisites

### Required PowerShell Modules

```powershell
# Install required modules
Install-Module PnP.PowerShell -MinimumVersion 2.0.0 -Force
Install-Module Microsoft.Graph.Groups -MinimumVersion 2.0.0 -Force
Install-Module Pester -MinimumVersion 5.0.0 -Force

# Optional for Teams testing
Install-Module MicrosoftTeams -Force
```

### Required Permissions

| Resource | Permission | Purpose |
|----------|-----------|---------|
| SharePoint | SharePoint Admin | Site management, permissions |
| Azure AD | Group.Read.All | Dynamic group validation |
| Microsoft Graph | Sites.Read.All | Site enumeration |
| Compliance Center | Compliance Admin | Sensitivity labels, DLP |

## 📈 Test Results

Results are exported to:
- `test-results/` - Default output directory
- JSON format for programmatic access
- CSV format for spreadsheet analysis
- HTML format for human-readable reports

### Sample Output Structure
```
test-results/
├── Infrastructure-Test-Report-*.html
├── Infrastructure-Test-Results-*.csv
├── Infrastructure-Test-Results-*.json
├── Security-Test-Report-*.html
├── Security-Test-Results-*.csv
├── Security-Test-Results-*.json
└── smoke/
    └── Smoke-Test-Results-*.csv
```

## ✅ Quality Gates

### Phase 2 Deployment Criteria

| Gate | Criteria | Threshold |
|------|----------|-----------|
| **Infrastructure** | Hub sites provisioned | 100% |
| **Security** | Compensating controls | 100% |
| **Permissions** | Unique permissions | 100% |
| **Isolation** | Cross-brand leakage | 0 incidents |
| **Pass Rate** | Overall test pass rate | >95% |

### Test Execution Schedule

| Frequency | Tests | Command |
|-----------|-------|---------|
| **Daily** | Smoke tests | `Run-Phase2-SmokeTests.ps1` |
| **Pre-deployment** | Full regression | `Invoke-RegressionTests.ps1 -Phase 2` |
| **Weekly** | Security scan | `Run-SecurityTests.ps1` |
| **Post-change** | Infrastructure tests | `Run-InfrastructureTests.ps1` |

## 🚨 Critical Failures

The following failures block deployment:

1. **TC-SEC-001**: Permission inheritance not broken
2. **TC-SEC-002**: Dangerous groups present
3. **TC-SEC-003**: External sharing enabled
4. **TC-SEC-004**: Cross-brand isolation violations
5. **TC-INF-001**: Corporate Hub not provisioned
6. **TC-INF-002**: DCE Hub not provisioned

## 📝 Test Plan Document

See `QA-TEST-PLAN.md` in repo root for:
- Detailed test case specifications
- Pass/fail criteria
- Expected results
- Pre/post conditions
- Performance benchmarks

## 🔗 Related Documentation

- `docs/architecture/decisions/ADR-001-*.md` - Architecture Decision Records
- `phase2-week1/scripts/security-controls/` - Security test scripts
- `phase2-week1/templates/` - PnP provisioning templates

## 🤝 Contributing

When adding new tests:
1. Follow naming convention: `TC-{CATEGORY}-{NUMBER}`
2. Include Test ID, Purpose, Preconditions, Steps, Expected Results
3. Add to appropriate test script
4. Update this README
5. Update QA-TEST-PLAN.md

---

**Version:** 1.0.0  
**Last Updated:** 2025-01-21  
**Owner:** QA Expert (qa-expert-931613)
