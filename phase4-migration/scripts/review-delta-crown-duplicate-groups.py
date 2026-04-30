#!/usr/bin/env python3
"""Read-only review for duplicate 'Delta Crown Extensions' M365 groups.

The script writes raw group/member evidence to .local only and emits a safe
summary suitable for documentation. It performs Graph GET requests only.
"""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
import time
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests

GRAPH_BASE = "https://graph.microsoft.com/v1.0"
DEFAULT_TENANT_ID = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
DEFAULT_OUTPUT_DIR = ".local/reports/tenant-inventory/duplicate-delta-crown-groups"
DUPLICATE_DISPLAY_NAME = "Delta Crown Extensions"

GROUP_SELECT = ",".join(
    [
        "id",
        "displayName",
        "mail",
        "mailNickname",
        "description",
        "createdDateTime",
        "renewedDateTime",
        "groupTypes",
        "securityEnabled",
        "mailEnabled",
        "visibility",
        "resourceProvisioningOptions",
        "onPremisesSyncEnabled",
    ]
)

PERSON_SELECT = "id,displayName,userPrincipalName,userType,companyName,department,jobTitle,accountEnabled"
SITE_SELECT = "id,displayName,name,webUrl,createdDateTime,lastModifiedDateTime"
LIST_SELECT = "id,displayName,name,webUrl,list,createdDateTime,lastModifiedDateTime"


@dataclass(frozen=True)
class GraphContext:
    token: str

    @property
    def headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.token}", "Accept": "application/json"}


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


def graph_get(ctx: GraphContext, url: str, params: dict[str, str] | None = None) -> tuple[int, dict[str, Any]]:
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


def graph_get_all(ctx: GraphContext, url: str, params: dict[str, str] | None = None) -> tuple[list[dict[str, Any]], str]:
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


def normalize(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (list, dict)):
        return json.dumps(value, sort_keys=True)
    return str(value)


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: normalize(row.get(field, "")) for field in fieldnames})


def summarize_people(rows: list[dict[str, Any]]) -> dict[str, Any]:
    user_types = Counter(row.get("userType") or "Unknown" for row in rows)
    companies = Counter(row.get("companyName") or "Missing" for row in rows)
    departments = Counter(row.get("department") or "Missing" for row in rows)
    job_titles_populated = sum(1 for row in rows if row.get("jobTitle"))
    disabled = sum(1 for row in rows if row.get("accountEnabled") is False)
    return {
        "count": len(rows),
        "user_types": dict(sorted(user_types.items())),
        "company_top_counts": dict(companies.most_common(8)),
        "department_top_counts": dict(departments.most_common(8)),
        "job_title_populated_count": job_titles_populated,
        "disabled_count": disabled,
    }


def list_item_count(row: dict[str, Any]) -> int | None:
    list_info = row.get("list") or {}
    if isinstance(list_info, dict):
        return list_info.get("itemCount")
    return None


def collect(ctx: GraphContext) -> dict[str, Any]:
    groups, group_error = graph_get_all(
        ctx,
        f"{GRAPH_BASE}/groups",
        {"$filter": f"displayName eq '{DUPLICATE_DISPLAY_NAME}'", "$select": GROUP_SELECT, "$top": "999"},
    )
    details: list[dict[str, Any]] = []
    for group in groups:
        group_id = group["id"]
        log(f"Reviewing group {group.get('mail')} / {group_id}")
        members, members_error = graph_get_all(
            ctx,
            f"{GRAPH_BASE}/groups/{group_id}/members",
            {"$select": PERSON_SELECT, "$top": "999"},
        )
        owners, owners_error = graph_get_all(
            ctx,
            f"{GRAPH_BASE}/groups/{group_id}/owners",
            {"$select": PERSON_SELECT, "$top": "999"},
        )
        site_status, site = graph_get(
            ctx,
            f"{GRAPH_BASE}/groups/{group_id}/sites/root",
            {"$select": SITE_SELECT},
        )
        lists: list[dict[str, Any]] = []
        lists_error = ""
        if site_status < 400:
            lists, lists_error = graph_get_all(
                ctx,
                f"{GRAPH_BASE}/sites/{site['id']}/lists",
                {"$select": LIST_SELECT, "$top": "999"},
            )
        details.append(
            {
                "group": group,
                "members": members,
                "members_error": members_error,
                "owners": owners,
                "owners_error": owners_error,
                "site_status": site_status,
                "site": site,
                "lists": lists,
                "lists_error": lists_error,
            }
        )
    return {"groups": groups, "group_error": group_error, "details": details}


