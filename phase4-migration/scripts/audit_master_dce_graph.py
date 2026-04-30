#!/usr/bin/env python3
"""Read-only Graph audit for HTTHQ / Shared Documents / Master DCE.

This script uses the current Azure CLI login to obtain a Microsoft Graph token.
It writes raw outputs to .local by default. Do not commit raw outputs without
review/redaction/owner approval.
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
from urllib.parse import quote

import requests

GRAPH_BASE = "https://graph.microsoft.com/v1.0"
DEFAULT_SITE_HOST = "httbrands.sharepoint.com"
DEFAULT_SITE_PATH = "/sites/HTTHQ"
DEFAULT_LIBRARY_NAMES = ("Documents", "Shared Documents")
DEFAULT_ROOT_FOLDER = "Master DCE"
DEFAULT_OUTPUT_DIR = ".local/reports/master-dce"


@dataclass(frozen=True)
class GraphContext:
    token: str
    site_host: str
    site_path: str

    @property
    def headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }


def log(message: str) -> None:
    print(f"[{datetime.now(timezone.utc).isoformat(timespec='seconds')}] {message}")


def get_az_graph_token() -> str:
    result = subprocess.run(
        [
            "az",
            "account",
            "get-access-token",
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

    payload = json.loads(result.stdout)
    token = payload.get("accessToken")
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
    items: list[dict[str, Any]] = []
    next_url: str | None = url
    next_params = params
    while next_url:
        data = graph_get(ctx, next_url, next_params)
        items.extend(data.get("value", []))
        next_url = data.get("@odata.nextLink")
        next_params = None
    return items


def get_site(ctx: GraphContext) -> dict[str, Any]:
    site_ref = f"{ctx.site_host}:{ctx.site_path}"
    url = f"{GRAPH_BASE}/sites/{site_ref}"
    site = graph_get(ctx, url)
    web_url = site.get("webUrl", "")
    expected_prefix = f"https://{ctx.site_host}{ctx.site_path}"
    if not web_url.startswith(expected_prefix):
        raise RuntimeError(f"Connected site {web_url!r} does not match expected {expected_prefix!r}")
    return site


def choose_drive(ctx: GraphContext, site_id: str, preferred_names: tuple[str, ...]) -> dict[str, Any]:
    drives = graph_get_all(ctx, f"{GRAPH_BASE}/sites/{site_id}/drives")
    for name in preferred_names:
        for drive in drives:
            if drive.get("name") == name:
                return drive
    names = ", ".join(sorted(d.get("name", "<unnamed>") for d in drives))
    raise RuntimeError(f"Could not find preferred document library {preferred_names}; available: {names}")


def get_folder_item(ctx: GraphContext, drive_id: str, folder_path: str) -> dict[str, Any]:
    encoded_path = quote(folder_path.strip("/"), safe="/")
    return graph_get(ctx, f"{GRAPH_BASE}/drives/{drive_id}/root:/{encoded_path}")


def get_children(ctx: GraphContext, drive_id: str, item_id: str) -> list[dict[str, Any]]:
    return graph_get_all(
        ctx,
        f"{GRAPH_BASE}/drives/{drive_id}/items/{item_id}/children",
        {
            "$select": "id,name,folder,file,size,createdDateTime,lastModifiedDateTime,webUrl,parentReference,createdBy,lastModifiedBy",
            "$top": "200",
        },
    )


def get_permissions(ctx: GraphContext, drive_id: str, item_id: str) -> list[dict[str, Any]]:
    try:
        return graph_get_all(ctx, f"{GRAPH_BASE}/drives/{drive_id}/items/{item_id}/permissions")
    except RuntimeError as error:
        log(f"Permission read failed for item {item_id}: {error}")
        return []


def actor_name(actor: dict[str, Any] | None) -> str:
    if not actor:
        return ""
    user = actor.get("user") or {}
    application = actor.get("application") or {}
    return user.get("displayName") or user.get("email") or application.get("displayName") or ""


def permission_principal(permission: dict[str, Any]) -> str:
    granted = permission.get("grantedTo") or {}
    identities = permission.get("grantedToIdentitiesV2") or permission.get("grantedToIdentities") or []
    link = permission.get("link") or {}
    invitation = permission.get("invitation") or {}

    if granted:
        user = granted.get("user") or {}
        app = granted.get("application") or {}
        group = granted.get("group") or {}
        site_group = granted.get("siteGroup") or {}
        return (
            user.get("email")
            or user.get("displayName")
            or group.get("displayName")
            or site_group.get("displayName")
            or app.get("displayName")
            or ""
        )
    if identities:
        names = []
        for identity in identities:
            user = identity.get("user") or {}
            group = identity.get("group") or {}
            names.append(user.get("email") or user.get("displayName") or group.get("displayName") or "")
        return "; ".join(name for name in names if name)
    if link:
        return f"sharing-link:{link.get('scope', 'unknown')}:{link.get('type', 'unknown')}"
    return invitation.get("email") or ""


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fieldnames})


def write_summary(path: Path, site: dict[str, Any], drive: dict[str, Any], root: dict[str, Any], inventory: list[dict[str, Any]], permissions: list[dict[str, Any]]) -> None:
    unique_like = [row for row in permissions if row.get("InheritedFrom") == ""]
    sharing_links = [row for row in permissions if str(row.get("Principal", "")).startswith("sharing-link:")]
    generated = datetime.now(timezone.utc).isoformat(timespec="seconds")

    lines = [
        "# Master DCE Graph Audit Summary",
        "",
        f"Generated: {generated}",
        f"Site: {site.get('webUrl')}",
        f"Library/drive: {drive.get('name')}",
        f"Root folder: {root.get('name')}",
        "",
        "## Totals",
        "",
        f"- Top-level items scanned: {len(inventory)}",
        f"- Top-level folders: {sum(1 for row in inventory if row.get('ItemType') == 'Folder')}",
        f"- Top-level files: {sum(1 for row in inventory if row.get('ItemType') == 'File')}",
        f"- Permission rows visible through Graph: {len(permissions)}",
        f"- Permission rows without inheritedFrom marker: {len(unique_like)}",
        f"- Sharing link rows: {len(sharing_links)}",
        "",
        "## Top-Level Inventory",
        "",
        "| Name | Type | Direct files | Direct folders | Modified | Modified by |",
        "|---|---|---:|---:|---|---|",
    ]
    for row in sorted(inventory, key=lambda item: item.get("Name", "")):
        lines.append(
            f"| {row.get('Name')} | {row.get('ItemType')} | {row.get('DirectFileCount')} | "
            f"{row.get('DirectFolderCount')} | {row.get('LastModifiedDateTime')} | {row.get('LastModifiedBy')} |"
        )

    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- This audit used Microsoft Graph via the current Azure CLI login.",
            "- Raw CSV outputs are local-only and should not be committed without review/redaction.",
            "- Graph permission data may differ from SharePoint/PnP role assignment detail; use it as audit evidence, not as a cleanup script.",
            "- No tenant writes, file operations, or permission changes were performed.",
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run(args: argparse.Namespace) -> int:
    ctx = GraphContext(
        token=get_az_graph_token(),
        site_host=args.site_host,
        site_path=args.site_path,
    )
    output_dir = Path(args.output_dir)
    log("Looking up HTTHQ site")
    site = get_site(ctx)
    log(f"Connected to verified site: {site.get('webUrl')}")

    drive = choose_drive(ctx, site["id"], tuple(args.library_name))
    log(f"Using drive/library: {drive.get('name')}")

    root = get_folder_item(ctx, drive["id"], args.root_folder)
    if "folder" not in root:
        raise RuntimeError(f"Root path {args.root_folder!r} is not a folder")
    log(f"Found root folder: {root.get('webUrl')}")

    children = get_children(ctx, drive["id"], root["id"])
    inventory: list[dict[str, Any]] = []
    permissions: list[dict[str, Any]] = []

    for item in children:
        item_type = "Folder" if "folder" in item else "File"
        direct_files = ""
        direct_folders = ""
        if item_type == "Folder":
            subchildren = get_children(ctx, drive["id"], item["id"])
            direct_files = sum(1 for child in subchildren if "file" in child)
            direct_folders = sum(1 for child in subchildren if "folder" in child)

        inventory.append(
            {
                "Name": item.get("name"),
                "ItemType": item_type,
                "Id": item.get("id"),
                "WebUrl": item.get("webUrl"),
                "Size": item.get("size", ""),
                "CreatedDateTime": item.get("createdDateTime", ""),
                "LastModifiedDateTime": item.get("lastModifiedDateTime", ""),
                "CreatedBy": actor_name(item.get("createdBy")),
                "LastModifiedBy": actor_name(item.get("lastModifiedBy")),
                "DirectFileCount": direct_files,
                "DirectFolderCount": direct_folders,
            }
        )

        for permission in get_permissions(ctx, drive["id"], item["id"]):
            inherited = permission.get("inheritedFrom") or {}
            link = permission.get("link") or {}
            permissions.append(
                {
                    "PathName": item.get("name"),
                    "ItemType": item_type,
                    "PermissionId": permission.get("id"),
                    "Roles": "; ".join(permission.get("roles", [])),
                    "Principal": permission_principal(permission),
                    "LinkScope": link.get("scope", ""),
                    "LinkType": link.get("type", ""),
                    "InheritedFrom": inherited.get("path", "") or inherited.get("id", ""),
                }
            )

    write_csv(
        output_dir / "master-dce-folder-inventory.csv",
        inventory,
        [
            "Name",
            "ItemType",
            "Id",
            "WebUrl",
            "Size",
            "CreatedDateTime",
            "LastModifiedDateTime",
            "CreatedBy",
            "LastModifiedBy",
            "DirectFileCount",
            "DirectFolderCount",
        ],
    )
    write_csv(
        output_dir / "master-dce-permissions.csv",
        permissions,
        ["PathName", "ItemType", "PermissionId", "Roles", "Principal", "LinkScope", "LinkType", "InheritedFrom"],
    )
    write_summary(output_dir / "master-dce-summary.md", site, drive, root, inventory, permissions)

    log(f"Inventory written: {output_dir / 'master-dce-folder-inventory.csv'}")
    log(f"Permissions written: {output_dir / 'master-dce-permissions.csv'}")
    log(f"Summary written: {output_dir / 'master-dce-summary.md'}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read-only Graph audit for HTTHQ Master DCE")
    parser.add_argument("--site-host", default=DEFAULT_SITE_HOST)
    parser.add_argument("--site-path", default=DEFAULT_SITE_PATH)
    parser.add_argument("--library-name", action="append", default=list(DEFAULT_LIBRARY_NAMES))
    parser.add_argument("--root-folder", default=DEFAULT_ROOT_FOLDER)
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    return parser.parse_args()


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args()))
    except Exception as exc:  # noqa: BLE001 - command-line script should report cleanly
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
