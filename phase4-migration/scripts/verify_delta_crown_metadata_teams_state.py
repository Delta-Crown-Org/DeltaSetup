#!/usr/bin/env python3
"""Read-only DCE user metadata and Teams state verification.

Uses Azure CLI Graph token to verify identity metadata, dynamic group state, and
whether the current delegated context can read Teams/channel state. Raw outputs
are local-only by default and may contain user/group/member details.
"""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests

GRAPH_BASE = "https://graph.microsoft.com/v1.0"
DEFAULT_TENANT_ID = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
DEFAULT_OUTPUT_DIR = ".local/reports/tenant-inventory/metadata-teams-verification"
DCE_OPERATIONS_TEAM_ID = "03255d50-a52d-4b1f-a0f6-37379cc13a35"
LEADERSHIP_CHANNEL_SITE_URL = "https://deltacrown.sharepoint.com/sites/DeltaCrownOperations-Leadership"

USER_FIELDS = [
    "id",
    "displayName",
    "userPrincipalName",
    "accountEnabled",
    "userType",
    "companyName",
    "department",
    "jobTitle",
    "officeLocation",
    "employeeType",
]

GROUP_FIELDS = [
    "id",
    "displayName",
    "mail",
    "securityEnabled",
    "mailEnabled",
    "groupTypes",
    "membershipRule",
    "membershipRuleProcessingState",
]

TARGET_DYNAMIC_GROUPS = {"AllStaff", "Managers", "Marketing", "Stylists", "External"}


@dataclass(frozen=True)
class GraphContext:
    token: str

    @property
    def headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.token}", "Accept": "application/json"}


def log(message: str) -> None:
    print(f"[{datetime.now(timezone.utc).isoformat(timespec='seconds')}] {message}")


def normalize(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (dict, list)):
        return json.dumps(value, sort_keys=True)
    return str(value)


def get_az_graph_token(tenant_id: str) -> str:
    result = subprocess.run(
        [
            "az",
            "account",
            "get-access-token",
            "--tenant",
            tenant_id,
            "--resource",
            "https://graph.microsoft.com",
            "-o",
            "json",
        ],
        capture_output=True,
        text=True,
        timeout=60,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"az token acquisition failed: {result.stderr.strip()}")
    token = json.loads(result.stdout).get("accessToken")
    if not token:
        raise RuntimeError("az token response did not include accessToken")
    return token


def graph_get(ctx: GraphContext, url: str, params: dict[str, Any] | None = None) -> tuple[int, dict[str, Any]]:
    for attempt in range(4):
        response = requests.get(url, headers=ctx.headers, params=params, timeout=60)
        if response.status_code == 429 and attempt < 3:
            delay = int(response.headers.get("Retry-After", "5"))
            log(f"Rate limited; sleeping {delay}s")
            time.sleep(delay)
            continue
        try:
            return response.status_code, response.json()
        except ValueError:
            return response.status_code, {"raw": response.text}
    raise RuntimeError(f"Graph GET failed after retries for {url}")


def graph_get_all(ctx: GraphContext, url: str, params: dict[str, Any] | None = None) -> tuple[list[dict[str, Any]], str]:
    rows: list[dict[str, Any]] = []
    next_url: str | None = url
    next_params = params
    while next_url:
        status, data = graph_get(ctx, next_url, next_params)
        if status >= 400:
            return rows, json.dumps(data)[:1000]
        rows.extend(data.get("value", []))
        next_url = data.get("@odata.nextLink")
        next_params = None
    return rows, ""


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: normalize(row.get(field, "")) for field in fieldnames})


