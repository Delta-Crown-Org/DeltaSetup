#!/usr/bin/env python3
"""Read-only Delta Crown security/apps/licenses inventory via Microsoft Graph.

Uses the current Azure CLI login to obtain a Graph token for the Delta Crown
tenant. Raw outputs are local-only by default and may contain app IDs, service
principal IDs, credential metadata, consent grants, and assigned license rows.
Do not commit raw outputs.
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
DEFAULT_OUTPUT_DIR = ".local/reports/tenant-inventory/security-apps"


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


def normalize(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, list):
        return json.dumps(value, sort_keys=True)
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


def count_credentials(rows: list[dict[str, Any]]) -> tuple[int, int]:
    password_count = 0
    key_count = 0
    for row in rows:
        password_count += len(row.get("passwordCredentials") or [])
        key_count += len(row.get("keyCredentials") or [])
    return password_count, key_count


def flatten_application_credentials(applications: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for app in applications:
        for credential in app.get("passwordCredentials") or []:
            rows.append(
                {
                    "ObjectType": "application",
                    "ObjectId": app.get("id", ""),
                    "DisplayName": app.get("displayName", ""),
                    "AppId": app.get("appId", ""),
                    "CredentialType": "password",
                    "KeyId": credential.get("keyId", ""),
                    "DisplayNameCredential": credential.get("displayName", ""),
                    "StartDateTime": credential.get("startDateTime", ""),
                    "EndDateTime": credential.get("endDateTime", ""),
                }
            )
        for credential in app.get("keyCredentials") or []:
            rows.append(
                {
                    "ObjectType": "application",
                    "ObjectId": app.get("id", ""),
                    "DisplayName": app.get("displayName", ""),
                    "AppId": app.get("appId", ""),
                    "CredentialType": "key",
                    "KeyId": credential.get("keyId", ""),
                    "DisplayNameCredential": credential.get("displayName", ""),
                    "StartDateTime": credential.get("startDateTime", ""),
                    "EndDateTime": credential.get("endDateTime", ""),
                }
            )
    return rows


def flatten_sp_credentials(service_principals: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for sp in service_principals:
        for credential in sp.get("passwordCredentials") or []:
            rows.append(
                {
                    "ObjectType": "servicePrincipal",
                    "ObjectId": sp.get("id", ""),
                    "DisplayName": sp.get("displayName", ""),
                    "AppId": sp.get("appId", ""),
                    "CredentialType": "password",
                    "KeyId": credential.get("keyId", ""),
                    "DisplayNameCredential": credential.get("displayName", ""),
                    "StartDateTime": credential.get("startDateTime", ""),
                    "EndDateTime": credential.get("endDateTime", ""),
                }
            )
        for credential in sp.get("keyCredentials") or []:
            rows.append(
                {
                    "ObjectType": "servicePrincipal",
                    "ObjectId": sp.get("id", ""),
                    "DisplayName": sp.get("displayName", ""),
                    "AppId": sp.get("appId", ""),
                    "CredentialType": "key",
                    "KeyId": credential.get("keyId", ""),
                    "DisplayNameCredential": credential.get("displayName", ""),
                    "StartDateTime": credential.get("startDateTime", ""),
                    "EndDateTime": credential.get("endDateTime", ""),
                }
            )
    return rows


def flatten_user_licenses(users: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for user in users:
        for license_row in user.get("assignedLicenses") or []:
            rows.append(
                {
                    "UserId": user.get("id", ""),
                    "DisplayName": user.get("displayName", ""),
                    "UserPrincipalName": user.get("userPrincipalName", ""),
                    "SkuId": license_row.get("skuId", ""),
                    "DisabledPlans": license_row.get("disabledPlans", []),
                }
            )
    return rows


def collect(ctx: GraphContext) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    errors: list[dict[str, Any]] = []
    data: dict[str, Any] = {}

    collection_specs = {
        "subscribed_skus": (f"{GRAPH_BASE}/subscribedSkus", None),
        "users_with_licenses": (
            f"{GRAPH_BASE}/users",
            {"$select": "id,displayName,userPrincipalName,assignedLicenses", "$top": "999"},
        ),
        "applications": (
            f"{GRAPH_BASE}/applications",
            {"$select": "id,appId,displayName,signInAudience,createdDateTime,passwordCredentials,keyCredentials", "$top": "999"},
        ),
        "service_principals": (
            f"{GRAPH_BASE}/servicePrincipals",
            {"$select": "id,appId,displayName,servicePrincipalType,accountEnabled,appOwnerOrganizationId,passwordCredentials,keyCredentials,tags", "$top": "999"},
        ),
        "oauth2_permission_grants": (
            f"{GRAPH_BASE}/oauth2PermissionGrants",
            {"$top": "999"},
        ),
        "conditional_access_policies": (
            f"{GRAPH_BASE}/identity/conditionalAccess/policies",
            None,
        ),
        "named_locations": (
            f"{GRAPH_BASE}/identity/conditionalAccess/namedLocations",
            None,
        ),
    }

    for key, (url, params) in collection_specs.items():
        log(f"Fetching {key}")
        rows, error = graph_get_all_optional(ctx, url, params)
        data[key] = rows
        if error:
            errors.append({"Scope": key, "Error": error})

    singleton_specs = {
        "authorization_policy": f"{GRAPH_BASE}/policies/authorizationPolicy",
        "identity_security_defaults": f"{GRAPH_BASE}/policies/identitySecurityDefaultsEnforcementPolicy",
        "authentication_methods_policy": f"{GRAPH_BASE}/policies/authenticationMethodsPolicy",
        "admin_consent_request_policy": f"{GRAPH_BASE}/policies/adminConsentRequestPolicy",
    }

    for key, url in singleton_specs.items():
        log(f"Fetching {key}")
        value, error = graph_get_optional(ctx, url)
        data[key] = value or {}
        if error:
            errors.append({"Scope": key, "Error": error})

    return data, errors


def sku_summary(skus: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for sku in skus:
        prepaid = sku.get("prepaidUnits") or {}
        consumed = sku.get("consumedUnits") or 0
        enabled = prepaid.get("enabled") or 0
        rows.append(
            {
                "SkuPartNumber": sku.get("skuPartNumber", ""),
                "SkuId": sku.get("skuId", ""),
                "ConsumedUnits": consumed,
                "EnabledUnits": enabled,
                "AvailableUnits": enabled - consumed,
                "SuspendedUnits": prepaid.get("suspended", 0),
                "WarningUnits": prepaid.get("warning", 0),
            }
        )
    return rows


def summarize(data: dict[str, Any], errors: list[dict[str, Any]]) -> dict[str, Any]:
    applications = data.get("applications") or []
    service_principals = data.get("service_principals") or []
    app_passwords, app_keys = count_credentials(applications)
    sp_passwords, sp_keys = count_credentials(service_principals)
    users = data.get("users_with_licenses") or []
    licensed_users = [user for user in users if user.get("assignedLicenses")]
    skus = sku_summary(data.get("subscribed_skus") or [])
    ca_policies = data.get("conditional_access_policies") or []
    ca_enabled = [row for row in ca_policies if row.get("state") == "enabled"]
    ca_report_only = [row for row in ca_policies if row.get("state") == "enabledForReportingButNotEnforced"]
    ca_disabled = [row for row in ca_policies if row.get("state") == "disabled"]
    security_defaults = data.get("identity_security_defaults") or {}
    auth_methods = data.get("authentication_methods_policy") or {}
    admin_consent = data.get("admin_consent_request_policy") or {}
    oauth_grants = data.get("oauth2_permission_grants") or []

    return {
        "generated": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "subscribed_sku_count": len(skus),
        "licensed_user_count": len(licensed_users),
        "application_count": len(applications),
        "service_principal_count": len(service_principals),
        "application_password_credential_count": app_passwords,
        "application_key_credential_count": app_keys,
        "service_principal_password_credential_count": sp_passwords,
        "service_principal_key_credential_count": sp_keys,
        "oauth2_permission_grant_count": len(oauth_grants),
        "conditional_access_policy_count": len(ca_policies),
        "conditional_access_enabled_count": len(ca_enabled),
        "conditional_access_report_only_count": len(ca_report_only),
        "conditional_access_disabled_count": len(ca_disabled),
        "named_location_count": len(data.get("named_locations") or []),
        "security_defaults_enabled": security_defaults.get("isEnabled", "unknown"),
        "authentication_methods_policy_state": auth_methods.get("policyVersion", "unknown"),
        "admin_consent_request_enabled": admin_consent.get("isEnabled", "unknown"),
        "skus": skus,
        "conditional_access_policies": [
            {
                "displayName": row.get("displayName", ""),
                "state": row.get("state", ""),
                "createdDateTime": row.get("createdDateTime", ""),
                "modifiedDateTime": row.get("modifiedDateTime", ""),
            }
            for row in ca_policies
        ],
        "errors": errors,
    }


def write_summary(path: Path, summary: dict[str, Any]) -> None:
    lines = [
        "# Delta Crown Security, Apps, and Licenses Inventory Summary",
        "",
        f"Generated: {summary['generated']}",
        "Tenant: deltacrown.com / ce62e17d-2feb-4e67-a115-8ea4af68da30",
        "",
        "## Totals",
        "",
        f"- Subscribed SKUs: {summary['subscribed_sku_count']}",
        f"- Licensed users: {summary['licensed_user_count']}",
        f"- App registrations: {summary['application_count']}",
        f"- Enterprise apps / service principals: {summary['service_principal_count']}",
        f"- Application password credentials: {summary['application_password_credential_count']}",
        f"- Application key credentials: {summary['application_key_credential_count']}",
        f"- Service principal password credentials: {summary['service_principal_password_credential_count']}",
        f"- Service principal key credentials: {summary['service_principal_key_credential_count']}",
        f"- OAuth2 permission grants: {summary['oauth2_permission_grant_count']}",
        f"- Conditional Access policies: {summary['conditional_access_policy_count']}",
        f"- Named locations: {summary['named_location_count']}",
        f"- Security defaults enabled: {summary['security_defaults_enabled']}",
        f"- Admin consent request enabled: {summary['admin_consent_request_enabled']}",
        "",
        "## Licenses",
        "",
        "| SKU | Enabled | Consumed | Available | Suspended | Warning |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for sku in sorted(summary["skus"], key=lambda row: row.get("SkuPartNumber", "")):
        lines.append(
            f"| {sku['SkuPartNumber']} | {sku['EnabledUnits']} | {sku['ConsumedUnits']} | "
            f"{sku['AvailableUnits']} | {sku['SuspendedUnits']} | {sku['WarningUnits']} |"
        )

    lines.extend(
        [
            "",
            "## Conditional Access",
            "",
            f"- Enabled: {summary['conditional_access_enabled_count']}",
            f"- Report-only: {summary['conditional_access_report_only_count']}",
            f"- Disabled: {summary['conditional_access_disabled_count']}",
            "",
            "| Policy | State | Modified |",
            "|---|---|---|",
        ]
    )
    for policy in sorted(summary["conditional_access_policies"], key=lambda row: row.get("displayName", "")):
        lines.append(f"| {policy['displayName']} | {policy['state']} | {policy.get('modifiedDateTime', '')} |")

    if summary["errors"]:
        lines.extend(["", "## Inventory limitations/errors", "", "| Scope | Error summary |", "|---|---|"])
        for error in summary["errors"]:
            error_text = str(error.get("Error", "")).replace("|", "\\|")[:300]
            lines.append(f"| {error.get('Scope', '')} | {error_text} |")

    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- Raw app IDs, service principal IDs, credential metadata, consent grants, and user license rows are local-only.",
            "- This script does not create, update, remove, or consent to any application or policy.",
            "- Purview DLP and sensitivity labels may require Compliance PowerShell/Purview roles beyond this Graph inventory.",
            "- No licenses, Conditional Access policies, apps, service principals, consent grants, or tenant settings were changed.",
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run(args: argparse.Namespace) -> int:
    output_dir = Path(args.output_dir)
    ctx = GraphContext(token=get_az_graph_token(args.tenant_id), tenant_id=args.tenant_id)
    data, errors = collect(ctx)

    applications = data.get("applications") or []
    service_principals = data.get("service_principals") or []
    user_license_rows = flatten_user_licenses(data.get("users_with_licenses") or [])
    app_credentials = flatten_application_credentials(applications)
    sp_credentials = flatten_sp_credentials(service_principals)
    summary = summarize(data, errors)

    write_csv(output_dir / "security-subscribed-skus.csv", sku_summary(data.get("subscribed_skus") or []), ["SkuPartNumber", "SkuId", "ConsumedUnits", "EnabledUnits", "AvailableUnits", "SuspendedUnits", "WarningUnits"])
    write_csv(output_dir / "security-user-license-assignments.csv", user_license_rows, ["UserId", "DisplayName", "UserPrincipalName", "SkuId", "DisabledPlans"])
    write_csv(output_dir / "security-applications.csv", applications, ["id", "appId", "displayName", "signInAudience", "createdDateTime", "passwordCredentials", "keyCredentials"])
    write_csv(output_dir / "security-service-principals.csv", service_principals, ["id", "appId", "displayName", "servicePrincipalType", "accountEnabled", "appOwnerOrganizationId", "passwordCredentials", "keyCredentials", "tags"])
    write_csv(output_dir / "security-application-credentials.csv", app_credentials, ["ObjectType", "ObjectId", "DisplayName", "AppId", "CredentialType", "KeyId", "DisplayNameCredential", "StartDateTime", "EndDateTime"])
    write_csv(output_dir / "security-service-principal-credentials.csv", sp_credentials, ["ObjectType", "ObjectId", "DisplayName", "AppId", "CredentialType", "KeyId", "DisplayNameCredential", "StartDateTime", "EndDateTime"])
    write_csv(output_dir / "security-oauth2-permission-grants.csv", data.get("oauth2_permission_grants") or [], ["id", "clientId", "consentType", "principalId", "resourceId", "scope"])
    write_csv(output_dir / "security-conditional-access-policies.csv", data.get("conditional_access_policies") or [], ["id", "displayName", "state", "createdDateTime", "modifiedDateTime", "conditions", "grantControls", "sessionControls"])
    write_csv(output_dir / "security-named-locations.csv", data.get("named_locations") or [], ["id", "displayName", "createdDateTime", "modifiedDateTime"])
    write_csv(output_dir / "security-inventory-errors.csv", errors, ["Scope", "Error"])
    (output_dir / "security-singleton-policies.json").write_text(json.dumps({k: data.get(k) for k in ["authorization_policy", "identity_security_defaults", "authentication_methods_policy", "admin_consent_request_policy"]}, indent=2, sort_keys=True), encoding="utf-8")
    (output_dir / "security-summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")
    write_summary(output_dir / "security-summary.md", summary)
    log(f"Wrote security/apps/license inventory outputs to {output_dir}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read-only Delta Crown security/apps/licenses inventory")
    parser.add_argument("--tenant-id", default=DEFAULT_TENANT_ID)
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    return parser.parse_args()


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args()))
    except Exception as exc:  # noqa: BLE001 - command-line script should report cleanly
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
