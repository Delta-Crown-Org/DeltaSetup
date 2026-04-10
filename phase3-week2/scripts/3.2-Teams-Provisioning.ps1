# ============================================================================
# PHASE 3.2: Teams Workspace Provisioning
# Delta Crown Extensions — Team, Channels, Tabs, Membership
# ============================================================================
# VERSION: 1.1.0
# DESCRIPTION: Creates "Delta Crown Operations" team with 5 channels,
#              configures tabs, sets membership from security groups
# DEPENDS ON: 3.1 (DCE-Operations site must exist)
# ADR: ADR-002 Phase 3 SharePoint Sites + Teams Collaboration
# FIXES: B3 (Team creation API), A3 (connection ownership), B7 (path seps)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="Microsoft.Graph.Teams";ModuleVersion="2.0.0"}, @{ModuleName="Microsoft.Graph.Groups";ModuleVersion="2.0.0"}, @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9-]{3,64}$')]
    [string]$TenantName = "deltacrownext",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",

    [Parameter(Mandatory=$false)]
    [string]$AdminUrl = "https://deltacrownext-admin.sharepoint.com"
)

# Error handling
$ErrorActionPreference = "Stop"
$scriptVersion = "1.1.0"

# ============================================================================
# PATH RESOLUTION & MODULE IMPORT (B7: Join-Path everywhere)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$ModulesPath = Join-Path $ProjectRoot (Join-Path "phase2-week1" "modules")
Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

$ConfigPath = Join-Path $ModulesPath "DeltaCrown.Config.psd1"
$Config = Import-PowerShellDataFile -Path $ConfigPath

