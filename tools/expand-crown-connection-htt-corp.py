#!/usr/bin/env python3
"""
Expand Crown Connection M365 group membership to include all licensed
@httbrands.com HTT corporate users (resolved via cross-tenant sync to their
DCE Member counterparts).

Idempotent: re-running picks up newly-synced users without re-adding existing
members. Designed to be re-run periodically (or on-demand) as HTT joiners
flow through cross-tenant sync.

PREREQUISITES
-------------
- az CLI signed into both HTT and DCE tenants (tenant-level account is enough
  for HTT; DCE Global Admin guest is required to write the group)
- jq, python3 (stdlib only)

USAGE
-----
    ./tools/expand-crown-connection-htt-corp.py             # apply changes
    ./tools/expand-crown-connection-htt-corp.py --dry-run   # plan only

ENVIRONMENT
-----------
    DCE_TOKEN  Optional pre-resolved DCE Graph token. If not set, the script
               calls `az account get-access-token --tenant <DCE_TENANT>`.
    HTT_TOKEN  Same, for HTT tenant.

CONFIGURATION (constants at top of file)
- GID         The Crown Connection group ObjectId.
- DCE_TENANT  Delta Crown Extensions tenant id.
- HTT_TENANT  HTT Brands tenant id.
- OWNERS_TO_ADD  Map of {displayName: dceUserId} to promote to group owners.

HISTORY
-------
First applied 2026-05-15 by code-puppy-1bc20e for the Crown Connection
launch handoff to Jenna Bowden (DeltaSetup-of8). At first run, 45 of 52
licensed HTT users mapped successfully; 7 were not yet synced to DCE.
"""
import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

GID = "11e4f2da-c468-4b81-9a18-46d883099a62"
DCE_TENANT = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
HTT_TENANT = "0c0e35dc-188a-4eb3-b8ba-61752154b407"

GRAPH = "https://graph.microsoft.com/v1.0"

# Group owners to ensure exist (idempotent — Graph returns 400 if already)
OWNERS_TO_ADD = {
    "Jenna Bowden": "26e9afa6-3e1b-4830-b0c6-68eceba42781",
    "Kristin Kidd": "f949fd2c-a5ce-4cb0-a58f-f0305160dc9d",
}


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


