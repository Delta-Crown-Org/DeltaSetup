# DeltaSetup — Claude Code Context

## Project
PowerShell-based M365 tenant provisioning for Delta Crown Extensions (DCE).
Two tenants: source (HTT Brands / httbrands.com) → target (DCE / deltacrown.com).

## Structure
- `config/tenant-config.json` — central config driving all scripts (protected by hook)
- `scripts/00-08` — ordered provisioning scripts, must run sequentially
- `docs/00-07` — matching documentation for each phase
- `templates/` — CSV templates for mailboxes, groups

## Script Conventions
- Scripts 02–06 support `-WhatIf` — always suggest dry runs
- Script 01 must run first to establish tenant connections
- All scripts load config from `config/tenant-config.json` via `$PSScriptRoot`
- PowerShell 7.0+ required (`#Requires -Version 7.0`)

## Safety
- Never edit `.env`, `.pfx`, `.pem`, `.key` files (hook blocks this)
- Editing `tenant-config.json` triggers confirmation (hook)
- Source vs target tenant matters — verify which tenant context before any cmdlet
- Prefer `Get-*` before `New-*` for idempotency

## Available Automations
- `/run-phase` — guided script execution with prerequisite checks
- `/validate-dns` — check SPF/DKIM/DMARC for deltacrown.com
- `ps-reviewer` subagent — review scripts for ErrorAction, WhatIf, hardcoded values, cleanup, tenant safety, idempotency
- `context7` MCP — live docs for Microsoft.Graph, ExchangeOnlineManagement, Az modules

## Commands
- `dig TXT deltacrown.com` — quick SPF check from macOS
- `pwsh -File scripts/<name>.ps1` — run a script
- `pwsh -File scripts/<name>.ps1 -WhatIf` — dry run (04, 05, 06)