# ============================================================================
# LOGGING
# ============================================================================
$LogPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" "logs")
if (!(Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$LogFile = Join-Path $LogPath "3.2-Teams-Provisioning-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# CONNECTION OWNERSHIP (A3: track who owns each connection)
# ============================================================================
$script:OwnsGraphConnection = $false
$script:OwnsPnPConnection = $false

# ============================================================================
# TEAM CONFIGURATION
# ============================================================================
$TeamConfig = @{
    DisplayName   = "Delta Crown Operations"
    Description   = "Daily operations hub for Delta Crown Extensions franchise"
    MailNickname  = "dce-operations"
    Visibility    = "Private"
    OwnerGroup    = "SG-DCE-Leadership"
    MemberGroup   = "SG-DCE-AllStaff"
}

$ChannelConfig = @(
    # General is auto-created — we configure it, not create it
    @{
        DisplayName = "Daily Ops"
        Description = "Shift reports, daily checklists, incident logs"
        MembershipType = "Standard"
        Tabs = @(
            @{ DisplayName = "Inventory"; Type = "SharePointList"; TargetSite = "/sites/dce-operations"; TargetList = "Inventory" }
        )
    },
    @{
        DisplayName = "Bookings"
        Description = "Client booking coordination and scheduling"
        MembershipType = "Standard"
        Tabs = @(
            @{ DisplayName = "Booking Tracker"; Type = "SharePointList"; TargetSite = "/sites/dce-operations"; TargetList = "Bookings" }
            @{ DisplayName = "Calendar"; Type = "SharePointList"; TargetSite = "/sites/dce-operations"; TargetList = "Calendar" }
        )
    },
    @{
        DisplayName = "Marketing"
        Description = "Marketing campaigns, social media, brand coordination"
        MembershipType = "Standard"
        Tabs = @(
            @{ DisplayName = "Brand Assets"; Type = "SharePointLibrary"; TargetSite = "/sites/dce-marketing"; TargetLibrary = "Brand Assets" }
            @{ DisplayName = "Campaigns"; Type = "SharePointList"; TargetSite = "/sites/dce-marketing"; TargetList = "Campaigns" }
            @{ DisplayName = "Social Calendar"; Type = "SharePointList"; TargetSite = "/sites/dce-marketing"; TargetList = "Social Calendar" }
        )
    },
    @{
        DisplayName = "Leadership"
        Description = "Management discussions — financials, HR, strategy"
        MembershipType = "Private"
        Tabs = @(
            @{ DisplayName = "Client Records"; Type = "SharePointList"; TargetSite = "/sites/dce-clientservices"; TargetList = "Client Records" }
            @{ DisplayName = "Docs & Policies"; Type = "SharePointLibrary"; TargetSite = "/sites/dce-docs"; TargetLibrary = "Policies" }
        )
    }
)

# Tabs for the General channel (configured separately since it auto-exists)
$GeneralChannelTabs = @(
    @{ DisplayName = "Staff Schedule"; Type = "SharePointList"; TargetSite = "/sites/dce-operations"; TargetList = "Staff Schedule" }
)

# ============================================================================
# HELPER FUNCTIONS (no connection management — caller owns the connection)
# ============================================================================

function Get-OrCreateTeam {
    <#
    .SYNOPSIS
        Creates M365 Group + Team. Assumes Graph context is active.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([hashtable]$Config)

    # Check if team already exists
    $existingGroup = Get-MgGroup -Filter "displayName eq '$($Config.DisplayName)'" -ErrorAction SilentlyContinue |
        Where-Object { $_.ResourceProvisioningOptions -contains "Team" } |
        Select-Object -First 1

    if ($existingGroup) {
        Write-DeltaCrownLog "Team already exists: $($Config.DisplayName) (ID: $($existingGroup.Id))" "WARNING"
        return $existingGroup
    }

    if ($PSCmdlet.ShouldProcess($Config.DisplayName, "Create M365 Group + Team")) {
        Write-DeltaCrownLog "Creating M365 Group: $($Config.DisplayName)" "INFO"

        # Step 1: Create M365 Group
        $group = New-MgGroup `
            -DisplayName $Config.DisplayName `
            -Description $Config.Description `
            -MailEnabled:$true `
            -SecurityEnabled:$true `
            -MailNickname $Config.MailNickname `
            -GroupTypes @("Unified") `
            -Visibility $Config.Visibility

        Write-DeltaCrownLog "M365 Group created: $($group.Id)" "SUCCESS"

        # Wait for group provisioning
        Start-Sleep -Seconds 15

        # Step 2: Team-enable the group (B3: use Graph REST, not New-MgTeam)
        Write-DeltaCrownLog "Enabling Teams on group..." "INFO"

        $teamBody = @{
            "memberSettings" = @{
                "allowCreateUpdateChannels" = $false
                "allowDeleteChannels" = $false
                "allowAddRemoveApps" = $false
                "allowCreateUpdateRemoveTabs" = $false
                "allowCreateUpdateRemoveConnectors" = $false
            }
            "guestSettings" = @{
                "allowCreateUpdateChannels" = $false
                "allowDeleteChannels" = $false
            }
            "funSettings" = @{
                "allowGiphy" = $false
                "allowStickersAndMemes" = $false
                "allowCustomMemes" = $false
            }
            "messagingSettings" = @{
                "allowOwnerDeleteMessages" = $true
                "allowUserDeleteMessages" = $false
                "allowUserEditMessages" = $true
                "allowTeamMentions" = $true
                "allowChannelMentions" = $true
            }
        }

        Invoke-DeltaCrownWithRetry -ScriptBlock {
            # B3 FIX: PUT to /groups/{id}/team enables Teams on existing group
            $teamUri = "https://graph.microsoft.com/v1.0/groups/$($group.Id)/team"
            Invoke-MgGraphRequest -Method PUT -Uri $teamUri -Body $teamBody
        } -OperationName "Team-enable group" -MaxRetries 5 -InitialDelaySeconds 10

        Write-DeltaCrownLog "Team enabled: $($Config.DisplayName)" "SUCCESS"

        Register-DeltaCrownRollbackAction `
            -ActionName "Remove team $($Config.DisplayName)" `
            -Action { param($ctx) Remove-MgGroup -GroupId $ctx.GroupId -Confirm:$false } `
            -Context @{ GroupId = $group.Id }

        return $group
    }
}

function Add-TeamChannel {
    <#
    .SYNOPSIS
        Creates a team channel. Assumes Graph context is active.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$TeamId,
        [hashtable]$ChannelConfig
    )

    # Check if channel exists
    $existing = Get-MgTeamChannel -TeamId $TeamId -Filter "displayName eq '$($ChannelConfig.DisplayName)'" -ErrorAction SilentlyContinue

    if ($existing) {
        Write-DeltaCrownLog "  Channel already exists: $($ChannelConfig.DisplayName)" "WARNING"
        return $existing
    }

    if ($PSCmdlet.ShouldProcess($ChannelConfig.DisplayName, "Create channel")) {
        $channelParams = @{
            TeamId       = $TeamId
            DisplayName  = $ChannelConfig.DisplayName
            Description  = $ChannelConfig.Description
            MembershipType = $ChannelConfig.MembershipType
        }

        $channel = New-MgTeamChannel @channelParams
        Write-DeltaCrownLog "  Created channel: $($ChannelConfig.DisplayName) ($($ChannelConfig.MembershipType))" "SUCCESS"

        # Wait for private channel SPO site provisioning
        if ($ChannelConfig.MembershipType -eq "Private") {
            Write-DeltaCrownLog "  Waiting for private channel SPO site provisioning..." "INFO"
            Start-Sleep -Seconds 30
        }

        return $channel
    }
}

function Add-ChannelTab {
    <#
    .SYNOPSIS
        Adds a SharePoint list/library tab to a channel.
        Assumes Graph context AND PnP context to TargetSite are managed by caller.
    #>
    [CmdletBinding()]
    param(
        [string]$TeamId,
        [string]$ChannelId,
        [hashtable]$TabConfig,
        [string]$TenantName
    )

    # Check existing tabs
    $existingTabs = Get-MgTeamChannelTab -TeamId $TeamId -ChannelId $ChannelId -ErrorAction SilentlyContinue
    $existing = $existingTabs | Where-Object { $_.DisplayName -eq $TabConfig.DisplayName }
    if ($existing) {
        Write-DeltaCrownLog "    Tab already exists: $($TabConfig.DisplayName)" "WARNING"
        return $existing
    }

    $siteUrl = "https://$TenantName.sharepoint.com$($TabConfig.TargetSite)"

    try {
        # Connect to the target site for list/library ID lookup
        Connect-DeltaCrownSharePoint -Url $siteUrl

        if ($TabConfig.Type -eq "SharePointList") {
            $list = Get-PnPList -Identity $TabConfig.TargetList -ErrorAction Stop
            $listUrl = "$siteUrl/Lists/$($TabConfig.TargetList -replace ' ','%20')"

            $tabBody = @{
                DisplayName     = $TabConfig.DisplayName
                "TeamsApp@odata.bind" = "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/2a527703-1f6f-4559-a332-d8a7d288cd88"
                Configuration   = @{
                    entityId    = $list.Id.Guid
                    contentUrl  = "$siteUrl/_layouts/15/TeamsLogon.aspx?SPFX=true&dest=$listUrl"
                    websiteUrl  = $listUrl
                    removeUrl   = $null
                }
            }
        }
        elseif ($TabConfig.Type -eq "SharePointLibrary") {
            $lib = Get-PnPList -Identity $TabConfig.TargetLibrary -ErrorAction Stop
            $libUrl = "$siteUrl/$($TabConfig.TargetLibrary -replace ' ','%20')"

            $tabBody = @{
                DisplayName     = $TabConfig.DisplayName
                "TeamsApp@odata.bind" = "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/2a527703-1f6f-4559-a332-d8a7d288cd88"
                Configuration   = @{
                    entityId    = $lib.Id.Guid
                    contentUrl  = "$siteUrl/_layouts/15/TeamsLogon.aspx?SPFX=true&dest=$libUrl"
                    websiteUrl  = $libUrl
                    removeUrl   = $null
                }
            }
        }

        New-MgTeamChannelTab -TeamId $TeamId -ChannelId $ChannelId -BodyParameter $tabBody
        Write-DeltaCrownLog "    Added tab: $($TabConfig.DisplayName) → $($TabConfig.TargetSite)" "SUCCESS"
    }
    catch {
        Write-DeltaCrownLog "    Failed to add tab $($TabConfig.DisplayName): $_" "WARNING"
    }
}

function Set-TeamMembership {
    <#
    .SYNOPSIS
        Syncs team membership from a security group. Assumes Graph context is active.
    #>
    [CmdletBinding()]
    param(
        [string]$GroupId,
        [string]$SecurityGroupName,
        [string]$Role  # "Owner" or "Member"
    )

    Write-DeltaCrownLog "Setting $Role membership from $SecurityGroupName..." "INFO"

    try {
        $sgGroup = Get-MgGroup -Filter "displayName eq '$SecurityGroupName'" -ErrorAction Stop | Select-Object -First 1
        if (!$sgGroup) {
            Write-DeltaCrownLog "Security group not found: $SecurityGroupName" "ERROR"
            return
        }

        $members = Get-MgGroupMember -GroupId $sgGroup.Id -All
        $existingMembers = Get-MgGroupMember -GroupId $GroupId -All

        $added = 0
        foreach ($member in $members) {
            $alreadyMember = $existingMembers | Where-Object { $_.Id -eq $member.Id }
            if ($alreadyMember) { continue }

            try {
                if ($Role -eq "Owner") {
                    New-MgGroupOwner -GroupId $GroupId -DirectoryObjectId $member.Id -ErrorAction SilentlyContinue
                }
                New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $member.Id -ErrorAction SilentlyContinue
                $added++
            }
            catch {
                # Member may already exist — non-fatal
                Write-DeltaCrownLog "  Could not add $($member.Id): $_" "DEBUG"
            }
        }

        Write-DeltaCrownLog "Added $added $($Role)s from $SecurityGroupName (total source: $($members.Count))" "SUCCESS"
    }
    catch {
        Write-DeltaCrownLog "Failed to set membership from $SecurityGroupName`: $_" "ERROR"
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownBanner "PHASE 3.2: Teams Workspace Provisioning"
    Write-DeltaCrownLog "Script Version: $scriptVersion" "INFO"
    Write-DeltaCrownLog "Tenant: $TenantName" "INFO"

    $results = @{
        TeamId         = $null
        ChannelsCreated = @()
        TabsCreated    = @()
        Errors         = @()
        StartTime      = Get-Date
    }

    # ------------------------------------------------------------------
    # CONNECTION SETUP (A3: check if Master pre-authed)
    # ------------------------------------------------------------------
    $existingGraph = Get-MgContext -ErrorAction SilentlyContinue
    if (!$existingGraph) {
        Connect-DeltaCrownGraph -RequiredScopes @(
            "Group.ReadWrite.All",
            "TeamSettings.ReadWrite.All",
            "Channel.Create",
            "TeamsTab.Create",
            "GroupMember.ReadWrite.All"
        )
        $script:OwnsGraphConnection = $true
    }
    else {
        Write-DeltaCrownLog "Using pre-established Graph connection" "INFO"
    }
    Write-DeltaCrownLog "Graph connection ready" "SUCCESS"

    $existingPnP = Get-PnPContext -ErrorAction SilentlyContinue
    if (!$existingPnP) {
        Connect-DeltaCrownSharePoint -Url $AdminUrl
        $script:OwnsPnPConnection = $true
    }
    else {
        Write-DeltaCrownLog "Using pre-established SharePoint connection" "INFO"
    }

    # ------------------------------------------------------------------
    # PRE-FLIGHT: Verify DCE-Operations exists
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Pre-Flight Checks ===" "STAGE"

    Connect-DeltaCrownSharePoint -Url $AdminUrl
    $opsUrl = "https://$TenantName.sharepoint.com/sites/dce-operations"
    $opsSite = Get-PnPTenantSite -Url $opsUrl -ErrorAction SilentlyContinue
    if (!$opsSite) {
        throw "DCE-Operations site not found at $opsUrl — Run 3.1-DCE-Sites-Provisioning.ps1 first."
    }
    Write-DeltaCrownLog "DCE-Operations verified: $opsUrl" "SUCCESS"

    # ------------------------------------------------------------------
    # STEP 1: Create M365 Group + Team
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 1: Create Team ===" "STAGE"

    $group = Get-OrCreateTeam -Config $TeamConfig
    $results.TeamId = $group.Id

    # Get team ID (wait for Team provisioning)
    $team = Invoke-DeltaCrownWithRetry -ScriptBlock {
        Get-MgTeam -TeamId $group.Id -ErrorAction Stop
    } -OperationName "Get team details" -MaxRetries 5 -InitialDelaySeconds 10

    Write-DeltaCrownLog "Team ready: $($team.DisplayName) (ID: $($team.Id))" "SUCCESS"

    # ------------------------------------------------------------------
    # STEP 2: Configure General channel tabs
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 2: Configure General Channel ===" "STAGE"

    $generalChannel = Get-MgTeamChannel -TeamId $team.Id -Filter "displayName eq 'General'" | Select-Object -First 1

    foreach ($tab in $GeneralChannelTabs) {
        Add-ChannelTab -TeamId $team.Id -ChannelId $generalChannel.Id -TabConfig $tab -TenantName $TenantName
        $results.TabsCreated += "General/$($tab.DisplayName)"
    }

    # ------------------------------------------------------------------
    # STEP 3: Create channels + tabs
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 3: Create Channels ===" "STAGE"

    foreach ($chConfig in $ChannelConfig) {
        try {
            $channel = Add-TeamChannel -TeamId $team.Id -ChannelConfig $chConfig
            $results.ChannelsCreated += $chConfig.DisplayName

            # Add tabs to channel
            if ($channel -and $chConfig.Tabs.Count -gt 0) {
                foreach ($tab in $chConfig.Tabs) {
                    Add-ChannelTab -TeamId $team.Id -ChannelId $channel.Id -TabConfig $tab -TenantName $TenantName
                    $results.TabsCreated += "$($chConfig.DisplayName)/$($tab.DisplayName)"
                }
            }
        }
        catch {
            Write-DeltaCrownLog "Failed to create channel $($chConfig.DisplayName): $_" "ERROR"
            $results.Errors += "Channel creation failed: $($chConfig.DisplayName) — $_"
        }
    }

    # ------------------------------------------------------------------
    # STEP 4: Set team membership from security groups
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 4: Set Team Membership ===" "STAGE"

    Set-TeamMembership -GroupId $group.Id -SecurityGroupName $TeamConfig.OwnerGroup -Role "Owner"
    Set-TeamMembership -GroupId $group.Id -SecurityGroupName $TeamConfig.MemberGroup -Role "Member"

    # ------------------------------------------------------------------
    # STEP 5: Associate Leadership private channel SPO site with Hub
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 5: Associate Leadership Channel SPO with DCE Hub ===" "STAGE"

    try {
        Connect-DeltaCrownSharePoint -Url $AdminUrl

        # Find the auto-created private channel site
        $leadershipSites = Get-PnPTenantSite | Where-Object {
            $_.Url -match "dce-operations" -and $_.Url -match "Leadership"
        }

        if ($leadershipSites) {
            $dceHubUrl = "https://$TenantName.sharepoint.com/sites/dce-hub"
            foreach ($site in $leadershipSites) {
                $isAssociated = Get-PnPHubSiteChild -Identity $dceHubUrl -ErrorAction SilentlyContinue |
                    Where-Object { $_ -eq $site.Url }

                if (!$isAssociated) {
                    Add-PnPHubSiteAssociation -Site $site.Url -HubSite $dceHubUrl
                    Write-DeltaCrownLog "Associated Leadership channel site with DCE Hub: $($site.Url)" "SUCCESS"
                }
                else {
                    Write-DeltaCrownLog "Leadership site already associated with hub" "WARNING"
                }
            }
        }
        else {
            Write-DeltaCrownLog "Leadership private channel SPO site not found yet — may need manual association" "WARNING"
        }
    }
    catch {
        Write-DeltaCrownLog "Failed to associate Leadership SPO with hub: $_" "WARNING"
        $results.Errors += "Leadership hub association: $_"
    }

    # ------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------
    $results.EndTime = Get-Date
    $duration = $results.EndTime - $results.StartTime

    Write-DeltaCrownBanner "PHASE 3.2 COMPLETE"
    Write-DeltaCrownLog "Team ID:            $($results.TeamId)" "SUCCESS"
    Write-DeltaCrownLog "Channels created:   $($results.ChannelsCreated.Count)/4" "SUCCESS"
    Write-DeltaCrownLog "Tabs configured:    $($results.TabsCreated.Count)" "SUCCESS"
    Write-DeltaCrownLog "Errors:             $($results.Errors.Count)" $(if($results.Errors.Count -gt 0){"ERROR"}else{"SUCCESS"})
    Write-DeltaCrownLog "Duration:           $($duration.TotalMinutes.ToString('F1')) minutes" "INFO"

    $resultsPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" (Join-Path "docs" "3.2-teams-results.json"))
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Force

    Clear-DeltaCrownRollbackStack
    Export-DeltaCrownLogBuffer -Path $LogFile

    return [PSCustomObject]@{
        TeamId           = $results.TeamId
        ChannelsCreated  = $results.ChannelsCreated
        TabsCreated      = $results.TabsCreated
        Errors           = $results.Errors
        Duration         = $duration
        Status           = if ($results.Errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Phase 3.2: $_" "CRITICAL"
    Write-DeltaCrownLog "Stack Trace: $($_.ScriptStackTrace)" "ERROR"

    try { Invoke-DeltaCrownRollback -Reason "Phase 3.2 failed: $_" -ContinueOnError } catch {}

    Export-DeltaCrownLogBuffer -Path $LogFile
    throw
}
finally {
    if ($script:OwnsGraphConnection) { Disconnect-MgGraph -ErrorAction SilentlyContinue }
    if ($script:OwnsPnPConnection) { Disconnect-PnPOnline -ErrorAction SilentlyContinue }
    Write-DeltaCrownLog "Disconnected from Graph + SharePoint" "INFO"
}
