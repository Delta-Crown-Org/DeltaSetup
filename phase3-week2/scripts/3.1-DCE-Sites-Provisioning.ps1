# ============================================================================
# PHASE 3.1: DCE SharePoint Sites Provisioning
# Delta Crown Extensions — Brand Sites, Lists, Libraries, Columns
# ============================================================================
# VERSION: 1.1.0
# DESCRIPTION: Creates 4 DCE SharePoint sites with full schema:
#              DCE-Operations, DCE-ClientServices, DCE-Marketing, DCE-Docs
# DEPENDS ON: Phase 2 complete (DCE Hub exists, Azure AD groups exist)
# ADR: ADR-002 Phase 3 SharePoint Sites + Teams Collaboration
# FIXES: A3 (connection ownership), B7 (path separators),
#        Read-Host removal (automation-safe)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^https://[a-zA-Z0-9-]+\.sharepoint\.com(/.*)?$')]
    [string]$AdminUrl = "https://deltacrown-admin.sharepoint.com",

    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9-]{3,64}$')]
    [string]$TenantName = "deltacrown",

    [Parameter(Mandatory=$false)]
    [string]$DCEHubUrl = "/sites/dce-hub",

    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$OwnerEmail = $null,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Development", "Staging", "Production")]
    [string]$Environment = "Development",

    [Parameter(Mandatory=$false)]
    [switch]$SkipHubAssociation,

    [Parameter(Mandatory=$false)]
    [switch]$SkipBranding
)

# Error handling
$ErrorActionPreference = "Stop"
$scriptVersion = "1.1.0"

# ============================================================================
# PATH RESOLUTION (B7: Join-Path everywhere)
# ============================================================================
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

# ============================================================================
# MODULE IMPORT
# ============================================================================
$ModulesPath = Join-Path $ProjectRoot (Join-Path "phase2-week1" "modules")

Import-Module (Join-Path $ModulesPath "DeltaCrown.Auth.psm1") -Force -ErrorAction Stop
Import-Module (Join-Path $ModulesPath "DeltaCrown.Common.psm1") -Force -ErrorAction Stop

# Load configuration
$ConfigPath = Join-Path $ModulesPath "DeltaCrown.Config.psd1"
$Config = Import-PowerShellDataFile -Path $ConfigPath

# ============================================================================
# LOGGING SETUP
# ============================================================================
$LogPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" "logs")
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}
$LogFile = Join-Path $LogPath "3.1-Sites-Provisioning-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================
# CONNECTION OWNERSHIP (A3: track who owns the connection)
# ============================================================================
$script:OwnsPnPConnection = $false

# ============================================================================
# BRANDING CONFIGURATION (from Config)
# ============================================================================
$BrandColors = $Config.Branding.Colors
$ThemeName = $Config.Branding.ThemeName

# ============================================================================
# SITE DEFINITIONS
# ============================================================================
$DCESites = @(
    @{
        Url          = "/sites/dce-operations"
        Title        = "DCE Operations"
        Description  = "Delta Crown Extensions daily operations hub"
        Template     = "STS#3"
        Type         = "TeamSite"
        TeamsConnected = $true
    },
    @{
        Url          = "/sites/dce-clientservices"
        Title        = "DCE Client Services"
        Description  = "Client records, service catalog, and feedback"
        Template     = "STS#3"
        Type         = "TeamSite"
        TeamsConnected = $false
    },
    @{
        Url          = "/sites/dce-marketing"
        Title        = "DCE Marketing"
        Description  = "Brand assets, campaigns, and social media coordination"
        Template     = "SITEPAGEPUBLISHING#0"
        Type         = "CommunicationSite"
        TeamsConnected = $false
    },
    @{
        Url          = "/sites/dce-docs"
        Title        = "DCE Document Center"
        Description  = "Central document repository — policies, training, forms"
        Template     = "STS#3"
        Type         = "TeamSite"
        TeamsConnected = $false
    }
)

# ============================================================================
# LIST & LIBRARY DEFINITIONS PER SITE
# ============================================================================

