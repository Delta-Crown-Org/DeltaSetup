#!/usr/bin/env bash
# Provision the Crown Connection M365 group + SharePoint site in the DCE tenant.
# Idempotent-ish: checks for an existing group with the same mailNickname before
# creating. Uses the current az CLI session for Graph auth — requires the caller
# to be Global Admin (or Group Admin) in the DCE tenant.
#
# This is the exact playbook used 2026-05-15 for the launch handoff to Jenna
# Boden. Re-runs are safe: if the group already exists, the script exits with
# the existing id rather than creating a duplicate.
#
# To add the OwnerConnection@deltacrown.com alias (deferred — see
# DeltaSetup-<follow-up>), use a DCE-native admin account against EXO:
#
#   Connect-ExchangeOnline -UserPrincipalName Megan.Myrand@deltacrown.com -Device
#   Set-UnifiedGroup -Identity CrownConnection -EmailAddresses @{
#       add = @('smtp:OwnerConnection@deltacrown.com',
#                'smtp:OwnerConnection@deltacrown.onmicrosoft.com')
#   }
#
# Tyler's HTT admin account cannot do this — it has Graph/Entra admin in DCE
# but no Exchange role, so EXO ignores -Organization deltacrown and lands the
# session in HTT.

set -euo pipefail

DCE_TENANT="${DCE_TENANT:-ce62e17d-2feb-4e67-a115-8ea4af68da30}"
MAIL_NICKNAME="${MAIL_NICKNAME:-CrownConnection}"
DISPLAY_NAME="${DISPLAY_NAME:-Crown Connection}"
DESCRIPTION="${DESCRIPTION:-The place for Crown Extension Studio Owners to connect.}"

# Owners-by-jobTitle filter — these are the Delta Crown Extensions Studio owners
# at launch (5 users). When new studios open, add their owners and rerun is fine.
MEMBER_FILTER='jobTitle eq '\''Owner'\'

# Group owner: Tyler Granlund - Admin DCE guest id (Global Admin in DCE)
GROUP_OWNER_ID="${GROUP_OWNER_ID:-13023522-0166-4e0d-b588-b89fa092aaca}"

TOKEN=$(az account get-access-token --tenant "$DCE_TENANT" --resource https://graph.microsoft.com --query accessToken -o tsv)

echo "[$(date -u +%H:%M:%SZ)] Checking for existing group with mailNickname=$MAIL_NICKNAME..."
EXISTING=$(curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/groups?\$filter=mailNickname+eq+%27${MAIL_NICKNAME}%27&\$select=id,displayName,mail")
EXISTING_ID=$(echo "$EXISTING" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['value'][0]['id'] if d.get('value') else '')")

if [[ -n "$EXISTING_ID" ]]; then
  echo "[$(date -u +%H:%M:%SZ)] Group already exists: $EXISTING_ID"
  echo "  Skipping creation. Re-run with a different MAIL_NICKNAME to create a new one."
  exit 0
fi

echo "[$(date -u +%H:%M:%SZ)] Resolving member IDs (jobTitle=Owner)..."
MEMBER_IDS=$(curl -sS -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/users?\$filter=${MEMBER_FILTER// /+}&\$select=id,displayName" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); [print(u['id'], u['displayName']) for u in d.get('value',[])]")
echo "$MEMBER_IDS"

MEMBER_BINDS=$(echo "$MEMBER_IDS" | awk '{print "https://graph.microsoft.com/v1.0/users/"$1}' \
  | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))")

cat > /tmp/.crown-connection-body.json <<JSON
{
  "displayName": "${DISPLAY_NAME}",
  "mailNickname": "${MAIL_NICKNAME}",
  "description": "${DESCRIPTION}",
  "groupTypes": ["Unified"],
  "mailEnabled": true,
  "securityEnabled": false,
  "visibility": "Private",
  "owners@odata.bind": [
    "https://graph.microsoft.com/v1.0/users/${GROUP_OWNER_ID}"
  ],
  "members@odata.bind": ${MEMBER_BINDS}
}
JSON

echo "[$(date -u +%H:%M:%SZ)] POST /v1.0/groups ..."
RESP=$(curl -sS -w "\n__HTTP__%{http_code}" -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/.crown-connection-body.json \
  https://graph.microsoft.com/v1.0/groups)
CODE=$(echo "$RESP" | awk -F__HTTP__ 'NR>1 || /__HTTP__/{print $2}' | tail -1)
BODY=$(echo "$RESP" | sed 's/__HTTP__.*//')

if [[ "$CODE" != "201" ]]; then
  echo "FAILED. HTTP $CODE"
  echo "$BODY"
  exit 1
fi

GID=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "[$(date -u +%H:%M:%SZ)] Created group $GID"

echo "[$(date -u +%H:%M:%SZ)] Waiting for SharePoint site auto-provisioning..."
for i in 1 2 3 4 5 6; do
  SITE=$(curl -sS -H "Authorization: Bearer $TOKEN" \
    "https://graph.microsoft.com/v1.0/groups/$GID/sites/root?\$select=webUrl")
  WEB_URL=$(echo "$SITE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('webUrl',''))" 2>/dev/null || echo "")
  if [[ -n "$WEB_URL" ]]; then
    echo "[$(date -u +%H:%M:%SZ)] Site live: $WEB_URL"
    break
  fi
  echo "  attempt $i/6 — site not yet provisioned, sleeping 15s..."
  sleep 15
done

rm -f /tmp/.crown-connection-body.json
echo "[$(date -u +%H:%M:%SZ)] Done."