def collect(ctx: GraphContext) -> dict[str, Any]:
    log("Fetching users")
    users, users_error = graph_get_all(
        ctx,
        f"{GRAPH_BASE}/users",
        {"$select": ",".join(USER_FIELDS), "$top": "999"},
    )
    log("Fetching groups")
    groups, groups_error = graph_get_all(
        ctx,
        f"{GRAPH_BASE}/groups",
        {"$select": ",".join(GROUP_FIELDS), "$top": "999"},
    )

    group_member_counts: list[dict[str, Any]] = []
    for group in groups:
        if group.get("displayName") not in TARGET_DYNAMIC_GROUPS:
            continue
        log(f"Fetching dynamic group member count: {group.get('displayName')}")
        members, error = graph_get_all(
            ctx,
            f"{GRAPH_BASE}/groups/{group['id']}/members",
            {"$select": "id,displayName,userPrincipalName", "$top": "999"},
        )
        group_member_counts.append(
            {
                "GroupDisplayName": group.get("displayName", ""),
                "MembershipRule": group.get("membershipRule", ""),
                "ProcessingState": group.get("membershipRuleProcessingState", ""),
                "MemberCount": len(members),
                "Error": error,
            }
        )

    log("Fetching DCE Operations group")
    operations_group_status, operations_group = graph_get(ctx, f"{GRAPH_BASE}/groups/{DCE_OPERATIONS_TEAM_ID}")
    operations_group_members, operations_group_members_error = graph_get_all(
        ctx,
        f"{GRAPH_BASE}/groups/{DCE_OPERATIONS_TEAM_ID}/members",
        {"$select": "id,displayName,userPrincipalName", "$top": "999"},
    )

    teams_checks: list[dict[str, Any]] = []
    for scope, url in [
        ("team", f"{GRAPH_BASE}/teams/{DCE_OPERATIONS_TEAM_ID}"),
        ("channels", f"{GRAPH_BASE}/teams/{DCE_OPERATIONS_TEAM_ID}/channels"),
        ("team-members", f"{GRAPH_BASE}/teams/{DCE_OPERATIONS_TEAM_ID}/members"),
    ]:
        log(f"Checking Teams endpoint: {scope}")
        status, data = graph_get(ctx, url)
        teams_checks.append(
            {
                "Scope": scope,
                "Status": status,
                "Readable": status < 400,
                "ErrorCode": (data.get("error") or {}).get("code", ""),
                "ErrorMessage": (data.get("error") or {}).get("message", "")[:300],
                "ValueCount": len(data.get("value", [])) if isinstance(data.get("value"), list) else "",
            }
        )

    return {
        "users": users,
        "users_error": users_error,
        "groups": groups,
        "groups_error": groups_error,
        "group_member_counts": group_member_counts,
        "operations_group_status": operations_group_status,
        "operations_group": operations_group,
        "operations_group_member_count": len(operations_group_members),
        "operations_group_members_error": operations_group_members_error,
        "teams_checks": teams_checks,
    }


def summarize(data: dict[str, Any]) -> dict[str, Any]:
    users = data["users"]
    field_counts = {
        field: sum(1 for user in users if user.get(field))
        for field in ["companyName", "department", "jobTitle", "officeLocation", "employeeType"]
    }
    disabled_users = [user for user in users if user.get("accountEnabled") is False]
    team_readable = all(row["Readable"] for row in data["teams_checks"])
    return {
        "generated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "user_count": len(users),
        "disabled_user_count": len(disabled_users),
        "field_counts": field_counts,
        "dynamic_groups": data["group_member_counts"],
        "operations_group_status": data["operations_group_status"],
        "operations_group_display_name": data["operations_group"].get("displayName", ""),
        "operations_group_mail": data["operations_group"].get("mail", ""),
        "operations_group_member_count": data["operations_group_member_count"],
        "teams_endpoints_readable": team_readable,
        "teams_checks": data["teams_checks"],
        "leadership_channel_site_url": LEADERSHIP_CHANNEL_SITE_URL,
        "notes": [
            "Teams endpoints may require the delegated reader/admin account to have a valid Teams/Office license in the target tenant.",
            "This verification did not change users, groups, Teams, channels, or SharePoint sites.",
        ],
    }


def run(args: argparse.Namespace) -> int:
    output_dir = Path(args.output_dir)
    ctx = GraphContext(token=get_az_graph_token(args.tenant_id))
    data = collect(ctx)
    summary = summarize(data)

    write_csv(output_dir / "metadata-users.csv", data["users"], USER_FIELDS)
    write_csv(output_dir / "metadata-dynamic-group-counts.csv", data["group_member_counts"], ["GroupDisplayName", "MembershipRule", "ProcessingState", "MemberCount", "Error"])
    write_csv(output_dir / "metadata-teams-endpoint-checks.csv", data["teams_checks"], ["Scope", "Status", "Readable", "ErrorCode", "ErrorMessage", "ValueCount"])
    (output_dir / "metadata-teams-summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")
    log(f"Wrote metadata/Teams verification outputs to {output_dir}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read-only DCE metadata and Teams state verification")
    parser.add_argument("--tenant-id", default=DEFAULT_TENANT_ID)
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    return parser.parse_args()


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args()))
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
