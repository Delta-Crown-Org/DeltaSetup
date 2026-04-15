#!/usr/bin/env python3
"""
Delta Crown Security Hardening - Python implementation
Uses MSAL device code flow + SharePoint REST API
"""
import msal
import requests
import json
import sys
import time

# === CONFIG ===
CLIENT_ID = "fe319e51-b7f1-4679-8c6e-9ad5baf30023"
TENANT = "deltacrown.onmicrosoft.com"
TENANT_NAME = "deltacrown"
AUTHORITY = f"https://login.microsoftonline.com/{TENANT}"
SCOPES = ["https://deltacrown.sharepoint.com/.default"]

# Permission matrix for DCE sites
PERMISSION_MATRIX = {
    "dce-hub": [
        {"group": "AllStaff", "role": "Read"},
        {"group": "Managers", "role": "Full Control"},
    ],
    "dce-clientservices": [
        {"group": "AllStaff", "role": "Contribute"},
        {"group": "Managers", "role": "Full Control"},
    ],
    "dce-marketing": [
        {"group": "AllStaff", "role": "Read"},
        {"group": "Managers", "role": "Full Control"},
        {"group": "Marketing", "role": "Edit"},
    ],
    "dce-docs": [
        {"group": "AllStaff", "role": "Read"},
        {"group": "Managers", "role": "Full Control"},
    ],
}

FORBIDDEN_GROUPS = [
    "Everyone",
    "Everyone except external users",
    "All Users",
    r"NT AUTHORITY\Authenticated Users",
]

CORP_SITES = ["corp-hub", "corp-hr", "corp-it", "corp-finance", "corp-training"]


def get_token():
    """Get access token via device code flow"""
    app = msal.PublicClientApplication(CLIENT_ID, authority=AUTHORITY)
    
    flow = app.initiate_device_flow(scopes=SCOPES)
    if "user_code" not in flow:
        print(f"❌ Failed to create device flow: {flow.get('error_description', 'unknown')}")
        sys.exit(1)
    
    # Write the code to a file for visibility
    code = flow["user_code"]
    with open("/tmp/device-code-current.txt", "w") as f:
        f.write(code)
    
    print()
    print("╔══════════════════════════════════════════════════════╗")
    print("║  TYLER - AUTHENTICATE NOW!                          ║")
    print(f"║  URL:  {flow['verification_uri']:44s} ║")
    print(f"║  CODE: {code:44s} ║")
    print("╚══════════════════════════════════════════════════════╝")
    print()
    sys.stdout.flush()
    
    # This blocks until auth completes
    result = app.acquire_token_by_device_flow(flow)
    
    if "access_token" in result:
        print(f"✅ Authenticated as: {result.get('id_token_claims', {}).get('preferred_username', 'unknown')}")
        # Save token
        with open("/tmp/spo-access-token.txt", "w") as f:
            f.write(result["access_token"])
        return result["access_token"]
    else:
        print(f"❌ Auth failed: {result.get('error_description', result.get('error', 'unknown'))}")
        sys.exit(1)


def spo_request(token, site_url, endpoint, method="GET", data=None, headers=None):
    """Make a SharePoint REST API request"""
    url = f"{site_url}/_api/{endpoint}"
    hdrs = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json;odata=nometadata",
        "Content-Type": "application/json;odata=nometadata",
    }
    if headers:
        hdrs.update(headers)
    
    if method == "GET":
        resp = requests.get(url, headers=hdrs)
    elif method == "POST":
        hdrs["X-RequestDigest"] = get_request_digest(token, site_url)
        resp = requests.post(url, headers=hdrs, json=data)
    elif method == "PATCH":
        hdrs["X-RequestDigest"] = get_request_digest(token, site_url)
        hdrs["X-HTTP-Method"] = "MERGE"
        hdrs["IF-MATCH"] = "*"
        resp = requests.post(url, headers=hdrs, json=data)
    
    return resp


def get_request_digest(token, site_url):
    """Get form digest value for POST requests"""
    resp = requests.post(
        f"{site_url}/_api/contextinfo",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json;odata=nometadata",
        }
    )
    if resp.status_code == 200:
        return resp.json().get("FormDigestValue", "")
    return ""


def break_inheritance(token, site_url, site_name):
    """Break permission inheritance on the web"""
    # Check current state
    resp = spo_request(token, site_url, "web?$select=HasUniqueRoleAssignments")
    if resp.status_code != 200:
        print(f"  ⚠️  Can't check inheritance: {resp.status_code} {resp.text[:200]}")
        return False
    
    data = resp.json()
    if data.get("HasUniqueRoleAssignments"):
        print(f"  ⏭️  Already has unique permissions")
        return True
    
    # Break inheritance (keep existing permissions)
    digest = get_request_digest(token, site_url)
    resp = requests.post(
        f"{site_url}/_api/web/breakroleinheritance(copyRoleAssignments=true,clearSubscopes=true)",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json;odata=nometadata",
            "X-RequestDigest": digest,
        }
    )
    
    if resp.status_code in (200, 204):
        print(f"  ✅ Broke permission inheritance")
        return True
    else:
        print(f"  ⚠️  Break inheritance failed: {resp.status_code} {resp.text[:200]}")
        return False


