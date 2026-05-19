#!/usr/bin/env python3
"""Dry-run scaffold for DCE SyncFabric bridge drift checks.

This intentionally avoids hard-coded tenant IDs, UPNs, object IDs, or app IDs.
Pass concrete values through environment variables in a private runner context.

Current mode is dry-run payload generation. A future live implementation should
query Microsoft Graph and exit non-zero on drift.
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from typing import Any


REQUIRED_KEYS = [
    "DCE_ADMIN_SOURCE_UPN",
    "DCE_ADMIN_TARGET_OBJECT_ID",
    "HTT_TO_DCE_SYNC_APP_OBJECT_ID",
    "HTT_TO_DCE_SYNC_JOB_ID",
    "DCE_BREAK_GLASS_CHECK_NAME",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def env_status() -> dict[str, bool]:
    return {key: bool(os.getenv(key)) for key in REQUIRED_KEYS}


def build_payload() -> dict[str, Any]:
    configured = env_status()
    missing = [key for key, present in configured.items() if not present]

    severity = "high" if missing else "info"
    status = "not_configured" if missing else "dry_run_ready"

    return {
        "timestampUtc": utc_now(),
        "class": "dce-syncfabric-bridge-drift",
        "severity": severity,
        "status": status,
        "dryRun": True,
        "configuredInputs": configured,
        "missingInputs": missing,
        "checksPlanned": [
            "source admin remains directly assigned to HTT-to-DCE sync app",
            "DCE target admin object exists",
            "DCE target admin object is not deleted",
            "DCE target admin object is accountEnabled",
            "DCE target admin remains Global Administrator",
            "HTT-to-DCE sync job is not quarantined",
            "DCE-native cloud-only break-glass admin exists",
        ],
        "recommendedAction": (
            "Set private environment variables before enabling live drift checks."
            if missing
            else "Wire Graph queries and alert routing, then run synthetic failure test."
        ),
    }


def main() -> int:
    print(json.dumps(build_payload(), indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
