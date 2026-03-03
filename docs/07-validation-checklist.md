# Phase 7: End-to-End Validation Checklist

## Overview

Complete validation of the entire Delta Crown Extensions setup. Run through every test case below before considering the setup production-ready.

## Test Environment

| Item | Value |
|------|-------|
| Test user (HTT Brands) | _Fill in: e.g., john.smith@httbrands.com_ |
| Test user (synced to DCE) | _Fill in: e.g., john.smith_httbrands.com#EXT#@deltacrown.onmicrosoft.com_ |
| Shared mailbox | _Fill in: e.g., john.smith@deltacrown.com_ |
| External test recipient | _Fill in: e.g., personal Gmail_ |

## Azure Subscription Tests

| # | Test | Expected Result | Pass/Fail | Notes |
|---|------|-----------------|-----------|-------|
| 1.1 | Sign into Azure Portal as DCE admin | Portal loads, DCE tenant selected | ☐ | |
| 1.2 | Navigate to Subscriptions | `DCE-CORE` visible | ☐ | |
| 1.3 | Create a test resource in `rg-dce-core-001` | Resource created successfully | ☐ | |
| 1.4 | Delete test resource | Cleanup successful | ☐ | |
| 1.5 | Budget alert configured | Alert email received at threshold | ☐ | |

## Cross-Tenant Sync Tests

| # | Test | Expected Result | Pass/Fail | Notes |
|---|------|-----------------|-----------|-------|
| 2.1 | Check synced user in DCE Entra ID | User appears as Member type | ☐ | |
| 2.2 | Check user attributes | displayName, mail, jobTitle synced correctly | ☐ | |
| 2.3 | Add new user to SG-DCE-Sync-Users | User syncs to DCE within 40 min | ☐ | |
| 2.4 | Remove user from SG-DCE-Sync-Users | User deprovisioned/disabled in DCE | ☐ | |
| 2.5 | Verify no MFA double-prompt | User accesses DCE without re-authenticating MFA | ☐ | |

## SharePoint Tests

| # | Test | Expected Result | Pass/Fail | Notes |
|---|------|-----------------|-----------|-------|
| 3.1 | Synced user navigates to DCE SharePoint site | Site loads, user has access | ☐ | |
| 3.2 | User uploads a document | Upload succeeds | ☐ | |
| 3.3 | User edits a document (co-authoring) | Edit saves, co-authoring works | ☐ | |
| 3.4 | User shares document with another DCE member | Sharing works internally | ☐ | |

## Teams Tests

| # | Test | Expected Result | Pass/Fail | Notes |
|---|------|-----------------|-----------|-------|
| 4.1 | Synced user opens Teams (DCE context) | Teams loads, teams visible | ☐ | |
| 4.2 | User posts in General channel | Post appears | ☐ | |
| 4.3 | User starts a 1:1 chat | Chat works | ☐ | |
| 4.4 | User joins a Teams meeting | Meeting joins successfully | ☐ | |
| 4.5 | User accesses Files tab in Teams | SharePoint files load | ☐ | |

## Email Tests

| # | Test | Expected Result | Pass/Fail | Notes |
|---|------|-----------------|-----------|-------|
| 5.1 | Shared mailbox appears in Outlook | Auto-mapped in folder pane | ☐ | |
| 5.2 | User sends email FROM @deltacrown.com | Email sent successfully | ☐ | |
| 5.3 | External recipient receives email | Arrives in inbox (not spam) | ☐ | |
| 5.4 | Check email headers (SPF) | SPF: PASS | ☐ | |
| 5.5 | Check email headers (DKIM) | DKIM: PASS | ☐ | |
| 5.6 | Check email headers (DMARC) | DMARC: PASS | ☐ | |
| 5.7 | Reply to @deltacrown.com email | Reply arrives in shared mailbox | ☐ | |
| 5.8 | User sends to M365 Group email | Group members receive email | ☐ | |

## Security Tests

| # | Test | Expected Result | Pass/Fail | Notes |
|---|------|-----------------|-----------|-------|
| 6.1 | CA policy Report-only logs | Entries visible in CA Insights | ☐ | |
| 6.2 | Legacy auth attempt | Blocked (if CA002 enabled) | ☐ | |
| 6.3 | Break-glass account sign-in | Sign-in works, alert triggered | ☐ | |
| 6.4 | Non-synced user tries DCE access | Access denied | ☐ | |

## DNS Validation

| # | Test | Expected Result | Pass/Fail | Notes |
|---|------|-----------------|-----------|-------|
| 7.1 | MXToolbox SPF check | Pass | ☐ | |
| 7.2 | MXToolbox DKIM check | Pass | ☐ | |
| 7.3 | MXToolbox DMARC check | Pass | ☐ | |

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| IT Administrator | | | |
| Project Sponsor | | | |
