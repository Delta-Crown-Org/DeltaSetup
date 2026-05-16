# 10 — Operational Runbooks

Each runbook is concrete: copy-pasteable commands, prereqs, expected
outcomes. Use these directly; don't paraphrase.

---

## Runbook 1 — Onboard a new DCE staff member

**Prerequisites:** New hire's HTT or DCE account exists and is licensed.

### If they're an HTT corporate hire

1. Verify they're in HTT and licensed:
   ```bash
   az account get-access-token --tenant 0c0e35dc-188a-4eb3-b8ba-61752154b407 --resource https://graph.microsoft.com --query accessToken -o tsv | read TOKEN
   curl -sH "Authorization: Bearer $TOKEN" "https://graph.microsoft.com/v1.0/users/<upn>?\$select=id,displayName,accountEnabled,assignedLicenses"
   ```
2. They auto-sync to DCE within 40 min via `SG-DCE-Sync-Users` dynamic
   group rule (now matches `*@httbrands.com` + accountEnabled).
3. Once in DCE, run the appropriate group-add tool:
   - Crown Connection: `tools/expand-crown-connection-htt-corp.py`
     (idempotent; will pick them up automatically).
4. They appear in DCE Hub (Visitors group implicitly via cross-tenant
   propagation).

### If they're a DCE-native franchise hire (rare)

1. Create their account in DCE tenant directly.
2. Add to the appropriate role group:
   - Franchise owner → `DCE-Franchise-Owners` and `Crown Connection` member group
   - Manager → `DCE-Managers`
   - Staff → `DCE-AllStaff`
3. License them appropriately.

---

## Runbook 2 — Offboard a DCE staff member

### If they're an HTT corp user

1. Disable their HTT account: handled by HTT IT (out of our scope).
2. Within 40 min, dynamic group rule excludes them → cross-tenant sync
   marks them as disabled in DCE.
3. Their DCE Crown Connection membership remains until manually removed:
   ```bash
   az account get-access-token --tenant ce62e17d --resource https://graph.microsoft.com | ...
   curl -X DELETE -H "Authorization: Bearer $TOKEN" \
     "https://graph.microsoft.com/v1.0/groups/11e4f2da-c468-4b81-9a18-46d883099a62/members/<user-id>/\$ref"
   ```
4. Audit Crown Connection's owner-only library for any documents they
   created; reassign or archive.

### If they're a DCE-native user

1. Disable account: SharePoint admin or Entra admin center.
2. Remove from role groups.
3. Transfer file ownership (OneDrive + Crown Connection documents).
4. Hold mailbox 30 days per retention policy.

---

## Runbook 3 — Add a new owner to Crown Connection

```bash
# Prereqs: Tyler authenticated; user already in DCE.
DCE_TOKEN=$(az account get-access-token --tenant ce62e17d-2feb-4e67-a115-8ea4af68da30 --resource https://graph.microsoft.com --query accessToken -o tsv)
GROUP_ID=11e4f2da-c468-4b81-9a18-46d883099a62
USER_ID=<new-owner-dce-id>

# Add as group owner
curl -X POST -H "Authorization: Bearer $DCE_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/groups/$GROUP_ID/owners/\$ref" \
  -d "{\"@odata.id\":\"https://graph.microsoft.com/v1.0/users/$USER_ID\"}"

# Add as group member if not already
curl -X POST -H "Authorization: Bearer $DCE_TOKEN" -H "Content-Type: application/json" \
  "https://graph.microsoft.com/v1.0/groups/$GROUP_ID/members/\$ref" \
  -d "{\"@odata.id\":\"https://graph.microsoft.com/v1.0/users/$USER_ID\"}"
```

Update the handoff memo at
`docs/onboarding/crown-connection-launch-handoff-jenna-bowden.md` if
the ownership cohort changes.

---

## Runbook 4 — Update DCE branding (color, font, logo)

1. Edit `deltacrown.com/css/tokens.css` in this repo (the source of
   truth).
2. PR + merge → public site updates.
3. Regenerate the SharePoint-side tokens:
   ```bash
   cd /Users/tygranlund/dev/04-other-orgs/dce-sharepoint
   npm run build:tokens
   ```
4. Commit + push the new `dist/sharepoint/theme.json`.
5. Deploy pipeline applies the new theme to DCE Hub and Crown Connection.
6. Manual step: Re-upload logos to Brand Center if logo changed.

**Validation:** Visit `/sites/dce-hub` 15 min after deploy; theme
should be live. Check focus rings, hero background, link colors.

---

## Runbook 5 — Investigate a permission anomaly

Symptom: A user reports "I can't see X" or "I can see X that I
shouldn't."

