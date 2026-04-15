#!/usr/bin/env python3
"""
Security Hardening via Microsoft Graph API
Uses app credentials (Sites.FullControl.All) to manage site permissions.

Note: Graph API can manage site-level permissions (app grants),
but SharePoint-internal operations (break inheritance, remove "Everyone"
groups, permission role matrix) require SPO REST or PnP.

This script handles what's possible through Graph:
1. Audit current site permissions
2. Set sharing restrictions via Graph (site-level sharing)
3. Report on group memberships for forbidden groups
"""
import json
import sys
import urllib.request
import urllib.parse
import os

TENANT_ID = "ce62e17d-2feb-4e67-a115-8ea4af68da30"

# Site mappings (displayName -> Graph site ID)
SITES = {
    "dce-hub": "deltacrown.sharepoint.com,c5efc225-1d3c-4d5f-a3f0-bcae08ac5d87,f3db80f9-3596-42fa-90b8-9d95414b16a8",
    "dce-operations": "deltacrown.sharepoint.com,781e8846-4c6a-4a9b-8498-4dc25cc0e236,bc02f423-484b-4f7c-b951-7536456370f0",
    "dce-clientservices": "deltacrown.sharepoint.com,b4b93bd7-c2de-461c-8adf-b95a18cf1889,bc02f423-484b-4f7c-b951-7536456370f0",
    "dce-marketing": "deltacrown.sharepoint.com,9e97b0f9-6967-4746-8ddc-5ebab526f6d8,f3db80f9-3596-42fa-90b8-9d95414b16a8",
    "dce-docs": "deltacrown.sharepoint.com,d3a736a2-75d1-4cca-af34-815c5d748d80,bc02f423-484b-4f7c-b951-7536456370f0",
}

CORP_SITES = {
    "corp-hub": "deltacrown.sharepoint.com,a2d9c03e-ec39-4ac5-b8ca-1504681c0b4d,f3db80f9-3596-42fa-90b8-9d95414b16a8",
    "corp-hr": "deltacrown.sharepoint.com,187dd7d7-e60b-45f1-bc37-d0badd8b2d98,f3db80f9-3596-42fa-90b8-9d95414b16a8",
    "corp-it": "deltacrown.sharepoint.com,a4ff9aa6-02e6-4471-870d-611b6c76dc8f,f3db80f9-3596-42fa-90b8-9d95414b16a8",
    "corp-finance": "deltacrown.sharepoint.com,770a4362-2b23-4261-aae5-94de3357a171,f3db80f9-3596-42fa-90b8-9d95414b16a8",
    "corp-training": "deltacrown.sharepoint.com,74996775-a338-4ea4-8aa9-a04735d17c02,f3db80f9-3596-42fa-90b8-9d95414b16a8",
}

FORBIDDEN_GROUPS = [
    "Everyone",
    "Everyone except external users",
    "All Users",
]

# Security groups we want to verify exist
SECURITY_GROUPS = {
    "AllStaff": None,
    "Managers": None,
    "Marketing": None,
    "Stylists": None,
}


def get_app_token():
    """Get Graph token using app credentials."""
    app_id = open("/tmp/teams-app-id.txt").read().strip()
    app_secret = open("/tmp/teams-app-secret2.txt").read().strip()

    data = urllib.parse.urlencode({
        "client_id": app_id,
        "client_secret": app_secret,
        "scope": "https://graph.microsoft.com/.default",
        "grant_type": "client_credentials",
    }).encode()

    req = urllib.request.Request(
        f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token",
        data=data,
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)["access_token"]


def graph_get(token, url):
    """GET from Graph API."""
    # URL-encode query parameters properly
    if '?' in url:
        base, query = url.split('?', 1)
        # Re-encode query string to handle spaces
        params = urllib.parse.parse_qs(query, keep_blank_values=True)
        url = base + '?' + urllib.parse.urlencode({k: v[0] for k, v in params.items()})
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        return {"error": {"code": e.code, "message": body[:200]}}


def graph_post(token, url, body):
    """POST to Graph API."""
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        url, data=data, method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        return {"error": {"code": e.code, "message": e.read().decode()[:200]}}


def graph_patch(token, url, body):
    """PATCH Graph API."""
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        url, data=data, method="PATCH",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        return {"error": {"code": e.code, "message": e.read().decode()[:200]}}