def graph_request(method: str, url: str, token: str, body=None):
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(
        url, data=data, method=method,
        headers={"Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "ConsistencyLevel": "eventual"},
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


def graph_paginated(path: str, token: str):
    url = GRAPH + path
    while url:
        code, d = graph_request("GET", url, token)
        if code >= 400:
            raise RuntimeError(f"GET {url} -> {code} {d}")
        for x in d.get("value", []):
            yield x
        url = d.get("@odata.nextLink")


def fetch_htt_licensed_upns(token: str) -> list[str]:
    """All accountEnabled @httbrands.com users with at least one license."""
    upns = []
    for u in graph_paginated(
        "/users?$filter=accountEnabled+eq+true+and+endswith"
        "(userPrincipalName,'%40httbrands.com')"
        "&$select=userPrincipalName,assignedLicenses&$top=999",
        token,
    ):
        if u.get("assignedLicenses"):
            upns.append(u["userPrincipalName"].lower())
    return upns


def build_dce_htt_origin_map(token: str) -> dict[str, tuple[str, str]]:
    """Map of HTT mail (lowercase) -> (DCE id, displayName) for synced users."""
    m: dict[str, tuple[str, str]] = {}
    for u in graph_paginated(
        "/users?$select=id,displayName,mail,userPrincipalName&$top=999", token
    ):
        mail = (u.get("mail") or "").lower()
        if "httbrands.com" in mail:
            m[mail] = (u["id"], u["displayName"])
    return m


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--dry-run", action="store_true",
                   help="Print plan without making changes.")
    args = p.parse_args()

    print(f"[{time.strftime('%H:%M:%SZ', time.gmtime())}] Resolving tokens...")
    htt_tok = get_token(HTT_TENANT, "HTT_TOKEN")
    dce_tok = get_token(DCE_TENANT, "DCE_TOKEN")

    print("Fetching licensed @httbrands.com users from HTT...")
    htt_upns = fetch_htt_licensed_upns(htt_tok)
    print(f"  -> {len(htt_upns)} licensed HTT users")

    print("Building DCE map of HTT-origin synced users...")
    dce_map = build_dce_htt_origin_map(dce_tok)
    print(f"  -> {len(dce_map)} HTT-origin DCE objects indexed")

    mapped, unmapped = [], []
    for upn in htt_upns:
        if upn in dce_map:
            mapped.append((dce_map[upn][0], dce_map[upn][1], upn))
        else:
            unmapped.append(upn)
    print(f"\nMapped: {len(mapped)}  Unmapped (pending sync): {len(unmapped)}")
    if unmapped:
        print("  Pending-sync UPNs:")
        for u in unmapped:
            print(f"    - {u}")

    print("\nFetching current Crown Connection members...")
    current_ids = {m["id"] for m in graph_paginated(
        f"/groups/{GID}/members?$select=id", dce_tok)}
    print(f"  -> {len(current_ids)} current members")

    to_add = [t for t in mapped if t[0] not in current_ids]
    print(f"\n  New members to add: {len(to_add)}")
    print(f"  Owners to ensure:   {len(OWNERS_TO_ADD)}")

    if args.dry_run:
        print("\n(dry-run) Skipping writes.")
        for (i, n, u) in to_add:
            print(f"  WOULD ADD MEMBER {n}")
        for (n, oid) in OWNERS_TO_ADD.items():
            print(f"  WOULD ENSURE OWNER {n}")
        return

    print("\n=== Adding owners ===")
    for name, oid in OWNERS_TO_ADD.items():
        code, body = graph_request(
            "POST", f"{GRAPH}/groups/{GID}/owners/$ref", dce_tok,
            {"@odata.id": f"{GRAPH}/directoryObjects/{oid}"},
        )
        if code in (201, 204):
            print(f"  + OWNER  {name}")
        elif code == 400 and "already exist" in json.dumps(body).lower():
            print(f"  = OWNER  {name} (already)")
        else:
            print(f"  ! OWNER  {name}  HTTP {code}: {json.dumps(body)[:150]}")

    print("\n=== Adding members (batches of 20) ===")
    added = 0
    for start in range(0, len(to_add), 20):
        batch = to_add[start:start + 20]
        body = {"members@odata.bind": [
            f"{GRAPH}/directoryObjects/{i}" for (i, _, _) in batch
        ]}
        code, resp = graph_request("PATCH", f"{GRAPH}/groups/{GID}", dce_tok, body)
        if code == 204:
            for (_, n, _) in batch:
                print(f"  + MEMBER {n}")
            added += len(batch)
        else:
            print(f"  ! Batch HTTP {code} — falling back to per-user")
            for (i, n, _) in batch:
                code2, body2 = graph_request(
                    "POST", f"{GRAPH}/groups/{GID}/members/$ref", dce_tok,
                    {"@odata.id": f"{GRAPH}/directoryObjects/{i}"},
                )
                if code2 in (201, 204):
                    print(f"  + MEMBER {n}")
                    added += 1
                elif code2 == 400 and "already exist" in json.dumps(body2).lower():
                    print(f"  = MEMBER {n} (already)")
                else:
                    print(f"  ! MEMBER {n}  HTTP {code2}: {json.dumps(body2)[:120]}")
        time.sleep(0.2)

    print(f"\nDone. Added {added} member(s).")
    if unmapped:
        print(f"\nNOTE: {len(unmapped)} HTT user(s) not yet synced to DCE; re-run "
              f"after the next cross-tenant sync cycle (~40 min).")


if __name__ == "__main__":
    main()