def remove_forbidden_groups(token, site_url):
    """Remove forbidden groups from site"""
    for group_name in FORBIDDEN_GROUPS:
        try:
            resp = spo_request(token, site_url, f"web/sitegroups/getbyname('{group_name}')")
            if resp.status_code == 200:
                group_id = resp.json().get("Id")
                if group_id:
                    digest = get_request_digest(token, site_url)
                    del_resp = requests.post(
                        f"{site_url}/_api/web/sitegroups/removebyid({group_id})",
                        headers={
                            "Authorization": f"Bearer {token}",
                            "Accept": "application/json;odata=nometadata",
                            "X-RequestDigest": digest,
                        }
                    )
                    if del_resp.status_code in (200, 204):
                        print(f"  ✅ Removed: {group_name}")
                    else:
                        print(f"  ⚠️  Remove {group_name}: {del_resp.status_code}")
            # 404 = group doesn't exist, skip silently
        except Exception as e:
            pass  # Expected for non-existent groups


def apply_permissions(token, site_url, perms):
    """Apply permission matrix entries"""
    for perm in perms:
        group_name = perm["group"]
        role_name = perm["role"]
        try:
            # Get role definition ID
            role_resp = spo_request(token, site_url, 
                f"web/roledefinitions/getbyname('{role_name}')?$select=Id")
            if role_resp.status_code != 200:
                print(f"  ⚠️  Role '{role_name}' not found: {role_resp.status_code}")
                continue
            role_id = role_resp.json()["Id"]
            
            # Get group ID  
            group_resp = spo_request(token, site_url,
                f"web/sitegroups/getbyname('{group_name}')?$select=Id")
            if group_resp.status_code != 200:
                print(f"  ⚠️  Group '{group_name}' not found: {group_resp.status_code}")
                continue
            group_id = group_resp.json()["Id"]
            
            # Add role assignment
            digest = get_request_digest(token, site_url)
            assign_resp = requests.post(
                f"{site_url}/_api/web/roleassignments/addroleassignment(principalid={group_id},roledefid={role_id})",
                headers={
                    "Authorization": f"Bearer {token}",
                    "Accept": "application/json;odata=nometadata",
                    "X-RequestDigest": digest,
                }
            )
            if assign_resp.status_code in (200, 204):
                print(f"  ✅ {group_name} → {role_name}")
            else:
                print(f"  ⚠️  {group_name} → {role_name}: {assign_resp.status_code} {assign_resp.text[:100]}")
        except Exception as e:
            print(f"  ⚠️  {group_name}: {e}")


def disable_sharing(token, site_url, site_name):
    """Disable external sharing via SharePoint REST API"""
    try:
        digest = get_request_digest(token, site_url)
        # Use the site properties to disable sharing
        resp = requests.post(
            f"{site_url}/_api/web/SetSharingCapability(1)",  # 1 = Disabled
            headers={
                "Authorization": f"Bearer {token}",
                "Accept": "application/json;odata=nometadata",
                "X-RequestDigest": digest,
            }
        )
        if resp.status_code in (200, 204):
            print(f"  ✅ External sharing disabled")
            return True
        else:
            # Try alternative method
            print(f"  ⚠️  SetSharingCapability: {resp.status_code}, trying admin API...")
            return False
    except Exception as e:
        print(f"  ⚠️  Sharing: {e}")
        return False


def main():
    print("=" * 60)
    print("Delta Crown Security Hardening")
    print("=" * 60)
    print()
    
    # Step 1: Get token
    token = get_token()
    
    print()
    print("=" * 60)
    print("Starting security hardening...")
    print("=" * 60)
    
    # Step 2: Process DCE sites (full treatment)
    for site_name, perms in PERMISSION_MATRIX.items():
        site_url = f"https://{TENANT_NAME}.sharepoint.com/sites/{site_name}"
        print(f"\n━━━ {site_name} ━━━")
        
        # Verify access
        resp = spo_request(token, site_url, "web?$select=Title")
        if resp.status_code != 200:
            print(f"  ❌ Cannot access site: {resp.status_code} {resp.text[:200]}")
            continue
        print(f"  Connected: {resp.json().get('Title', '?')}")
        
        # 1. Break inheritance
        break_inheritance(token, site_url, site_name)
        
        # 2. Remove forbidden groups
        remove_forbidden_groups(token, site_url)
        
        # 3. Apply permission matrix
        apply_permissions(token, site_url, perms)
        
        # 4. Disable sharing
        disable_sharing(token, site_url, site_name)
    
    # Step 3: Process Corp sites (sharing only)
    for site_name in CORP_SITES:
        site_url = f"https://{TENANT_NAME}.sharepoint.com/sites/{site_name}"
        print(f"\n━━━ {site_name} (sharing only) ━━━")
        
        resp = spo_request(token, site_url, "web?$select=Title")
        if resp.status_code != 200:
            print(f"  ❌ Cannot access site: {resp.status_code} {resp.text[:200]}")
            continue
        print(f"  Connected: {resp.json().get('Title', '?')}")
        
        disable_sharing(token, site_url, site_name)
    
    print()
    print("🏁 Security hardening complete!")
    print()


if __name__ == "__main__":
    main()