def summarize(data: dict[str, Any]) -> dict[str, Any]:
    details = data["details"]
    member_sets = [set(row["id"] for row in detail["members"]) for detail in details]
    owner_sets = [set(row["id"] for row in detail["owners"]) for detail in details]
    member_overlap = len(set.intersection(*member_sets)) if len(member_sets) >= 2 else 0
    owner_overlap = len(set.intersection(*owner_sets)) if len(owner_sets) >= 2 else 0

    group_summaries: list[dict[str, Any]] = []
    for detail in details:
        group = detail["group"]
        site = detail["site"] if detail["site_status"] < 400 else {}
        lists = detail["lists"]
        visible_lists = [row for row in lists if not (row.get("list") or {}).get("hidden")]
        group_summaries.append(
            {
                "id": group.get("id"),
                "display_name": group.get("displayName"),
                "mail": group.get("mail"),
                "mail_nickname": group.get("mailNickname"),
                "created": group.get("createdDateTime"),
                "renewed": group.get("renewedDateTime"),
                "visibility": group.get("visibility"),
                "resource_provisioning_options": group.get("resourceProvisioningOptions") or [],
                "security_enabled": group.get("securityEnabled"),
                "mail_enabled": group.get("mailEnabled"),
                "member_summary": summarize_people(detail["members"]),
                "owner_summary": summarize_people(detail["owners"]),
                "site_status": detail["site_status"],
                "site_url": site.get("webUrl", ""),
                "site_created": site.get("createdDateTime", ""),
                "site_last_modified": site.get("lastModifiedDateTime", ""),
                "visible_list_count": len(visible_lists),
                "document_library_item_counts": {
                    row.get("displayName", ""): list_item_count(row)
                    for row in visible_lists
                    if (row.get("list") or {}).get("template") == "documentLibrary"
                },
            }
        )
    return {
        "generated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "duplicate_display_name": DUPLICATE_DISPLAY_NAME,
        "duplicate_count": len(details),
        "member_overlap_count": member_overlap,
        "owner_overlap_count": owner_overlap,
        "groups": group_summaries,
        "recommendations": [
            "Treat both groups as active until Teams/channel dependencies are readable or owner-attested.",
            "Do not delete either group or connected site based only on display-name duplication.",
            "Rename only after owner approval and Teams dependency review to reduce navigation ambiguity.",
        ],
    }


def write_raw(output_dir: Path, data: dict[str, Any], summary: dict[str, Any]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "duplicate-groups-summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")
    write_csv(
        output_dir / "duplicate-groups.csv",
        [detail["group"] for detail in data["details"]],
        GROUP_SELECT.split(","),
    )
    for detail in data["details"]:
        safe_name = (detail["group"].get("mailNickname") or detail["group"]["id"]).replace("/", "-")
        write_csv(output_dir / f"{safe_name}-members.csv", detail["members"], PERSON_SELECT.split(","))
        write_csv(output_dir / f"{safe_name}-owners.csv", detail["owners"], PERSON_SELECT.split(","))
        write_csv(output_dir / f"{safe_name}-lists.csv", detail["lists"], LIST_SELECT.split(","))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Review duplicate Delta Crown Extensions M365 groups")
    parser.add_argument("--tenant-id", default=DEFAULT_TENANT_ID)
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    return parser.parse_args()


def run(args: argparse.Namespace) -> int:
    ctx = GraphContext(get_az_graph_token(args.tenant_id))
    data = collect(ctx)
    summary = summarize(data)
    write_raw(Path(args.output_dir), data, summary)
    log(f"Wrote duplicate-group review outputs to {args.output_dir}")
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args()))
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