1. Identify the surface in question (site + page + web part / list / library).
2. Run the audit script:
   ```bash
   cd /Users/tygranlund/dev/01-htt-brands/sharepointagent
   python audit_folder_permissions.py --site https://deltacrown.sharepoint.com/sites/<site> --path "<path>"
   ```
3. Compare against `reference/permission-breaks.csv`. If undocumented
   break: this is drift.
4. Resolve:
   - If break is correct but not documented → add to CSV, commit.
   - If break is incorrect → remove via PnP:
     ```powershell
     Connect-PnPOnline -Url <site-url> -Interactive
     $list = Get-PnPList -Identity "<library-name>"
     $list.ResetRoleInheritance()
     $list.Update()
     Invoke-PnPQuery
     ```
5. Re-run audit to confirm.

---

## Runbook 6 — Add a new page to DCE Hub

1. Author the page locally:
   ```powershell
   Connect-PnPOnline -Url https://deltacrown.sharepoint.com/sites/dce-hub-dev -Interactive
   $page = Add-PnPPage -Name "FeatureRequests" -LayoutType Article
   Add-PnPPageSection -Page "FeatureRequests" -SectionTemplate OneColumn -Order 1
   Add-PnPPageWebPart -Page "FeatureRequests" -DefaultWebPartType Text -Section 1 -Column 1 -WebPartProperties @{ Text = "Initial content" }
   ```
2. Export as template:
   ```powershell
   Get-PnPSiteTemplate -Out "templates/hub/003-add-feature-requests.xml" -Handlers Pages
   ```
3. PR + merge → CI applies to prod.

---

## Runbook 7 — Roll back a bad deploy

See `09-deployment.md` § "Rollback procedure (concrete)". TL;DR:

```powershell
git checkout <known-good-commit>
Invoke-PnPSiteTemplate -Path backups/<timestamp>/snapshot.xml
```

---

## Runbook 8 — Re-issue deployment certificate (annual)

1. Generate new cert (per `09-deployment.md` § Step 2).
2. Upload public `.cer` to Entra app registration in the DCE tenant.
3. Update GitHub secrets `DCE_DEPLOY_PFX` and `DCE_DEPLOY_PFX_PASSWORD`.
4. Test deploy to dev environment.
5. After 7 days of successful operation, revoke the old cert from the
   Entra app.
6. Delete local cert files.

---

## Runbook 9 — Investigate "user not appearing in DCE"

1. Verify they're in HTT and enabled:
   ```bash
   curl -sH "Authorization: Bearer $HTT_TOKEN" \
     "https://graph.microsoft.com/v1.0/users/<upn>?\$select=accountEnabled,assignedLicenses"
   ```
2. Verify they're in `SG-DCE-Sync-Users` group:
   ```bash
   curl -sH "Authorization: Bearer $HTT_TOKEN" \
     "https://graph.microsoft.com/v1.0/groups/6f5cc75e-b2ae-4ed2-992d-e56d4e3ef5f3/members?\$select=userPrincipalName" \
     | grep -i <upn>
   ```
3. If they're in HTT + enabled but not in the group, the dynamic rule
   isn't matching. Possible cause: `accountEnabled` is false on the
   user despite the UI saying enabled (check `accountEnabled`
   attribute directly).
4. If they're in the group, force on-demand provisioning:
   ```bash
   curl -X POST -H "Authorization: Bearer $HTT_TOKEN" \
     "https://graph.microsoft.com/v1.0/servicePrincipals/1f074621-8bcd-4d9e-b27e-4470afeedba1/synchronization/jobs/Azure2Azure.0c0e35dc188a4eb3b8ba61752154b407.9c8934a1-658d-4bab-b7a1-a1a11593a203/provisionOnDemand" \
     -H "Content-Type: application/json" \
     -d "{\"parameters\":[{\"subjects\":[{\"objectId\":\"<user-htt-id>\",\"objectTypeName\":\"User\"}],\"ruleId\":\"01e28086-1453-4cb2-b95d-4fbc4564fcc0\"}]}"
   ```
5. If on-demand provisioning succeeds but user still not in DCE within
   1 hour, check sync provisioning logs in Entra admin center for
   detailed failure reason.

---

## Runbook 10 — Emergency access

If Tyler is unavailable and an urgent admin action is needed:

1. **Megan Myrand** is the DCE-native Global Admin backup.
   Account: `megan.myrand@deltacrown.com`.
2. For Exchange-Online cross-tenant ops, use the
   `-DelegatedOrganization` pattern from
   `tools/connect-exo-cross-tenant.md`.
3. For automated deploys, the cert-based app registration runs
   independently of Tyler's interactive session.

---

## Runbook conventions

- Every runbook starts with prereqs.
- Every runbook ends with a validation step.
- Every command shown is copy-pasteable (no `<placeholders>`
  without telling the reader what to substitute).
- Update runbooks when underlying mechanics change. Outdated runbooks
  are worse than no runbooks.
