# Approvals

This directory holds Tyler's approval files for live tenant writes.

Create the appropriate file before running any script that requires an approval gate.
Files in this directory are gitignored by default — they are local-only signals.
The scripts reference them but do not commit them.

## Current approval files needed

| File | Unlocks |
|------|---------|
| `exchange-jenna-dce-mailbox.txt` | `tools/provision-jenna-dce-mailbox.ps1` — creates jenna.bowden@deltacrown.com SharedMailbox |
| `exchange-cos-mailbox-conversion.txt` | SharedMailbox conversion for ColoradoSprings@deltacrown.com |
| `entra-jenna-bowden-extensionattribute1.txt` | extensionAttribute1 write on Jenna's DCE guest record |

## Format

Each approval file must contain the word APPROVED on the first line:

```
APPROVED: <description of what is being approved>
Date: YYYY-MM-DD
Tyler Granlund
```
