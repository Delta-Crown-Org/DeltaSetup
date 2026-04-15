# Quick Teams deployment — run as single session
param([string]$GroupId = "03255d50-a52d-4b1f-a0f6-37379cc13a35")

$ErrorActionPreference = "Continue"
Connect-MgGraph -Scopes "Group.ReadWrite.All","Team.Create","Channel.Create","TeamSettings.ReadWrite.All","TeamMember.ReadWrite.All" -TenantId "ce62e17d-2feb-4e67-a115-8ea4af68da30" -NoWelcome
Write-Host "Connected to Graph"

# Step 1: Team-enable the group
Write-Host "Enabling Teams on group $GroupId..."
$teamBody = @{
    memberSettings = @{ allowCreateUpdateChannels = $false; allowDeleteChannels = $false }
    guestSettings = @{ allowCreateUpdateChannels = $false; allowDeleteChannels = $false }
    messagingSettings = @{ allowOwnerDeleteMessages = $true; allowUserDeleteMessages = $false; allowUserEditMessages = $true }
}

$ok = $false; $try = 0
while ($try -lt 5 -and -not $ok) {
    try {
        $try++
        Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/v1.0/groups/$GroupId/team" -Body $teamBody
        $ok = $true
        Write-Host "✅ Team enabled!"
    } catch {
        Write-Host "  Retry $try/5 — $($_.Exception.Message)"
        Start-Sleep -Seconds 10
    }
}

if (-not $ok) {
    Write-Host "❌ Failed to team-enable. Exiting."
    exit 1
}

# Step 2: Add owners from Managers group
Write-Host "`n=== Adding Owners (Managers) ==="
$managersGroup = Get-MgGroup -All | Where-Object { $_.DisplayName -eq "Managers" } | Select-Object -First 1
if ($managersGroup) {
    $managers = Get-MgGroupMember -GroupId $managersGroup.Id -All
    foreach ($m in $managers) {
        try {
            $body = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($m.Id)" }
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups/$GroupId/owners/`$ref" -Body $body
            Write-Host "  ✅ Owner: $($m.AdditionalProperties.displayName)"
        } catch {
            if ($_.Exception.Message -match "already exist") { Write-Host "  ⏭️  Already owner: $($m.AdditionalProperties.displayName)" }
            else { Write-Host "  ⚠️  $($_.Exception.Message)" }
        }
    }
} else { Write-Host "  ⚠️  Managers group not found" }

# Step 3: Add members from AllStaff group
Write-Host "`n=== Adding Members (AllStaff) ==="
$allStaff = Get-MgGroup -All | Where-Object { $_.DisplayName -eq "AllStaff" } | Select-Object -First 1
if ($allStaff) {
    $staff = Get-MgGroupMember -GroupId $allStaff.Id -All
    foreach ($s in $staff) {
        try {
            $body = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($s.Id)" }
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups/$GroupId/members/`$ref" -Body $body
            Write-Host "  ✅ Member: $($s.AdditionalProperties.displayName)"
        } catch {
            if ($_.Exception.Message -match "already exist") { Write-Host "  ⏭️  Already member: $($s.AdditionalProperties.displayName)" }
            else { Write-Host "  ⚠️  $($_.Exception.Message)" }
        }
    }
} else { Write-Host "  ⚠️  AllStaff group not found" }

# Step 4: Create channels
Write-Host "`n=== Creating Channels ==="
$channels = @(
    @{ displayName = "Daily Ops"; description = "Shift reports, daily checklists, incident logs"; membershipType = "standard" }
    @{ displayName = "Bookings"; description = "Client booking coordination and scheduling"; membershipType = "standard" }
    @{ displayName = "Marketing"; description = "Marketing campaigns, social media, brand coordination"; membershipType = "standard" }
    @{ displayName = "Leadership"; description = "Management discussions — financials, HR, strategy"; membershipType = "private" }
)

foreach ($ch in $channels) {
    try {
        $existing = Get-MgTeamChannel -TeamId $GroupId | Where-Object { $_.DisplayName -eq $ch.displayName }
        if ($existing) {
            Write-Host "  ⏭️  Exists: $($ch.displayName)"
            continue
        }
        New-MgTeamChannel -TeamId $GroupId -BodyParameter $ch
        Write-Host "  ✅ Created: $($ch.displayName) [$($ch.membershipType)]"
    } catch {
        Write-Host "  ❌ $($ch.displayName): $($_.Exception.Message)"
    }
}

# Step 5: Verify
Write-Host "`n=== Final State ==="
$allChannels = Get-MgTeamChannel -TeamId $GroupId
foreach ($c in $allChannels) { Write-Host "  📣 $($c.DisplayName) [$($c.MembershipType)]" }

$members = Get-MgGroupMember -GroupId $GroupId -All
Write-Host "`nMembers: $($members.Count)"
$owners = Get-MgGroupOwner -GroupId $GroupId -All
Write-Host "Owners: $($owners.Count)"

Disconnect-MgGraph | Out-Null
Write-Host "`n🏁 Teams provisioning complete!"