$SiteSchemas = @{
    # ------------------------------------------------------------------
    # DCE-OPERATIONS
    # ------------------------------------------------------------------
    "/sites/dce-operations" = @{
        Libraries = @(
            @{ Title = "Daily Ops"; Description = "Shift reports, daily checklists, incident logs" }
            # Note: "Documents" (Shared Documents) is auto-created with Team Sites
        )
        Lists = @(
            @{
                Title = "Bookings"
                Description = "Client booking tracker"
                Columns = @(
                    @{ Name = "ServiceType";  DisplayName = "Service Type";  Type = "Choice"; Choices = @("Extensions","Maintenance","Removal","Consultation"); Required = $true }
                    @{ Name = "BookingDate";  DisplayName = "Booking Date";  Type = "DateTime"; Required = $true }
                    @{ Name = "Stylist";      DisplayName = "Stylist";       Type = "User"; Required = $true }
                    @{ Name = "Status";       DisplayName = "Status";        Type = "Choice"; Choices = @("Confirmed","Pending","Completed","Cancelled","No-Show"); Required = $true }
                    @{ Name = "Notes";        DisplayName = "Notes";         Type = "Note"; Required = $false }
                    @{ Name = "Revenue";      DisplayName = "Revenue";       Type = "Currency"; Required = $false }
                )
                Views = @(
                    @{ Title = "Today's Bookings"; Query = "<Where><Eq><FieldRef Name='BookingDate' /><Value Type='DateTime'><Today /></Value></Eq></Where>"; Fields = @("LinkTitle","ServiceType","BookingDate","Stylist","Status") }
                    @{ Title = "Pending";          Query = "<Where><Eq><FieldRef Name='Status' /><Value Type='Choice'>Pending</Value></Eq></Where>";           Fields = @("LinkTitle","ServiceType","BookingDate","Stylist","Status","Notes") }
                )
            },
            @{
                Title = "Staff Schedule"
                Description = "Weekly staff roster and shift schedule"
                Columns = @(
                    @{ Name = "StaffMember";  DisplayName = "Staff Member";  Type = "User"; Required = $true }
                    @{ Name = "ShiftDate";    DisplayName = "Shift Date";    Type = "DateTime"; Required = $true }
                    @{ Name = "StartTime";    DisplayName = "Start Time";    Type = "DateTime"; Required = $true }
                    @{ Name = "EndTime";      DisplayName = "End Time";      Type = "DateTime"; Required = $true }
                    @{ Name = "Location";     DisplayName = "Location";      Type = "Choice"; Choices = @("Main Salon","CBD Studio","Mobile"); Required = $true }
                    @{ Name = "Role";         DisplayName = "Role";          Type = "Choice"; Choices = @("Stylist","Reception","Manager","Trainee"); Required = $true }
                    @{ Name = "Notes";        DisplayName = "Notes";         Type = "Note"; Required = $false }
                )
                Views = @(
                    @{ Title = "This Week"; Query = "<Where><And><Geq><FieldRef Name='ShiftDate' /><Value Type='DateTime'><Today /></Value></Geq><Leq><FieldRef Name='ShiftDate' /><Value Type='DateTime'><Today OffsetDays='7' /></Value></Leq></And></Where>"; Fields = @("StaffMember","ShiftDate","StartTime","EndTime","Location","Role") }
                )
            },
            @{
                Title = "Tasks"
                Description = "Operational task tracking"
                Columns = @(
                    @{ Name = "AssignedTo";   DisplayName = "Assigned To";   Type = "User"; Required = $true }
                    @{ Name = "DueDate";      DisplayName = "Due Date";      Type = "DateTime"; Required = $true }
                    @{ Name = "Priority";     DisplayName = "Priority";      Type = "Choice"; Choices = @("Urgent","High","Medium","Low"); Required = $true }
                    @{ Name = "TaskStatus";   DisplayName = "Status";        Type = "Choice"; Choices = @("Not Started","In Progress","Completed","Blocked"); Required = $true }
                    @{ Name = "Category";     DisplayName = "Category";      Type = "Choice"; Choices = @("Operations","Maintenance","Admin","Training"); Required = $true }
                    @{ Name = "Description";  DisplayName = "Description";   Type = "Note"; Required = $false }
                )
                Views = @(
                    @{ Title = "Active Tasks"; Query = "<Where><Neq><FieldRef Name='TaskStatus' /><Value Type='Choice'>Completed</Value></Neq></Where>"; Fields = @("LinkTitle","AssignedTo","DueDate","Priority","TaskStatus","Category") }
                    @{ Title = "My Tasks";     Query = "<Where><And><Eq><FieldRef Name='AssignedTo' /><Value Type='User'><UserID /></Value></Eq><Neq><FieldRef Name='TaskStatus' /><Value Type='Choice'>Completed</Value></Neq></And></Where>"; Fields = @("LinkTitle","DueDate","Priority","TaskStatus","Category") }
                )
            },
            @{
                Title = "Inventory"
                Description = "Product inventory tracker"
                Columns = @(
                    @{ Name = "SKU";          DisplayName = "SKU";           Type = "Text"; Required = $true }
                    @{ Name = "Category";     DisplayName = "Category";      Type = "Choice"; Choices = @("Hair Extensions","Adhesives","Tools","Care Products","Accessories"); Required = $true }
                    @{ Name = "Quantity";     DisplayName = "Quantity";      Type = "Number"; Required = $true }
                    @{ Name = "ReorderLevel"; DisplayName = "Reorder Level"; Type = "Number"; Required = $false }
                    @{ Name = "Supplier";     DisplayName = "Supplier";      Type = "Text"; Required = $false }
                    @{ Name = "UnitCost";     DisplayName = "Unit Cost";     Type = "Currency"; Required = $false }
                    @{ Name = "LastRestocked"; DisplayName = "Last Restocked"; Type = "DateTime"; Required = $false }
                )
                Views = @(
                    @{ Title = "Low Stock"; Query = "<Where><Leq><FieldRef Name='Quantity' /><FieldRef Name='ReorderLevel' /></Where>"; Fields = @("LinkTitle","SKU","Category","Quantity","ReorderLevel","Supplier") }
                )
            },
            @{
                Title = "Calendar"
                Description = "Team calendar — syncs to Outlook"
                TemplateType = 106   # Events list template (B2: confirmed correct)
                Columns = @()
                Views = @()
            }
        )
    }

    # ------------------------------------------------------------------
    # DCE-CLIENTSERVICES
    # ------------------------------------------------------------------
    "/sites/dce-clientservices" = @{
        Libraries = @(
            @{ Title = "Consent Forms"; Description = "Signed client consent PDFs" }
        )
        Lists = @(
            @{
                Title = "Client Records"
                Description = "Client service history and contact details (PII)"
                Columns = @(
                    @{ Name = "Email";           DisplayName = "Email";            Type = "Text"; Required = $false }
                    @{ Name = "Phone";           DisplayName = "Phone";            Type = "Text"; Required = $false }
                    @{ Name = "ServiceHistory";  DisplayName = "Service History";  Type = "Note"; Required = $false }
                    @{ Name = "LastVisit";       DisplayName = "Last Visit";       Type = "DateTime"; Required = $false }
                    @{ Name = "PreferredStylist"; DisplayName = "Preferred Stylist"; Type = "User"; Required = $false }
                    @{ Name = "AllergyNotes";    DisplayName = "Allergy/Notes";    Type = "Note"; Required = $false }
                    @{ Name = "TotalSpend";      DisplayName = "Total Spend";      Type = "Currency"; Required = $false }
                    @{ Name = "VIPStatus";       DisplayName = "VIP Status";       Type = "Boolean"; Required = $false }
                )
                Views = @(
                    @{ Title = "All Clients";  Query = ""; Fields = @("LinkTitle","Email","Phone","LastVisit","PreferredStylist","VIPStatus") }
                    @{ Title = "VIP Clients";  Query = "<Where><Eq><FieldRef Name='VIPStatus' /><Value Type='Boolean'>1</Value></Eq></Where>"; Fields = @("LinkTitle","Email","Phone","LastVisit","TotalSpend") }
                )
            },
            @{
                Title = "Service Catalog"
                Description = "Services offered and pricing"
                Columns = @(
                    @{ Name = "ServiceCategory"; DisplayName = "Category";    Type = "Choice"; Choices = @("Extensions","Maintenance","Removal","Consultation","Styling"); Required = $true }
                    @{ Name = "Duration";        DisplayName = "Duration (min)"; Type = "Number"; Required = $true }
                    @{ Name = "Price";           DisplayName = "Price";       Type = "Currency"; Required = $true }
                    @{ Name = "Description";     DisplayName = "Description"; Type = "Note"; Required = $false }
                    @{ Name = "Active";          DisplayName = "Active";      Type = "Boolean"; Required = $true }
                )
                Views = @(
                    @{ Title = "Active Services"; Query = "<Where><Eq><FieldRef Name='Active' /><Value Type='Boolean'>1</Value></Eq></Where>"; Fields = @("LinkTitle","ServiceCategory","Duration","Price") }
                )
            },
            @{
                Title = "Feedback"
                Description = "Client satisfaction and feedback tracker"
                Columns = @(
                    @{ Name = "ClientName";    DisplayName = "Client Name";    Type = "Text"; Required = $true }
                    @{ Name = "ServiceDate";   DisplayName = "Service Date";   Type = "DateTime"; Required = $true }
                    @{ Name = "Rating";        DisplayName = "Rating (1-5)";   Type = "Number"; Required = $true }
                    @{ Name = "FeedbackType";  DisplayName = "Type";           Type = "Choice"; Choices = @("Compliment","Suggestion","Complaint","General"); Required = $true }
                    @{ Name = "Comments";      DisplayName = "Comments";       Type = "Note"; Required = $false }
                    @{ Name = "FollowUp";      DisplayName = "Follow-Up Required"; Type = "Boolean"; Required = $false }
                    @{ Name = "ResolvedBy";    DisplayName = "Resolved By";    Type = "User"; Required = $false }
                )
                Views = @(
                    @{ Title = "Needs Follow-Up"; Query = "<Where><Eq><FieldRef Name='FollowUp' /><Value Type='Boolean'>1</Value></Eq></Where>"; Fields = @("ClientName","ServiceDate","Rating","FeedbackType","Comments") }
                )
            }
        )
    }

    # ------------------------------------------------------------------
    # DCE-MARKETING
    # ------------------------------------------------------------------
    "/sites/dce-marketing" = @{
        Libraries = @(
            @{ Title = "Brand Assets"; Description = "Logos, photos, videos, brand guidelines" }
            @{ Title = "Templates";    Description = "Marketing templates — flyers, social posts, email" }
        )
        Lists = @(
            @{
                Title = "Campaigns"
                Description = "Marketing campaign tracker"
                Columns = @(
                    @{ Name = "StartDate";      DisplayName = "Start Date";      Type = "DateTime"; Required = $true }
                    @{ Name = "EndDate";        DisplayName = "End Date";        Type = "DateTime"; Required = $true }
                    @{ Name = "Channel";        DisplayName = "Channel";         Type = "Choice"; Choices = @("Instagram","Facebook","TikTok","Email","In-Store","Google"); Required = $true }
                    @{ Name = "CampaignStatus"; DisplayName = "Status";          Type = "Choice"; Choices = @("Planning","Active","Paused","Completed"); Required = $true }
                    @{ Name = "Budget";         DisplayName = "Budget";          Type = "Currency"; Required = $false }
                    @{ Name = "TargetAudience"; DisplayName = "Target Audience"; Type = "Note"; Required = $false }
                    @{ Name = "Results";        DisplayName = "Results";         Type = "Note"; Required = $false }
                    @{ Name = "CampaignOwner";  DisplayName = "Owner";           Type = "User"; Required = $true }
                )
                Views = @(
                    @{ Title = "Active Campaigns"; Query = "<Where><Eq><FieldRef Name='CampaignStatus' /><Value Type='Choice'>Active</Value></Eq></Where>"; Fields = @("LinkTitle","Channel","StartDate","EndDate","CampaignStatus","CampaignOwner","Budget") }
                )
            },
            @{
                Title = "Social Calendar"
                Description = "Social media posting schedule"
                Columns = @(
                    @{ Name = "PostDate";       DisplayName = "Post Date";       Type = "DateTime"; Required = $true }
                    @{ Name = "Platform";       DisplayName = "Platform";        Type = "Choice"; Choices = @("Instagram","Facebook","TikTok","LinkedIn","Google Business"); Required = $true }
                    @{ Name = "ContentType";    DisplayName = "Content Type";    Type = "Choice"; Choices = @("Photo","Video","Reel","Story","Carousel","Text"); Required = $true }
                    @{ Name = "Caption";        DisplayName = "Caption";         Type = "Note"; Required = $false }
                    @{ Name = "PostStatus";     DisplayName = "Status";          Type = "Choice"; Choices = @("Draft","Scheduled","Published","Cancelled"); Required = $true }
                    @{ Name = "Hashtags";       DisplayName = "Hashtags";        Type = "Note"; Required = $false }
                    @{ Name = "PostOwner";      DisplayName = "Owner";           Type = "User"; Required = $true }
                )
                Views = @(
                    @{ Title = "This Week"; Query = "<Where><And><Geq><FieldRef Name='PostDate' /><Value Type='DateTime'><Today /></Value></Geq><Leq><FieldRef Name='PostDate' /><Value Type='DateTime'><Today OffsetDays='7' /></Value></Leq></And></Where>"; Fields = @("LinkTitle","PostDate","Platform","ContentType","PostStatus","PostOwner") }
                )
            }
        )
    }

    # ------------------------------------------------------------------
    # DCE-DOCS (Document Center pattern — 5 libraries, metadata columns)
    # ------------------------------------------------------------------
    "/sites/dce-docs" = @{
        Libraries = @(
            @{ Title = "Policies";  Description = "Company policies and SOPs" }
            @{ Title = "Training";  Description = "Training materials and videos" }
            @{ Title = "Forms";     Description = "Standardized forms" }
            @{ Title = "Templates"; Description = "Document templates" }
            @{ Title = "Archive";   Description = "Historical documents" }
        )
        # Metadata columns applied to ALL libraries (not lists)
        LibraryMetadata = @(
            @{ Name = "DocType";    DisplayName = "Document Type"; Type = "Choice"; Choices = @("Policy","SOP","Form","Template","Training","Reference"); Required = $false }
            @{ Name = "Department"; DisplayName = "Department";    Type = "Choice"; Choices = @("Operations","Marketing","Finance","HR","IT"); Required = $false }
            @{ Name = "ReviewDate"; DisplayName = "Review Date";   Type = "DateTime"; Required = $false }
            @{ Name = "DocVersion"; DisplayName = "Version";       Type = "Number"; Required = $false }
            @{ Name = "DocStatus";  DisplayName = "Status";        Type = "Choice"; Choices = @("Draft","Under Review","Published","Archived"); Required = $false }
            @{ Name = "DocOwner";   DisplayName = "Owner";         Type = "User"; Required = $false }
        )
        Lists = @()
    }
}

