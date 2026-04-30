#!/usr/bin/env python3
"""Read-only Delta Crown identity/group inventory via Microsoft Graph.

Uses the current Azure CLI login to obtain a Graph token for the Delta Crown
tenant. Raw outputs are local-only by default and may contain user names,
UPNs, group memberships, and role assignments. Do not commit raw outputs.
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
DEFAULT_OUTPUT_DIR = ".local/reports/tenant-inventory/identity"

USER_FIELDS = [
    "id",
    "displayName",
    "userPrincipalName",
    "mail",
    "accountEnabled",
    "userType",
    "companyName",
    "department",
    "jobTitle",
    "officeLocation",
    "employeeType",
    "createdDateTime",
]

GROUP_FIELDS = [
    "id",
    "displayName",
    "description",
    "mail",
    "mailEnabled",
    "securityEnabled",
    "groupTypes",
    "membershipRule",
    "membershipRuleProcessingState",
    "createdDateTime",
]


@dataclass(frozen=True)
class GraphContext:
    token: str
    tenant_id: str

    @property
    def headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }


def log(message: str) -> None:
    print(f"[{datetime.now(timezone.utc).isoformat(timespec='seconds')}] {message}")


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


def graph_get(ctx: GraphContext, url: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
    for attempt in range(4):
        response = requests.get(url, headers=ctx.headers, params=params, timeout=60)
        if response.status_code == 429 and attempt < 3:
            delay = int(response.headers.get("Retry-After", "5"))
            log(f"Rate limited; sleeping {delay}s")
            time.sleep(delay)
            continue
        if response.ok:
            return response.json()
        raise RuntimeError(f"Graph GET failed {response.status_code} for {url}: {response.text[:1200]}")
    raise RuntimeError(f"Graph GET failed after retries for {url}")


def graph_get_all(ctx: GraphContext, url: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    next_url: str | None = url
    next_params = params
    while next_url:
        data = graph_get(ctx, next_url, next_params)
        rows.extend(data.get("value", []))
        next_url = data.get("@odata.nextLink")
        next_params = None
    return rows


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: normalize(row.get(field, "")) for field in fieldnames})


def normalize(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, list):
        return ";".join(str(item) for item in value)
    if isinstance(value, dict):
        return json.dumps(value, sort_keys=True)
    return str(value)


def object_label(obj: dict[str, Any]) -> str:
    return obj.get("displayName") or obj.get("userPrincipalName") or obj.get("mail") or obj.get("id") or ""


def object_type(obj: dict[str, Any]) -> str:
    odata_type = obj.get("@odata.type", "")
    if odata_type:
        return odata_type.split(".")[-1]
    if "userPrincipalName" in obj:
        return "user"
    if "groupTypes" in obj:
        return "group"
    return "directoryObject"


def get_users(ctx: GraphContext) -> list[dict[str, Any]]:
    log("Fetching users")
    return graph_get_all(
        ctx,
        f"{GRAPH_BASE}/users",
        {
            "$select": ",".join(USER_FIELDS),
            "$top": "999",
        },
    )


def get_groups(ctx: GraphContext) -> list[dict[str, Any]]:
    log("Fetching groups")
    return graph_get_all(
        ctx,
        f"{GRAPH_BASE}/groups",
        {
            "$select": ",".join(GROUP_FIELDS),
            "$top": "999",
        },
    )


def get_group_relationships(ctx: GraphContext, groups: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    memberships: list[dict[str, Any]] = []
    owners: list[dict[str, Any]] = []
    counts: list[dict[str, Any]] = []

    for group in groups:
        group_id = group["id"]
        group_name = group.get("displayName", "")
        log(f"Fetching group relationships: {group_name}")
        members = graph_get_all(
            ctx,
            f"{GRAPH_BASE}/groups/{group_id}/members",
            {"$select": "id,displayName,userPrincipalName,mail", "$top": "999"},
        )
        group_owners = graph_get_all(
            ctx,
            f"{GRAPH_BASE}/groups/{group_id}/owners",
            {"$select": "id,displayName,userPrincipalName,mail", "$top": "999"},
        )
        counts.append(
            {
                "GroupId": group_id,
                "GroupDisplayName": group_name,
                "MemberCount": len(members),
                "OwnerCount": len(group_owners),
            }
        )
        for member in members:
            memberships.append(
                {
                    "GroupId": group_id,
                    "GroupDisplayName": group_name,
                    "MemberId": member.get("id", ""),
                    "MemberType": object_type(member),
                    "MemberDisplayName": object_label(member),
                    "MemberUPN": member.get("userPrincipalName", ""),
                    "MemberMail": member.get("mail", ""),
                }
            )
        for owner in group_owners:
            owners.append(
                {
                    "GroupId": group_id,
                    "GroupDisplayName": group_name,
                    "OwnerId": owner.get("id", ""),
                    "OwnerType": object_type(owner),
                    "OwnerDisplayName": object_label(owner),
                    "OwnerUPN": owner.get("userPrincipalName", ""),
                    "OwnerMail": owner.get("mail", ""),
                }
            )
    return memberships, owners, counts


def get_directory_roles(ctx: GraphContext) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    log("Fetching activated directory roles")
    roles = graph_get_all(
        ctx,
        f"{GRAPH_BASE}/directoryRoles",
        {"$select": "id,displayName,description,roleTemplateId"},
    )
    members: list[dict[str, Any]] = []
    for role in roles:
        role_id = role["id"]
        role_name = role.get("displayName", "")
        log(f"Fetching role members: {role_name}")
        role_members = graph_get_all(
            ctx,
            f"{GRAPH_BASE}/directoryRoles/{role_id}/members",
            {"$select": "id,displayName,userPrincipalName,mail"},
        )
        role["memberCount"] = len(role_members)
        for member in role_members:
            members.append(
                {
                    "RoleId": role_id,
                    "RoleDisplayName": role_name,
                    "MemberId": member.get("id", ""),
                    "MemberType": object_type(member),
                    "MemberDisplayName": object_label(member),
                    "MemberUPN": member.get("userPrincipalName", ""),
                    "MemberMail": member.get("mail", ""),
                }
            )
    return roles, members


def summarize(users: list[dict[str, Any]], groups: list[dict[str, Any]], group_counts: list[dict[str, Any]], roles: list[dict[str, Any]]) -> dict[str, Any]:
    required_user_fields = [
        "companyName",
        "department",
        "jobTitle",
        "officeLocation",
        "employeeType",
    ]
    field_counts = {
        field: sum(1 for user in users if user.get(field))
        for field in required_user_fields
    }
    dynamic_groups = [group for group in groups if group.get("membershipRule")]
    mail_enabled_groups = [group for group in groups if group.get("mailEnabled")]
    security_groups = [group for group in groups if group.get("securityEnabled")]
    disabled_users = [user for user in users if user.get("accountEnabled") is False]
    guest_users = [user for user in users if user.get("userType") == "Guest"]
    member_users = [user for user in users if user.get("userType") == "Member"]

    return {
        "generated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "user_count": len(users),
        "member_user_count": len(member_users),
        "guest_user_count": len(guest_users),
        "disabled_user_count": len(disabled_users),
        "group_count": len(groups),
        "dynamic_group_count": len(dynamic_groups),
        "mail_enabled_group_count": len(mail_enabled_groups),
        "security_group_count": len(security_groups),
        "directory_role_count": len(roles),
        "field_counts": field_counts,
        "groups": [
            {
                "displayName": group.get("displayName", ""),
                "mail": group.get("mail", ""),
                "mailEnabled": group.get("mailEnabled", ""),
                "securityEnabled": group.get("securityEnabled", ""),
                "groupTypes": group.get("groupTypes", []),
                "membershipRule": group.get("membershipRule", ""),
                "membershipRuleProcessingState": group.get("membershipRuleProcessingState", ""),
                "memberCount": next((row["MemberCount"] for row in group_counts if row["GroupId"] == group.get("id")), 0),
                "ownerCount": next((row["OwnerCount"] for row in group_counts if row["GroupId"] == group.get("id")), 0),
            }
            for group in groups
        ],
        "roles": [
            {
                "displayName": role.get("displayName", ""),
                "memberCount": role.get("memberCount", 0),
            }
            for role in roles
        ],
    }


def write_summary(path: Path, summary: dict[str, Any]) -> None:
    lines = [
        "# Delta Crown Identity Inventory Summary",
        "",
        f"Generated: {summary['generated']}",
        "Tenant: deltacrown.com / ce62e17d-2feb-4e67-a115-8ea4af68da30",
        "",
        "## Totals",
        "",
        f"- Users: {summary['user_count']}",
        f"- Member users: {summary['member_user_count']}",
        f"- Guest users: {summary['guest_user_count']}",
        f"- Disabled users: {summary['disabled_user_count']}",
        f"- Groups: {summary['group_count']}",
        f"- Dynamic groups: {summary['dynamic_group_count']}",
        f"- Mail-enabled groups: {summary['mail_enabled_group_count']}",
        f"- Security-enabled groups: {summary['security_group_count']}",
        f"- Activated directory roles: {summary['directory_role_count']}",
        "",
        "## User metadata completeness",
        "",
        "| Field | Populated users |",
        "|---|---:|",
    ]
    for field, count in summary["field_counts"].items():
        lines.append(f"| {field} | {count} |")

    lines.extend(["", "## Groups", "", "| Group | Mail | Type | Members | Owners | Dynamic rule present |", "|---|---|---|---:|---:|---|"])
    for group in sorted(summary["groups"], key=lambda row: row["displayName"].lower()):
        group_types = ";".join(group.get("groupTypes") or [])
        type_label = group_types or ("Security" if group.get("securityEnabled") else "Group")
        dynamic_rule = "Yes" if group.get("membershipRule") else "No"
        lines.append(
            f"| {group['displayName']} | {group.get('mail', '')} | {type_label} | "
            f"{group['memberCount']} | {group['ownerCount']} | {dynamic_rule} |"
        )

    lines.extend(["", "## Activated directory roles", "", "| Role | Members |", "|---|---:|"])
    for role in sorted(summary["roles"], key=lambda row: row["displayName"].lower()):
        lines.append(f"| {role['displayName']} | {role['memberCount']} |")

    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- This summary excludes raw user, group membership, owner, and role-member rows.",
            "- Raw CSV outputs are local-only and may contain user names, UPNs, group memberships, and role assignments.",
            "- No users, groups, roles, licenses, or tenant settings were changed.",
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run(args: argparse.Namespace) -> int:
    output_dir = Path(args.output_dir)
    ctx = GraphContext(token=get_az_graph_token(args.tenant_id), tenant_id=args.tenant_id)

    users = get_users(ctx)
    groups = get_groups(ctx)
    memberships, owners, group_counts = get_group_relationships(ctx, groups)
    roles, role_members = get_directory_roles(ctx)
    summary = summarize(users, groups, group_counts, roles)

    write_csv(output_dir / "identity-users.csv", users, USER_FIELDS)
    write_csv(output_dir / "identity-groups.csv", groups, GROUP_FIELDS)
    write_csv(
        output_dir / "identity-group-memberships.csv",
        memberships,
        ["GroupId", "GroupDisplayName", "MemberId", "MemberType", "MemberDisplayName", "MemberUPN", "MemberMail"],
    )
    write_csv(
        output_dir / "identity-group-owners.csv",
        owners,
        ["GroupId", "GroupDisplayName", "OwnerId", "OwnerType", "OwnerDisplayName", "OwnerUPN", "OwnerMail"],
    )
    write_csv(output_dir / "identity-group-counts.csv", group_counts, ["GroupId", "GroupDisplayName", "MemberCount", "OwnerCount"])
    write_csv(output_dir / "identity-directory-roles.csv", roles, ["id", "displayName", "description", "roleTemplateId", "memberCount"])
    write_csv(
        output_dir / "identity-directory-role-members.csv",
        role_members,
        ["RoleId", "RoleDisplayName", "MemberId", "MemberType", "MemberDisplayName", "MemberUPN", "MemberMail"],
    )
    (output_dir / "identity-summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")
    write_summary(output_dir / "identity-summary.md", summary)

    log(f"Wrote identity inventory outputs to {output_dir}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read-only Delta Crown identity inventory")
    parser.add_argument("--tenant-id", default=DEFAULT_TENANT_ID)
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    return parser.parse_args()


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args()))
    except Exception as exc:  # noqa: BLE001 - command-line script should report cleanly
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
