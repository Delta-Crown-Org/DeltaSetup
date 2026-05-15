#!/usr/bin/env python3
"""
Silent-invite HTT corporate users into the DCE tenant as B2B users,
then flip their userType to Member (matching the pattern established
by the original 2026-03-04 bulk invite that brought ~74 HTT users
into DCE).

Why this exists
---------------
HTT and DCE are NOT in a Multi-Tenant Organization and there is no
cross-tenant synchronization job between them. The HTT-origin users
that show up in DCE today were created by a one-time manual B2B
invite event on 2026-03-04. New HTT hires after that date do NOT
automatically appear in DCE.

This script is the canonical way to onboard a new HTT hire (or backfill
a missed one) so they're visible in the DCE directory and can be added
to DCE M365 groups (Crown Connection, etc.).

Usage
-----
    DCE_TOKEN=$(az account get-access-token --tenant <DCE> --query accessToken -o tsv) \
        ./tools/invite-htt-users-to-dce.py user1@httbrands.com user2@httbrands.com ...

If no UPNs are passed on the command line, the script reads them
(one per line) from stdin.

The Graph 'invitations' endpoint with sendInvitationMessage=False
creates the user immediately without sending an email. This matches
how the original 2026-03-04 bulk was done.
"""
import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

GRAPH = "https://graph.microsoft.com/v1.0"
DCE_TENANT = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
HTT_TENANT = "0c0e35dc-188a-4eb3-b8ba-61752154b407"


def get_token(tenant_id: str, env_var: str) -> str:
    if os.environ.get(env_var):
        return os.environ[env_var]
    out = subprocess.run(
        ["az", "account", "get-access-token", "--tenant", tenant_id,
         "--resource", "https://graph.microsoft.com", "--query", "accessToken",
         "-o", "tsv"],
        capture_output=True, text=True, check=True,
    )
    return out.stdout.strip()


def gcall(method: str, url: str, token: str, body=None):
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(
        url, data=data, method=method,
        headers={"Authorization": f"Bearer {token}",
                "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as r:
            txt = r.read().decode()
            return r.status, (json.loads(txt) if txt else {})
    except urllib.error.HTTPError as e:
        txt = e.read().decode()
        try:
            j = json.loads(txt)
        except Exception:
            j = {"raw": txt}
        return e.code, j


def lookup_htt_user(htt_token: str, upn: str) -> dict | None:
    code, body = gcall("GET",
        f"{GRAPH}/users/{upn}?$select=id,displayName,userPrincipalName,mail,accountEnabled",
        htt_token)
    if code != 200:
        return None
    return body


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("upns", nargs="*",
                   help="HTT user principal names to invite into DCE")
    p.add_argument("--landing-url",
                   default="https://deltacrown.sharepoint.com/sites/CrownConnection",
                   help="Where the invited user lands when they sign in to DCE")
    args = p.parse_args()

    upns = args.upns or [line.strip() for line in sys.stdin if line.strip()]
    if not upns:
        print("No UPNs provided.", file=sys.stderr)
        sys.exit(2)

    print("Resolving tokens...")
    htt_token = get_token(HTT_TENANT, "HTT_TOKEN")
    dce_token = get_token(DCE_TENANT, "DCE_TOKEN")

    results = []
    for upn in upns:
        upn = upn.strip().lower()
        print(f"\n--- {upn} ---")
        htt_u = lookup_htt_user(htt_token, upn)
        if not htt_u:
            print("  HTT lookup failed — skipping.")
            results.append((upn, "htt-not-found"))
            continue
        if not htt_u.get("accountEnabled"):
            print("  HTT account is DISABLED — skipping.")
            results.append((upn, "htt-disabled"))
            continue

        display = htt_u.get("displayName") or upn
        body = {
            "invitedUserEmailAddress": upn,
            "invitedUserDisplayName": display,
            "inviteRedirectUrl": args.landing_url,
            "sendInvitationMessage": False,
            "invitedUserType": "Guest",
        }
        code, resp = gcall("POST", f"{GRAPH}/invitations", dce_token, body)
        if code in (200, 201):
            uid = resp.get("invitedUser", {}).get("id")
            print(f"  invited  id={uid}")
            time.sleep(2)
            code2, _ = gcall("PATCH", f"{GRAPH}/users/{uid}", dce_token,
                              {"userType": "Member"})
            if code2 == 204:
                print(f"  flipped userType -> Member  OK")
                results.append((upn, "ok"))
            else:
                print(f"  flip failed HTTP {code2}")
                results.append((upn, f"flip-failed-{code2}"))
        elif code == 409 or "already" in json.dumps(resp).lower():
            print("  already exists in DCE — skipping.")
            results.append((upn, "already-exists"))
        else:
            print(f"  invite FAILED HTTP {code}: {json.dumps(resp)[:200]}")
            results.append((upn, f"invite-failed-{code}"))

    print("\n=== Summary ===")
    for upn, status in results:
        print(f"  {status:20s}  {upn}")


if __name__ == "__main__":
    main()
