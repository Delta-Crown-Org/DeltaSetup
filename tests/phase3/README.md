# Phase 3 Pester Tests

## Overview

Pester 5.x unit tests for Phase 3 PowerShell scripts. These tests validate script **configuration, structure, and patterns** without requiring a live M365 tenant.

## Running Tests

```powershell
# All Phase 3 tests
Invoke-Pester -Path tests/phase3/ -Output Detailed

# Specific test file
Invoke-Pester -Path tests/phase3/Phase3-Config.Tests.ps1 -Output Detailed
```

## Test Categories

| File | What It Tests | Live Tenant? |
|------|---------------|-------------|
| `Phase3-Config.Tests.ps1` | Script configuration constants, auth patterns, coverage | No |
| `Phase3-AuthModule.Tests.ps1` | Auth module structure, exports, production guards | No |

## Future Tests (Integration)

| File | What It Tests | Live Tenant? |
|------|---------------|-------------|
| `Phase3-Smoke.Tests.ps1` | End-to-end with developer tenant | Yes |
| `Phase3-Idempotency.Tests.ps1` | Run-twice validation | Yes |