# ============================================================================
# HELPER FUNCTIONS (no connection management — caller owns the connection)
# ============================================================================

function New-DCESiteCollection {
    <#
    .SYNOPSIS
        Creates a site collection. Assumes admin PnP context is active.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [hashtable]$SiteConfig,
        [string]$Owner,
        [string]$TenantName
    )

    $siteUrl = "https://$TenantName.sharepoint.com$($SiteConfig.Url)"

    # Idempotency check
    $existing = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue
    if ($existing) {
        Write-DeltaCrownLog "Site already exists: $siteUrl — skipping creation" "WARNING"
        return $existing
    }

    if ($PSCmdlet.ShouldProcess($siteUrl, "Create site collection")) {
        Write-DeltaCrownLog "Creating site: $($SiteConfig.Title) ($siteUrl)" "INFO"

        # B1: CommunicationSite expects full URL — confirmed correct
        if ($SiteConfig.Type -eq "CommunicationSite") {
            New-PnPSite -Type CommunicationSite `
                -Title $SiteConfig.Title `
                -Url $siteUrl `
                -Description $SiteConfig.Description `
                -Owner $Owner `
                -Lcid 1033 `
                -TimeZone 10 `
                -Wait
        }
        else {
            New-PnPSite -Type TeamSiteWithoutMicrosoft365Group `
                -Title $SiteConfig.Title `
                -Url $siteUrl `
                -Description $SiteConfig.Description `
                -Owner $Owner `
                -Lcid 1033 `
                -TimeZone 10 `
                -Wait
        }

        # Wait for provisioning
        Wait-DeltaCrownSiteProvisioned -SiteUrl $siteUrl -TimeoutSeconds 120
        Write-DeltaCrownLog "Site created: $siteUrl" "SUCCESS"
    }

    return Get-PnPTenantSite -Url $siteUrl
}