def audit_site_permissions(token, site_name, site_id):
    """Audit permissions for a site."""
    result = graph_get(token, f"https://graph.microsoft.com/v1.0/sites/{site_id}/permissions")
    perms = result.get("value", [])
    print(f"  Permissions: {len(perms)} explicit grants")
    for p in perms:
        roles = p.get("roles", [])
        granted = p.get("grantedToV2", {})
        app_name = granted.get("application", {}).get("displayName", "?")
        print(f"    {p['id']}: {roles} → {app_name}")
    return perms


def find_security_groups(token):
    """Find our security groups."""
    for name in SECURITY_GROUPS:
        result = graph_get(
            token,
            f"https://graph.microsoft.com/v1.0/groups?$filter=displayName eq '{name}'&$select=id,displayName,membershipRule",
        )
        groups = result.get("value", [])
        if groups:
            SECURITY_GROUPS[name] = groups[0]["id"]
            print(f"  ✅ {name}: {groups[0]['id']}")
        else:
            print(f"  ❌ {name}: NOT FOUND")


def check_forbidden_groups(token):
    """Check if forbidden groups exist in the directory."""
    print("\n  Forbidden groups check:")
    for name in FORBIDDEN_GROUPS:
        result = graph_get(
            token,
            f"https://graph.microsoft.com/v1.0/groups?$filter=displayName eq '{name}'&$select=id,displayName",
        )
        groups = result.get("value", [])
        if groups:
            print(f"    ⚠️  {name} EXISTS: {groups[0]['id']}")
        else:
            print(f"    ✅ {name}: not found in directory")


def set_site_sharing_via_graph(token, site_name, site_id):
    """
    Graph API doesn't directly expose SharePoint sharing settings.
    But we can use the beta API to manage site permissions.
    
    What we CAN do via Graph:
    - Grant app-level permissions to sites
    - List/manage site permissions
    
    What we CANNOT do via Graph (needs SPO REST/PnP):
    - Break permission inheritance
    - Remove "Everyone" groups from site
    - Set SharingCapability to Disabled
    - Set permission levels (Read/Contribute/Full Control)
    """
    # We can at least verify the site's group memberships
    # and check for "Everyone" in the site's permissions
    result = graph_get(
        token,
        f"https://graph.microsoft.com/v1.0/sites/{site_id}/permissions",
    )
    perms = result.get("value", [])
    has_forbidden = False
    for p in perms:
        granted = p.get("grantedToIdentitiesV2", [])
        for g in granted:
            user = g.get("user", {})
            if user.get("displayName", "") in FORBIDDEN_GROUPS:
                has_forbidden = True
                print(f"    ⚠️  Found forbidden: {user['displayName']}")
    if not has_forbidden:
        print(f"    ✅ No forbidden groups in site permissions")
    return not has_forbidden


def main():
    print("=" * 60)
    print("  Delta Crown Security Hardening — Graph API Audit")
    print("=" * 60)
    print()

    token = get_app_token()
    print(f"✅ App token obtained\n")

    # 1. Find security groups
    print("=== Security Groups ===")
    find_security_groups(token)
    check_forbidden_groups(token)

    # 2. Audit DCE sites
    print("\n=== DCE Site Permissions ===")
    all_sites = {**SITES, **CORP_SITES}
    results = {}
    for site_name, site_id in all_sites.items():
        print(f"\n━━━ {site_name} ━━━")
        perms = audit_site_permissions(token, site_name, site_id)
        clean = set_site_sharing_via_graph(token, site_name, site_id)
        results[site_name] = {"perms": len(perms), "clean": clean}

    # 3. Summary
    print("\n" + "=" * 60)
    print("  SUMMARY")
    print("=" * 60)
    print(f"\n{'Site':25s} {'Perms':>6s}  {'Clean':>6s}")
    print("-" * 45)
    for site, data in sorted(results.items()):
        status = "✅" if data["clean"] else "⚠️"
        print(f"  {site:23s} {data['perms']:>4d}    {status}")

    print("\n⚠️  REMAINING ACTIONS (require SPO REST API / PnP):")
    print("  1. Break permission inheritance on DCE sites")
    print("  2. Remove 'Everyone except external users' from SP groups")
    print("  3. Apply permission matrix (AllStaff=Read, Managers=Full Control)")
    print("  4. Set SharingCapability=Disabled on all sites")
    print()
    print("  These require either:")
    print("  a) Tyler to run: pwsh -File deploy-security-hardening.ps1")
    print("  b) Enable app-only auth: Set-SPOTenant -DisableCustomAppAuthentication $false")
    print()


if __name__ == "__main__":
    main()
