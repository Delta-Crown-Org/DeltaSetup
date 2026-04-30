#!/usr/bin/env python3
"""Read-only Delta Crown SharePoint/OneDrive inventory via Microsoft Graph.

Uses the current Azure CLI login to obtain a Graph token for the Delta Crown
tenant. Because tenant-wide site search may be denied, this inventories known
Delta Crown site paths plus group-connected root sites. Raw outputs are
local-only by default. Do not commit raw outputs.
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
DEFAULT_HOSTNAME = "deltacrown.sharepoint.com"
DEFAULT_OUTPUT_DIR = ".local/reports/tenant-inventory/sharepoint"
KNOWN_SITE_PATHS = [
    "/",
    "/sites/corp-hub",
    "/sites/corp-hr",
    "/sites/corp-it",
    "/sites/corp-finance",
    "/sites/corp-training",
    "/sites/dce-hub",
    "/sites/dce-operations",
    "/sites/dce-clientservices",
    "/sites/dce-marketing",
    "/sites/dce-docs",
]
RISK_LIST_NAMES = {"Client Records", "Service History", "Feedback"}
RISK_LIBRARY_NAMES = {"Consent Forms"}


@dataclass(frozen=True)
class GraphContext:
    token: str
    tenant_id: str
    hostname: str

    @property
    def headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }


def log(message: str) -> None:
    print(f"[{datetime.now(timezone.utc).isoformat(timespec='seconds')}] {message}")


def normalize(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, list):
        return ";".join(str(item) for item in value)
    if isinstance(value, dict):
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


def graph_get_optional(ctx: GraphContext, url: str, params: dict[str, Any] | None = None) -> tuple[dict[str, Any] | None, str]:
    try:
        return graph_get(ctx, url, params), ""
    except RuntimeError as exc:
        return None, str(exc)


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


def graph_get_all_optional(ctx: GraphContext, url: str, params: dict[str, Any] | None = None) -> tuple[list[dict[str, Any]], str]:
    try:
        return graph_get_all(ctx, url, params), ""
    except RuntimeError as exc:
        return [], str(exc)


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: normalize(row.get(field, "")) for field in fieldnames})


def site_lookup_url(ctx: GraphContext, path: str) -> str:
    if path == "/":
        return f"{GRAPH_BASE}/sites/{ctx.hostname}:/"
    return f"{GRAPH_BASE}/sites/{ctx.hostname}:{path}"


def collect_known_sites(ctx: GraphContext, paths: list[str]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    sites: list[dict[str, Any]] = []
    failures: list[dict[str, Any]] = []
    seen_ids: set[str] = set()

    for path in paths:
        log(f"Looking up site path: {path}")
        data, error = graph_get_optional(ctx, site_lookup_url(ctx, path))
        if error or not data:
            failures.append({"Path": path, "Error": error})
            continue
        site_id = data.get("id", "")
        if site_id in seen_ids:
            continue
        seen_ids.add(site_id)
        data["inventorySource"] = "known-path"
        data["requestedPath"] = path
        sites.append(data)
    return sites, failures


def collect_group_sites(ctx: GraphContext, known_site_ids: set[str]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    groups = graph_get_all(
        ctx,
        f"{GRAPH_BASE}/groups",
        {"$select": "id,displayName,mail,groupTypes", "$top": "999"},
    )
    sites: list[dict[str, Any]] = []
    failures: list[dict[str, Any]] = []
    for group in groups:
        group_types = group.get("groupTypes") or []
        if "Unified" not in group_types:
            continue
        group_id = group["id"]
        log(f"Looking up group-connected site: {group.get('displayName')}")
        data, error = graph_get_optional(ctx, f"{GRAPH_BASE}/groups/{group_id}/sites/root")
        if error or not data:
            failures.append({"GroupId": group_id, "GroupDisplayName": group.get("displayName", ""), "Error": error})
            continue
        site_id = data.get("id", "")
        if site_id in known_site_ids:
            continue
        data["inventorySource"] = "group-root-site"
        data["groupId"] = group_id
        data["groupDisplayName"] = group.get("displayName", "")
        data["groupMail"] = group.get("mail", "")
        sites.append(data)
        known_site_ids.add(site_id)
    return sites, failures


def collect_site_details(ctx: GraphContext, sites: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    site_rows: list[dict[str, Any]] = []
    drive_rows: list[dict[str, Any]] = []
    list_rows: list[dict[str, Any]] = []
    column_rows: list[dict[str, Any]] = []
    errors: list[dict[str, Any]] = []

    for site in sites:
        site_id = site.get("id", "")
        site_name = site.get("displayName", "") or site.get("name", "")
        web_url = site.get("webUrl", "")
        log(f"Inventorying site details: {web_url}")
        site_rows.append(
            {
                "SiteId": site_id,
                "DisplayName": site_name,
                "Name": site.get("name", ""),
                "WebUrl": web_url,
                "Description": site.get("description", ""),
                "CreatedDateTime": site.get("createdDateTime", ""),
                "LastModifiedDateTime": site.get("lastModifiedDateTime", ""),
                "InventorySource": site.get("inventorySource", ""),
                "RequestedPath": site.get("requestedPath", ""),
                "GroupId": site.get("groupId", ""),
                "GroupDisplayName": site.get("groupDisplayName", ""),
                "GroupMail": site.get("groupMail", ""),
            }
        )

        drives, drive_error = graph_get_all_optional(
            ctx,
            f"{GRAPH_BASE}/sites/{site_id}/drives",
            {"$select": "id,name,description,driveType,webUrl,createdDateTime,lastModifiedDateTime,quota", "$top": "999"},
        )
        if drive_error:
            errors.append({"Scope": "drives", "SiteId": site_id, "SiteUrl": web_url, "Error": drive_error})
        for drive in drives:
            quota = drive.get("quota") or {}
            drive_rows.append(
                {
                    "SiteId": site_id,
                    "SiteDisplayName": site_name,
                    "SiteUrl": web_url,
                    "DriveId": drive.get("id", ""),
                    "Name": drive.get("name", ""),
                    "Description": drive.get("description", ""),
                    "DriveType": drive.get("driveType", ""),
                    "WebUrl": drive.get("webUrl", ""),
                    "CreatedDateTime": drive.get("createdDateTime", ""),
                    "LastModifiedDateTime": drive.get("lastModifiedDateTime", ""),
                    "QuotaUsed": quota.get("used", ""),
                    "QuotaTotal": quota.get("total", ""),
                    "IsRiskLibraryName": drive.get("name", "") in RISK_LIBRARY_NAMES,
                }
            )

        lists, list_error = graph_get_all_optional(
            ctx,
            f"{GRAPH_BASE}/sites/{site_id}/lists",
            {"$select": "id,displayName,name,webUrl,createdDateTime,lastModifiedDateTime,list", "$top": "999"},
        )
        if list_error:
            errors.append({"Scope": "lists", "SiteId": site_id, "SiteUrl": web_url, "Error": list_error})
        for list_item in lists:
            list_id = list_item.get("id", "")
            display_name = list_item.get("displayName", "")
            list_meta = list_item.get("list") or {}
            is_risk = display_name in RISK_LIST_NAMES or display_name in RISK_LIBRARY_NAMES
            list_rows.append(
                {
                    "SiteId": site_id,
                    "SiteDisplayName": site_name,
                    "SiteUrl": web_url,
                    "ListId": list_id,
                    "DisplayName": display_name,
                    "Name": list_item.get("name", ""),
                    "WebUrl": list_item.get("webUrl", ""),
                    "Template": list_meta.get("template", ""),
                    "Hidden": list_meta.get("hidden", ""),
                    "ContentTypesEnabled": list_meta.get("contentTypesEnabled", ""),
                    "CreatedDateTime": list_item.get("createdDateTime", ""),
                    "LastModifiedDateTime": list_item.get("lastModifiedDateTime", ""),
                    "IsRiskListName": is_risk,
                }
            )
            columns, column_error = graph_get_all_optional(
                ctx,
                f"{GRAPH_BASE}/sites/{site_id}/lists/{list_id}/columns",
                {"$select": "id,name,displayName,description,hidden,readOnly,required,columnGroup", "$top": "999"},
            )
            if column_error:
                errors.append({"Scope": "columns", "SiteId": site_id, "SiteUrl": web_url, "ListName": display_name, "Error": column_error})
            for column in columns:
                column_rows.append(
                    {
                        "SiteId": site_id,
                        "SiteDisplayName": site_name,
                        "SiteUrl": web_url,
                        "ListId": list_id,
                        "ListDisplayName": display_name,
                        "ColumnId": column.get("id", ""),
                        "Name": column.get("name", ""),
                        "DisplayName": column.get("displayName", ""),
                        "Description": column.get("description", ""),
                        "Hidden": column.get("hidden", ""),
                        "ReadOnly": column.get("readOnly", ""),
                        "Required": column.get("required", ""),
                        "ColumnGroup": column.get("columnGroup", ""),
                        "IsRiskListName": is_risk,
                    }
                )
    return site_rows, drive_rows, list_rows, column_rows, errors


def summarize(site_rows: list[dict[str, Any]], drive_rows: list[dict[str, Any]], list_rows: list[dict[str, Any]], column_rows: list[dict[str, Any]], lookup_failures: list[dict[str, Any]], errors: list[dict[str, Any]]) -> dict[str, Any]:
    risk_lists = [row for row in list_rows if str(row.get("IsRiskListName")) == "True"]
    risk_drives = [row for row in drive_rows if str(row.get("IsRiskLibraryName")) == "True"]
    clientservices_sites = [row for row in site_rows if "dce-clientservices" in row.get("WebUrl", "").lower()]
    brand_resources_named = [row for row in site_rows + drive_rows + list_rows if "brand resources" in (row.get("DisplayName", "") or row.get("Name", "")).lower()]
    return {
        "generated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "site_count": len(site_rows),
        "drive_count": len(drive_rows),
        "list_count": len(list_rows),
        "column_count": len(column_rows),
        "lookup_failure_count": len(lookup_failures),
        "detail_error_count": len(errors),
        "clientservices_site_count": len(clientservices_sites),
        "risk_list_count": len(risk_lists),
        "risk_drive_count": len(risk_drives),
        "brand_resources_named_count": len(brand_resources_named),
        "sites": site_rows,
        "risk_lists": risk_lists,
        "risk_drives": risk_drives,
        "lookup_failures": lookup_failures,
        "errors": errors,
    }


def write_summary(path: Path, summary: dict[str, Any]) -> None:
    lines = [
        "# Delta Crown SharePoint Inventory Summary",
        "",
        f"Generated: {summary['generated']}",
        "Tenant: deltacrown.com / ce62e17d-2feb-4e67-a115-8ea4af68da30",
        "",
        "## Totals",
        "",
        f"- Sites inventoried: {summary['site_count']}",
        f"- Document libraries/drives inventoried: {summary['drive_count']}",
        f"- Lists inventoried: {summary['list_count']}",
        f"- List/library columns inventoried: {summary['column_count']}",
        f"- Known site lookup failures: {summary['lookup_failure_count']}",
        f"- Detail read errors: {summary['detail_error_count']}",
        f"- `/sites/dce-clientservices` sites found: {summary['clientservices_site_count']}",
        f"- Risk-named lists found: {summary['risk_list_count']}",
        f"- Risk-named libraries found: {summary['risk_drive_count']}",
        f"- Brand Resources named site/list/library objects found: {summary['brand_resources_named_count']}",
        "",
        "## Sites",
        "",
        "| Site | URL | Source | Group |",
        "|---|---|---|---|",
    ]
    for site in sorted(summary["sites"], key=lambda row: row.get("WebUrl", "")):
        lines.append(
            f"| {site.get('DisplayName', '')} | {site.get('WebUrl', '')} | "
            f"{site.get('InventorySource', '')} | {site.get('GroupDisplayName', '')} |"
        )

    lines.extend(["", "## Risk-named lists/libraries", "", "| Type | Name | Site | URL |", "|---|---|---|---|"])
    for row in summary["risk_lists"]:
        lines.append(f"| List | {row.get('DisplayName', '')} | {row.get('SiteDisplayName', '')} | {row.get('WebUrl', '')} |")
    for row in summary["risk_drives"]:
        lines.append(f"| Library | {row.get('Name', '')} | {row.get('SiteDisplayName', '')} | {row.get('WebUrl', '')} |")

    if summary["lookup_failures"]:
        lines.extend(["", "## Known site lookup failures", "", "| Path/group | Error summary |", "|---|---|"])
        for row in summary["lookup_failures"]:
            key = row.get("Path") or row.get("GroupDisplayName") or row.get("GroupId")
            error = str(row.get("Error", "")).replace("|", "\\|")[:250]
            lines.append(f"| {key} | {error} |")

    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- This inventory used Microsoft Graph read calls through the current Azure CLI session.",
            "- Tenant-wide site search returned access denied, so the script inventoried known Delta Crown paths and group-connected root sites.",
            "- Raw CSV outputs are local-only and may contain IDs, URLs, list metadata, and schema details.",
            "- The script does not read list items, file contents, OneDrive file contents, or client records.",
            "- No SharePoint, OneDrive, group, permission, or tenant settings were changed.",
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run(args: argparse.Namespace) -> int:
    output_dir = Path(args.output_dir)
    ctx = GraphContext(token=get_az_graph_token(args.tenant_id), tenant_id=args.tenant_id, hostname=args.hostname)
    paths = args.site_path or KNOWN_SITE_PATHS

    known_sites, known_failures = collect_known_sites(ctx, paths)
    group_sites, group_failures = collect_group_sites(ctx, {site.get("id", "") for site in known_sites})
    site_rows, drive_rows, list_rows, column_rows, detail_errors = collect_site_details(ctx, known_sites + group_sites)
    lookup_failures = known_failures + group_failures
    summary = summarize(site_rows, drive_rows, list_rows, column_rows, lookup_failures, detail_errors)

    write_csv(output_dir / "sharepoint-sites.csv", site_rows, ["SiteId", "DisplayName", "Name", "WebUrl", "Description", "CreatedDateTime", "LastModifiedDateTime", "InventorySource", "RequestedPath", "GroupId", "GroupDisplayName", "GroupMail"])
    write_csv(output_dir / "sharepoint-drives.csv", drive_rows, ["SiteId", "SiteDisplayName", "SiteUrl", "DriveId", "Name", "Description", "DriveType", "WebUrl", "CreatedDateTime", "LastModifiedDateTime", "QuotaUsed", "QuotaTotal", "IsRiskLibraryName"])
    write_csv(output_dir / "sharepoint-lists.csv", list_rows, ["SiteId", "SiteDisplayName", "SiteUrl", "ListId", "DisplayName", "Name", "WebUrl", "Template", "Hidden", "ContentTypesEnabled", "CreatedDateTime", "LastModifiedDateTime", "IsRiskListName"])
    write_csv(output_dir / "sharepoint-list-columns.csv", column_rows, ["SiteId", "SiteDisplayName", "SiteUrl", "ListId", "ListDisplayName", "ColumnId", "Name", "DisplayName", "Description", "Hidden", "ReadOnly", "Required", "ColumnGroup", "IsRiskListName"])
    write_csv(output_dir / "sharepoint-inventory-errors.csv", lookup_failures + detail_errors, ["Path", "GroupId", "GroupDisplayName", "Scope", "SiteId", "SiteUrl", "ListName", "Error"])
    (output_dir / "sharepoint-summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")
    write_summary(output_dir / "sharepoint-summary.md", summary)
    log(f"Wrote SharePoint inventory outputs to {output_dir}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read-only Delta Crown SharePoint inventory")
    parser.add_argument("--tenant-id", default=DEFAULT_TENANT_ID)
    parser.add_argument("--hostname", default=DEFAULT_HOSTNAME)
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--site-path", action="append", help="Known site path to inventory; repeatable. Defaults to built-in Delta Crown paths.")
    return parser.parse_args()


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args()))
    except Exception as exc:  # noqa: BLE001 - command-line script should report cleanly
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