function Add-DCEDocumentLibrary {
    <#
    .SYNOPSIS
        Creates a document library. Assumes site PnP context is active.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Title,
        [string]$Description
    )

    $existing = Get-PnPList -Identity $Title -ErrorAction SilentlyContinue
    if ($existing) {
        Write-DeltaCrownLog "  Library already exists: $Title — skipping" "WARNING"
        return $existing
    }

    if ($PSCmdlet.ShouldProcess($Title, "Create document library")) {
        $library = New-PnPList -Title $Title -Template DocumentLibrary -ErrorAction Stop
        Set-PnPList -Identity $Title -Description $Description
        Write-DeltaCrownLog "  Created library: $Title" "SUCCESS"
        return $library
    }
}

function Add-DCESharePointList {
    <#
    .SYNOPSIS
        Creates a list with columns and views. Assumes site PnP context is active.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [hashtable]$ListConfig
    )

    $existing = Get-PnPList -Identity $ListConfig.Title -ErrorAction SilentlyContinue
    if ($existing) {
        Write-DeltaCrownLog "  List already exists: $($ListConfig.Title) — skipping" "WARNING"
        return $existing
    }

    if ($PSCmdlet.ShouldProcess($ListConfig.Title, "Create SharePoint list")) {
        # B2: TemplateType 106 = Events list — confirmed correct for Calendar
        if ($ListConfig.ContainsKey("TemplateType")) {
            $list = New-PnPList -Title $ListConfig.Title -Template $ListConfig.TemplateType -ErrorAction Stop
        }
        else {
            $list = New-PnPList -Title $ListConfig.Title -Template GenericList -ErrorAction Stop
        }

        Set-PnPList -Identity $ListConfig.Title -Description $ListConfig.Description

        # Add columns
        foreach ($col in $ListConfig.Columns) {
            Add-DCEListColumn -ListTitle $ListConfig.Title -ColumnConfig $col
        }

        # Add views
        foreach ($view in $ListConfig.Views) {
            Add-DCEListView -ListTitle $ListConfig.Title -ViewConfig $view
        }

        Write-DeltaCrownLog "  Created list: $($ListConfig.Title) ($($ListConfig.Columns.Count) columns, $($ListConfig.Views.Count) views)" "SUCCESS"
        return $list
    }
}

