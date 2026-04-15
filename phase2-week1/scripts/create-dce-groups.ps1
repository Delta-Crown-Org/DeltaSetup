# ============================================================================
# Create Azure AD Dynamic Groups for DCE
# Run this from YOUR terminal if the main script fails with MSAL errors
# ============================================================================

$tenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"

Write-Host "Creating DCE Azure AD Dynamic Groups..." -ForegroundColor Cyan
Write-Host "Tyler: you'll get a browser popup for Graph auth" -ForegroundColor Yellow

Connect-MgGraph -Scopes "Group.ReadWrite.All","Directory.ReadWrite.All" -TenantId $tenantId

$groups = @(
    @{ N="AllStaff";  D="All Delta Crown Extensions staff"
       M='(user.companyName -eq "Delta Crown Extensions")'; Nick="dce-allstaff" }
    @{ N="Managers";  D="DCE management team"
       M='(user.companyName -eq "Delta Crown Extensions") and (user.jobTitle -contains "Manager")'; Nick="dce-managers" }
    @{ N="Stylists";  D="DCE stylists and technicians"
       M='(user.companyName -eq "Delta Crown Extensions") and (user.jobTitle -contains "Stylist")'; Nick="dce-stylists" }
    @{ N="External";  D="External partners for DCE"
       M='(user.userType -eq "Guest") and (user.companyName -eq "Delta Crown Extensions")'; Nick="dce-external" }
)

foreach ($g in $groups) {
    $existing = Get-MgGroup -Filter "displayName eq '$($g.N)'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "  Exists: $($g.N) (ID: $($existing.Id))" -ForegroundColor Yellow
        continue
    }
    try {
        $new = New-MgGroup -DisplayName $g.N -Description $g.D `
            -MailEnabled:$false -MailNickname $g.Nick `
            -SecurityEnabled:$true -GroupTypes @("DynamicMembership") `
            -MembershipRule $g.M -MembershipRuleProcessingState "On"
        Write-Host "  Created: $($g.N) (ID: $($new.Id))" -ForegroundColor Green
    } catch {
        Write-Host "  FAILED: $($g.N) — $_" -ForegroundColor Red
    }
}

Disconnect-MgGraph
Write-Host "Done!" -ForegroundColor Green