function Add-DCEListColumn {
    [CmdletBinding()]
    param(
        [string]$ListTitle,
        [hashtable]$ColumnConfig
    )

    $existingField = Get-PnPField -List $ListTitle -Identity $ColumnConfig.Name -ErrorAction SilentlyContinue
    if ($existingField) {
        Write-DeltaCrownLog "    Column already exists: $($ColumnConfig.DisplayName) — skipping" "DEBUG"
        return
    }

    $fieldParams = @{
        List         = $ListTitle
        InternalName = $ColumnConfig.Name
        DisplayName  = $ColumnConfig.DisplayName
        Required     = $ColumnConfig.Required
        AddToDefaultView = $true
    }

    switch ($ColumnConfig.Type) {
        "Text"     { Add-PnPField @fieldParams -Type Text }
        "Note"     { Add-PnPField @fieldParams -Type Note }
        "Choice"   { Add-PnPField @fieldParams -Type Choice -Choices $ColumnConfig.Choices }
        "DateTime" { Add-PnPField @fieldParams -Type DateTime }
        "User"     { Add-PnPField @fieldParams -Type User }
        "Number"   { Add-PnPField @fieldParams -Type Number }
        "Currency" { Add-PnPField @fieldParams -Type Currency }
        "Boolean"  { Add-PnPField @fieldParams -Type Boolean }
        default    { Write-DeltaCrownLog "    Unknown column type: $($ColumnConfig.Type) for $($ColumnConfig.DisplayName)" "WARNING" }
    }

    Write-DeltaCrownLog "    Added column: $($ColumnConfig.DisplayName) ($($ColumnConfig.Type))" "DEBUG"
}

function Add-DCEListView {
    [CmdletBinding()]
    param(
        [string]$ListTitle,
        [hashtable]$ViewConfig
    )

    $existing = Get-PnPView -List $ListTitle -Identity $ViewConfig.Title -ErrorAction SilentlyContinue
    if ($existing) {
        Write-DeltaCrownLog "    View already exists: $($ViewConfig.Title) — skipping" "DEBUG"
        return
    }

    $viewParams = @{
        List   = $ListTitle
        Title  = $ViewConfig.Title
        Fields = $ViewConfig.Fields
    }

    if ($ViewConfig.Query) {
        $viewParams.Query = $ViewConfig.Query
    }

    Add-PnPView @viewParams
    Write-DeltaCrownLog "    Added view: $($ViewConfig.Title)" "DEBUG"
}

function Add-DCELibraryMetadata {
    [CmdletBinding()]
    param(
        [string]$LibraryTitle,
        [array]$MetadataColumns
    )

    foreach ($col in $MetadataColumns) {
        $colConfig = @{
            Name        = $col.Name
            DisplayName = $col.DisplayName
            Type        = $col.Type
            Required    = $col.Required
        }
        if ($col.ContainsKey("Choices")) {
            $colConfig.Choices = $col.Choices
        }
        Add-DCEListColumn -ListTitle $LibraryTitle -ColumnConfig $colConfig
    }

    Write-DeltaCrownLog "  Applied $($MetadataColumns.Count) metadata columns to: $LibraryTitle" "SUCCESS"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-DeltaCrownBanner "PHASE 3.1: DCE SharePoint Sites Provisioning"
    Write-DeltaCrownLog "Script Version: $scriptVersion" "INFO"
    Write-DeltaCrownLog "Tenant: $TenantName" "INFO"
    Write-DeltaCrownLog "Environment: $Environment" "INFO"
    Write-DeltaCrownLog "Log file: $LogFile" "INFO"

    # ------------------------------------------------------------------
    # CONNECTION SETUP (A3: check if Master pre-authed)
    # ------------------------------------------------------------------
    $existingCtx = Get-PnPContext -ErrorAction SilentlyContinue
    if (!$existingCtx) {
        Connect-DeltaCrownSharePoint -Url $AdminUrl
        $script:OwnsPnPConnection = $true
    }
    else {
        Write-DeltaCrownLog "Using pre-established SharePoint connection" "INFO"
    }

    # ------------------------------------------------------------------
    # PRE-FLIGHT: Validate Phase 2 prerequisites
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Pre-Flight Checks ===" "STAGE"

    $dceHubFullUrl = "https://$TenantName.sharepoint.com$DCEHubUrl"

    # Ensure we're on admin context for tenant operations
    Connect-DeltaCrownSharePoint -Url $AdminUrl
    Write-DeltaCrownLog "Connected to SharePoint Admin" "SUCCESS"

    # Verify DCE Hub exists
    $hub = Get-PnPHubSite -Identity $dceHubFullUrl -ErrorAction SilentlyContinue
    if (!$hub) {
        throw "DCE Hub not found at $dceHubFullUrl — Phase 2 must be complete before running Phase 3."
    }
    Write-DeltaCrownLog "DCE Hub verified: $dceHubFullUrl" "SUCCESS"

    # Get owner (no Read-Host — fail clearly if not provided)
    if (!$OwnerEmail) {
        $OwnerEmail = $env:DCE_ADMIN_EMAIL
        if (!$OwnerEmail) {
            throw "OwnerEmail is required. Pass -OwnerEmail or set DCE_ADMIN_EMAIL environment variable."
        }
    }

    # Track results
    $results = @{
        SitesCreated     = @()
        ListsCreated     = @()
        LibrariesCreated = @()
        Errors           = @()
        StartTime        = Get-Date
    }

    # ------------------------------------------------------------------
    # STEP 1: Create all 4 site collections
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 1: Create Site Collections ===" "STAGE"

    foreach ($siteConfig in $DCESites) {
        try {
            $site = New-DCESiteCollection -SiteConfig $siteConfig -Owner $OwnerEmail -TenantName $TenantName
            $results.SitesCreated += $siteConfig.Url

            # Register rollback
            Register-DeltaCrownRollbackAction `
                -ActionName "Remove site $($siteConfig.Url)" `
                -Action {
                    param($ctx)
                    Remove-PnPTenantSite -Url "https://$($ctx.Tenant).sharepoint.com$($ctx.Url)" -Force -SkipRecycleBin
                } `
                -Context @{ Url = $siteConfig.Url; Tenant = $TenantName }
        }
        catch {
            Write-DeltaCrownLog "Failed to create site $($siteConfig.Url): $_" "ERROR"
            $results.Errors += "Site creation failed: $($siteConfig.Url) — $_"
        }
    }

    Write-DeltaCrownLog "Sites created: $($results.SitesCreated.Count)/4" "INFO"

    # ------------------------------------------------------------------
    # STEP 2: Associate sites with DCE Hub
    # ------------------------------------------------------------------
    if (!$SkipHubAssociation) {
        Write-DeltaCrownLog "=== Step 2: Associate Sites with DCE Hub ===" "STAGE"

        foreach ($siteUrl in $results.SitesCreated) {
            try {
                $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
                $association = Get-PnPHubSiteChild -Identity $dceHubFullUrl -ErrorAction SilentlyContinue
                $isAssociated = $association | Where-Object { $_ -eq $fullUrl }

                if ($isAssociated) {
                    Write-DeltaCrownLog "Already associated with hub: $siteUrl" "WARNING"
                }
                else {
                    if ($PSCmdlet.ShouldProcess($fullUrl, "Associate with DCE Hub")) {
                        Add-PnPHubSiteAssociation -Site $fullUrl -HubSite $dceHubFullUrl
                        Write-DeltaCrownLog "Associated with DCE Hub: $siteUrl" "SUCCESS"
                    }
                }
            }
            catch {
                Write-DeltaCrownLog "Failed to associate $siteUrl with hub: $_" "ERROR"
                $results.Errors += "Hub association failed: $siteUrl — $_"
            }
        }
    }

    # ------------------------------------------------------------------
    # STEP 3: Apply DCE branding to each site
    # ------------------------------------------------------------------
    if (!$SkipBranding) {
        Write-DeltaCrownLog "=== Step 3: Apply DCE Branding ===" "STAGE"

        foreach ($siteUrl in $results.SitesCreated) {
            try {
                $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
                Connect-DeltaCrownSharePoint -Url $fullUrl
                Set-PnPWebTheme -Theme $ThemeName
                Write-DeltaCrownLog "Applied theme to: $siteUrl" "SUCCESS"
            }
            catch {
                Write-DeltaCrownLog "Failed to apply theme to ${siteUrl}: $_" "WARNING"
            }
        }
    }

    # ------------------------------------------------------------------
    # STEP 4: Create lists, libraries, columns, views per site
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 4: Create Lists, Libraries & Schema ===" "STAGE"

    foreach ($siteUrl in $results.SitesCreated) {
        $schema = $SiteSchemas[$siteUrl]
        if (!$schema) {
            Write-DeltaCrownLog "No schema defined for $siteUrl — skipping" "WARNING"
            continue
        }

        $fullUrl = "https://$TenantName.sharepoint.com$siteUrl"
        Connect-DeltaCrownSharePoint -Url $fullUrl

        Write-DeltaCrownLog "Provisioning schema for: $siteUrl" "INFO"

        # Create document libraries
        foreach ($lib in $schema.Libraries) {
            try {
                Add-DCEDocumentLibrary -Title $lib.Title -Description $lib.Description
                $results.LibrariesCreated += "$siteUrl/$($lib.Title)"
            }
            catch {
                Write-DeltaCrownLog "Failed to create library $($lib.Title) on $siteUrl`: $_" "ERROR"
                $results.Errors += "Library creation failed: $siteUrl/$($lib.Title) — $_"
            }
        }

        # Apply library metadata (DCE-Docs pattern)
        if ($schema.ContainsKey("LibraryMetadata") -and $schema.LibraryMetadata.Count -gt 0) {
            foreach ($lib in $schema.Libraries) {
                try {
                    Add-DCELibraryMetadata -LibraryTitle $lib.Title -MetadataColumns $schema.LibraryMetadata
                }
                catch {
                    Write-DeltaCrownLog "Failed to add metadata to $($lib.Title): $_" "ERROR"
                    $results.Errors += "Library metadata failed: $siteUrl/$($lib.Title) — $_"
                }
            }
        }

        # Create SharePoint lists
        foreach ($listConfig in $schema.Lists) {
            try {
                Add-DCESharePointList -ListConfig $listConfig
                $results.ListsCreated += "$siteUrl/$($listConfig.Title)"
            }
            catch {
                Write-DeltaCrownLog "Failed to create list $($listConfig.Title) on $siteUrl`: $_" "ERROR"
                $results.Errors += "List creation failed: $siteUrl/$($listConfig.Title) — $_"
            }
        }
    }

    # ------------------------------------------------------------------
    # STEP 5: Configure hub navigation to include new sites
    # ------------------------------------------------------------------
    Write-DeltaCrownLog "=== Step 5: Update Hub Navigation ===" "STAGE"

    Connect-DeltaCrownSharePoint -Url $dceHubFullUrl

    $navItems = @(
        @{ Title = "Operations";     Url = "https://$TenantName.sharepoint.com/sites/dce-operations" }
        @{ Title = "Client Services"; Url = "https://$TenantName.sharepoint.com/sites/dce-clientservices" }
        @{ Title = "Marketing";      Url = "https://$TenantName.sharepoint.com/sites/dce-marketing" }
        @{ Title = "Document Center"; Url = "https://$TenantName.sharepoint.com/sites/dce-docs" }
        @{ Title = "Corporate Resources"; Url = "https://$TenantName.sharepoint.com/sites/corp-hub" }
    )

    foreach ($nav in $navItems) {
        try {
            Add-PnPNavigationNode -Location TopNavigationBar -Title $nav.Title -Url $nav.Url -ErrorAction SilentlyContinue
            Write-DeltaCrownLog "Added navigation: $($nav.Title)" "SUCCESS"
        }
        catch {
            Write-DeltaCrownLog "Navigation may already exist: $($nav.Title)" "WARNING"
        }
    }

    # ------------------------------------------------------------------
    # COMPLETION
    # ------------------------------------------------------------------
    $results.EndTime = Get-Date
    $duration = $results.EndTime - $results.StartTime

    Write-DeltaCrownBanner "PHASE 3.1 COMPLETE"
    Write-DeltaCrownLog "Sites created:     $($results.SitesCreated.Count)/4" "SUCCESS"
    Write-DeltaCrownLog "Libraries created:  $($results.LibrariesCreated.Count)" "SUCCESS"
    Write-DeltaCrownLog "Lists created:      $($results.ListsCreated.Count)" "SUCCESS"
    Write-DeltaCrownLog "Errors:             $($results.Errors.Count)" $(if($results.Errors.Count -gt 0){"ERROR"}else{"SUCCESS"})
    Write-DeltaCrownLog "Duration:           $($duration.TotalMinutes.ToString('F1')) minutes" "INFO"
    Write-DeltaCrownLog "Log file:           $LogFile" "INFO"

    # Export results
    $resultsPath = Join-Path $ProjectRoot (Join-Path "phase3-week2" (Join-Path "docs" "3.1-provisioning-results.json"))
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Force
    Write-DeltaCrownLog "Results exported: $resultsPath" "INFO"

    # Clear rollback stack on success
    Clear-DeltaCrownRollbackStack

    # Flush log buffer
    Export-DeltaCrownLogBuffer -Path $LogFile

    return [PSCustomObject]@{
        SitesCreated     = $results.SitesCreated
        LibrariesCreated = $results.LibrariesCreated
        ListsCreated     = $results.ListsCreated
        Errors           = $results.Errors
        Duration         = $duration
        Status           = if ($results.Errors.Count -eq 0) { "SUCCESS" } else { "PARTIAL" }
        Timestamp        = Get-Date
    }
}
catch {
    Write-DeltaCrownLog "CRITICAL ERROR in Phase 3.1: $_" "CRITICAL"
    Write-DeltaCrownLog "Stack Trace: $($_.ScriptStackTrace)" "ERROR"

    # Attempt rollback
    try {
        Invoke-DeltaCrownRollback -Reason "Phase 3.1 failed: $_" -ContinueOnError
    }
    catch {
        Write-DeltaCrownLog "Rollback also failed: $_" "CRITICAL"
    }

    Export-DeltaCrownLogBuffer -Path $LogFile
    throw
}
finally {
    if ($script:OwnsPnPConnection) {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
    }
    Write-DeltaCrownLog "Disconnected from SharePoint" "INFO"
}
