# ============================================================================
# PHASE 3.1: DCE Sites Provisioning — Standalone
# ============================================================================
# Creates 4 DCE spoke sites with lists, libraries, columns, views
# Associates them with DCE Hub
# Tyler: 5 device codes at https://microsoft.com/devicelogin
# ============================================================================

$ErrorActionPreference = "Stop"
$clientId = "6d8820fe-7a7b-4226-bc3b-2c53add3c207"
$tenantId = "ce62e17d-2feb-4e67-a115-8ea4af68da30"
$TenantName = "deltacrown"
$adminUrl = "https://${TenantName}-admin.sharepoint.com"
$dceHubUrl = "https://${TenantName}.sharepoint.com/sites/dce-hub"

$results = @{ SitesCreated = @(); ListsCreated = @(); LibsCreated = @(); Errors = @() }

function Write-Log {
    param([string]$Msg, [string]$Lvl = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $c = @{ INFO="White"; SUCCESS="Green"; WARNING="Yellow"; ERROR="Red"; STAGE="Cyan" }
    $p = @{ SUCCESS="[OK]"; ERROR="[!!]"; WARNING="[??]"; STAGE="[==]"; INFO="[..]" }
    Write-Host "$ts $($p[$Lvl]) $Msg" -ForegroundColor $c[$Lvl]
}

function Do-DeviceLogin {
    param([string]$Url, [string]$Label)
    Write-Host "`n$('=' * 60)" -ForegroundColor Cyan
    Write-Host "  AUTH: $Label" -ForegroundColor Cyan
    Write-Host "  Tyler: code at https://microsoft.com/devicelogin" -ForegroundColor Yellow
    Write-Host "$('=' * 60)" -ForegroundColor Cyan
    Connect-PnPOnline -Url $Url -DeviceLogin -ClientId $clientId -Tenant $tenantId -ErrorAction Stop
    Write-Log "Connected: $Label" "SUCCESS"
}

# ============================================================================
# AUTH 1: Admin — Create 4 DCE sites
# ============================================================================
Do-DeviceLogin -Url $adminUrl -Label "SharePoint Admin"

Write-Log "=== PHASE 3.1: DCE Sites Provisioning ===" "STAGE"

# Site definitions
$dceSites = @(
    @{ Path = "dce-operations";     Title = "DCE Operations";       Template = "STS#3"; Teams = $true }
    @{ Path = "dce-clientservices"; Title = "DCE Client Services";  Template = "STS#3"; Teams = $false }
    @{ Path = "dce-marketing";      Title = "DCE Marketing";        Template = "SITEPAGEPUBLISHING#0"; Teams = $false }
    @{ Path = "dce-docs";           Title = "DCE Document Center";  Template = "STS#3"; Teams = $false }
)

# Create sites
Write-Log "=== Creating 4 DCE Sites ===" "STAGE"
foreach ($site in $dceSites) {
    $siteUrl = "https://${TenantName}.sharepoint.com/sites/$($site.Path)"

    $existing = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Log "  Exists: $($site.Title)" "WARNING"
        continue
    }

    Write-Log "  Creating: $($site.Title) ($($site.Template))..."
    try {
        if ($site.Template -eq "SITEPAGEPUBLISHING#0") {
            # Communication Site
            New-PnPSite -Type CommunicationSite -Title $site.Title -Url $siteUrl `
                -Description "DCE $($site.Title)" -Lcid 1033 -TimeZone 10 -Wait
        } else {
            # Team Site without M365 Group
            New-PnPSite -Type TeamSiteWithoutMicrosoft365Group -Title $site.Title -Url $siteUrl `
                -Description "DCE $($site.Title)" -Lcid 1033 -TimeZone 10 -Wait
        }
        Write-Log "    Created: $siteUrl" "SUCCESS"
        $results.SitesCreated += $site.Path
        Start-Sleep -Seconds 5
    } catch {
        Write-Log "    FAILED: $_" "ERROR"
        $results.Errors += "Site: $($site.Path) — $_"
    }
}

# Associate with DCE Hub
Write-Log "=== Associating with DCE Hub ===" "STAGE"
foreach ($site in $dceSites) {
    $siteUrl = "https://${TenantName}.sharepoint.com/sites/$($site.Path)"
    try {
        Add-PnPHubSiteAssociation -Site $siteUrl -HubSite $dceHubUrl -ErrorAction Stop
        Write-Log "  $($site.Path) → DCE-Hub" "SUCCESS"
    } catch {
        Write-Log "  $($site.Path) association: $_" "WARNING"
    }
}

# Apply DCE theme to all sites
Write-Log "=== Applying DCE Theme ===" "STAGE"
$themeName = "Delta Crown Extensions Theme"
foreach ($site in $dceSites) {
    $siteUrl = "https://${TenantName}.sharepoint.com/sites/$($site.Path)"
    try {
        Connect-PnPOnline -Url $siteUrl -DeviceLogin -ClientId $clientId -Tenant $tenantId
        Set-PnPWebTheme -Theme $themeName -ErrorAction SilentlyContinue
        Write-Log "  Theme: $($site.Path)" "SUCCESS"
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
    } catch {
        Write-Log "  Theme $($site.Path): $_" "WARNING"
    }
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 2: DCE-Operations — Lists and Libraries
# ============================================================================
$opsUrl = "https://${TenantName}.sharepoint.com/sites/dce-operations"
Do-DeviceLogin -Url $opsUrl -Label "DCE-Operations"

Write-Log "=== DCE-Operations: Libraries ===" "STAGE"
# Daily Ops library
try {
    New-PnPList -Title "Daily Ops" -Template DocumentLibrary -ErrorAction SilentlyContinue
    Set-PnPList -Identity "Daily Ops" -Description "Shift reports, daily checklists, incident logs"
    Write-Log "  Library: Daily Ops" "SUCCESS"
    $results.LibsCreated += "dce-operations/Daily Ops"
} catch { Write-Log "  Daily Ops: $_" "WARNING" }

Write-Log "=== DCE-Operations: Lists ===" "STAGE"

# Bookings list
$list = New-PnPList -Title "Bookings" -Template GenericList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Bookings" -Description "Client booking tracker"
Add-PnPField -List "Bookings" -InternalName "ServiceType" -DisplayName "Service Type" -Type Choice -Choices @("Extensions","Maintenance","Removal","Consultation") -AddToDefaultView
Add-PnPField -List "Bookings" -InternalName "BookingDate" -DisplayName "Booking Date" -Type DateTime -AddToDefaultView
Add-PnPField -List "Bookings" -InternalName "Stylist" -DisplayName "Stylist" -Type User -AddToDefaultView
Add-PnPField -List "Bookings" -InternalName "Status" -DisplayName "Status" -Type Choice -Choices @("Confirmed","Pending","Completed","Cancelled","No-Show") -AddToDefaultView
Add-PnPField -List "Bookings" -InternalName "Revenue" -DisplayName "Revenue" -Type Currency -AddToDefaultView
Write-Log "  List: Bookings" "SUCCESS"
$results.ListsCreated += "dce-operations/Bookings"

# Staff Schedule
New-PnPList -Title "Staff Schedule" -Template GenericList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Staff Schedule" -Description "Weekly staff roster"
Add-PnPField -List "Staff Schedule" -InternalName "StaffMember" -DisplayName "Staff Member" -Type User -AddToDefaultView
Add-PnPField -List "Staff Schedule" -InternalName "ShiftDate" -DisplayName "Shift Date" -Type DateTime -AddToDefaultView
Add-PnPField -List "Staff Schedule" -InternalName "Location" -DisplayName "Location" -Type Choice -Choices @("Main Salon","CBD Studio","Mobile") -AddToDefaultView
Add-PnPField -List "Staff Schedule" -InternalName "Role" -DisplayName "Role" -Type Choice -Choices @("Stylist","Reception","Manager","Trainee") -AddToDefaultView
Write-Log "  List: Staff Schedule" "SUCCESS"
$results.ListsCreated += "dce-operations/Staff Schedule"

# Tasks
New-PnPList -Title "Tasks" -Template GenericList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Tasks" -Description "Operational task tracking"
Add-PnPField -List "Tasks" -InternalName "AssignedTo" -DisplayName "Assigned To" -Type User -AddToDefaultView
Add-PnPField -List "Tasks" -InternalName "DueDate" -DisplayName "Due Date" -Type DateTime -AddToDefaultView
Add-PnPField -List "Tasks" -InternalName "Priority" -DisplayName "Priority" -Type Choice -Choices @("Urgent","High","Medium","Low") -AddToDefaultView
Add-PnPField -List "Tasks" -InternalName "TaskStatus" -DisplayName "Status" -Type Choice -Choices @("Not Started","In Progress","Completed","Blocked") -AddToDefaultView
Write-Log "  List: Tasks" "SUCCESS"
$results.ListsCreated += "dce-operations/Tasks"

# Inventory
New-PnPList -Title "Inventory" -Template GenericList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Inventory" -Description "Product inventory tracker"
Add-PnPField -List "Inventory" -InternalName "SKU" -DisplayName "SKU" -Type Text -AddToDefaultView
Add-PnPField -List "Inventory" -InternalName "Category" -DisplayName "Category" -Type Choice -Choices @("Hair Extensions","Adhesives","Tools","Care Products","Accessories") -AddToDefaultView
Add-PnPField -List "Inventory" -InternalName "Quantity" -DisplayName "Quantity" -Type Number -AddToDefaultView
Add-PnPField -List "Inventory" -InternalName "ReorderLevel" -DisplayName "Reorder Level" -Type Number -AddToDefaultView
Add-PnPField -List "Inventory" -InternalName "UnitCost" -DisplayName "Unit Cost" -Type Currency -AddToDefaultView
Write-Log "  List: Inventory" "SUCCESS"
$results.ListsCreated += "dce-operations/Inventory"

# Calendar (Events list)
New-PnPList -Title "Calendar" -Template EventsList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Calendar" -Description "Team calendar — syncs to Outlook"
Write-Log "  List: Calendar" "SUCCESS"
$results.ListsCreated += "dce-operations/Calendar"

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 3: DCE-ClientServices
# ============================================================================
$csUrl = "https://${TenantName}.sharepoint.com/sites/dce-clientservices"
Do-DeviceLogin -Url $csUrl -Label "DCE-ClientServices"

Write-Log "=== DCE-ClientServices: Libraries ===" "STAGE"
New-PnPList -Title "Consent Forms" -Template DocumentLibrary -ErrorAction SilentlyContinue
Set-PnPList -Identity "Consent Forms" -Description "Signed client consent PDFs"
Write-Log "  Library: Consent Forms" "SUCCESS"
$results.LibsCreated += "dce-clientservices/Consent Forms"

Write-Log "=== DCE-ClientServices: Lists ===" "STAGE"

# Client Records
New-PnPList -Title "Client Records" -Template GenericList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Client Records" -Description "Client service history (PII)"
Add-PnPField -List "Client Records" -InternalName "Email" -DisplayName "Email" -Type Text -AddToDefaultView
Add-PnPField -List "Client Records" -InternalName "Phone" -DisplayName "Phone" -Type Text -AddToDefaultView
Add-PnPField -List "Client Records" -InternalName "LastVisit" -DisplayName "Last Visit" -Type DateTime -AddToDefaultView
Add-PnPField -List "Client Records" -InternalName "PreferredStylist" -DisplayName "Preferred Stylist" -Type User -AddToDefaultView
Add-PnPField -List "Client Records" -InternalName "TotalSpend" -DisplayName "Total Spend" -Type Currency -AddToDefaultView
Add-PnPField -List "Client Records" -InternalName "VIPStatus" -DisplayName "VIP Status" -Type Boolean -AddToDefaultView
Write-Log "  List: Client Records" "SUCCESS"
$results.ListsCreated += "dce-clientservices/Client Records"

# Service Catalog
New-PnPList -Title "Service Catalog" -Template GenericList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Service Catalog" -Description "Services offered and pricing"
Add-PnPField -List "Service Catalog" -InternalName "ServiceCategory" -DisplayName "Category" -Type Choice -Choices @("Extensions","Maintenance","Removal","Consultation","Styling") -AddToDefaultView
Add-PnPField -List "Service Catalog" -InternalName "Duration" -DisplayName "Duration (min)" -Type Number -AddToDefaultView
Add-PnPField -List "Service Catalog" -InternalName "Price" -DisplayName "Price" -Type Currency -AddToDefaultView
Add-PnPField -List "Service Catalog" -InternalName "Active" -DisplayName "Active" -Type Boolean -AddToDefaultView
Write-Log "  List: Service Catalog" "SUCCESS"
$results.ListsCreated += "dce-clientservices/Service Catalog"

# Feedback
New-PnPList -Title "Feedback" -Template GenericList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Feedback" -Description "Client satisfaction tracker"
Add-PnPField -List "Feedback" -InternalName "Rating" -DisplayName "Rating (1-5)" -Type Number -AddToDefaultView
Add-PnPField -List "Feedback" -InternalName "FeedbackType" -DisplayName "Type" -Type Choice -Choices @("Compliment","Suggestion","Complaint","General") -AddToDefaultView
Add-PnPField -List "Feedback" -InternalName "FollowUp" -DisplayName "Follow-Up Required" -Type Boolean -AddToDefaultView
Write-Log "  List: Feedback" "SUCCESS"
$results.ListsCreated += "dce-clientservices/Feedback"

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 4: DCE-Marketing
# ============================================================================
$mktUrl = "https://${TenantName}.sharepoint.com/sites/dce-marketing"
Do-DeviceLogin -Url $mktUrl -Label "DCE-Marketing"

Write-Log "=== DCE-Marketing: Libraries ===" "STAGE"
New-PnPList -Title "Brand Assets" -Template DocumentLibrary -ErrorAction SilentlyContinue
Set-PnPList -Identity "Brand Assets" -Description "Logos, photos, videos, brand guidelines"
Write-Log "  Library: Brand Assets" "SUCCESS"
$results.LibsCreated += "dce-marketing/Brand Assets"

New-PnPList -Title "Templates" -Template DocumentLibrary -ErrorAction SilentlyContinue
Set-PnPList -Identity "Templates" -Description "Marketing templates — flyers, social posts, email"
Write-Log "  Library: Templates" "SUCCESS"
$results.LibsCreated += "dce-marketing/Templates"

Write-Log "=== DCE-Marketing: Lists ===" "STAGE"

# Campaigns
New-PnPList -Title "Campaigns" -Template GenericList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Campaigns" -Description "Marketing campaign tracker"
Add-PnPField -List "Campaigns" -InternalName "StartDate" -DisplayName "Start Date" -Type DateTime -AddToDefaultView
Add-PnPField -List "Campaigns" -InternalName "Channel" -DisplayName "Channel" -Type Choice -Choices @("Instagram","Facebook","TikTok","Email","In-Store","Google") -AddToDefaultView
Add-PnPField -List "Campaigns" -InternalName "CampaignStatus" -DisplayName "Status" -Type Choice -Choices @("Planning","Active","Paused","Completed") -AddToDefaultView
Add-PnPField -List "Campaigns" -InternalName "Budget" -DisplayName "Budget" -Type Currency -AddToDefaultView
Add-PnPField -List "Campaigns" -InternalName "CampaignOwner" -DisplayName "Owner" -Type User -AddToDefaultView
Write-Log "  List: Campaigns" "SUCCESS"
$results.ListsCreated += "dce-marketing/Campaigns"

# Social Calendar
New-PnPList -Title "Social Calendar" -Template GenericList -ErrorAction SilentlyContinue
Set-PnPList -Identity "Social Calendar" -Description "Social media posting schedule"
Add-PnPField -List "Social Calendar" -InternalName "PostDate" -DisplayName "Post Date" -Type DateTime -AddToDefaultView
Add-PnPField -List "Social Calendar" -InternalName "Platform" -DisplayName "Platform" -Type Choice -Choices @("Instagram","Facebook","TikTok","LinkedIn","Google Business") -AddToDefaultView
Add-PnPField -List "Social Calendar" -InternalName "ContentType" -DisplayName "Content Type" -Type Choice -Choices @("Photo","Video","Reel","Story","Carousel","Text") -AddToDefaultView
Add-PnPField -List "Social Calendar" -InternalName "PostStatus" -DisplayName "Status" -Type Choice -Choices @("Draft","Scheduled","Published","Cancelled") -AddToDefaultView
Write-Log "  List: Social Calendar" "SUCCESS"
$results.ListsCreated += "dce-marketing/Social Calendar"

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# AUTH 5: DCE-Docs (Document Center)
# ============================================================================
$docsUrl = "https://${TenantName}.sharepoint.com/sites/dce-docs"
Do-DeviceLogin -Url $docsUrl -Label "DCE-Document Center"

Write-Log "=== DCE-Docs: Document Libraries ===" "STAGE"

$docLibs = @(
    @{ Title = "Policies";  Desc = "Company policies and SOPs" }
    @{ Title = "Training";  Desc = "Training materials and videos" }
    @{ Title = "Forms";     Desc = "Standardized forms" }
    @{ Title = "Templates"; Desc = "Document templates" }
    @{ Title = "Archive";   Desc = "Historical documents" }
)

foreach ($lib in $docLibs) {
    try {
        New-PnPList -Title $lib.Title -Template DocumentLibrary -ErrorAction SilentlyContinue
        Set-PnPList -Identity $lib.Title -Description $lib.Desc
        Write-Log "  Library: $($lib.Title)" "SUCCESS"
        $results.LibsCreated += "dce-docs/$($lib.Title)"
    } catch {
        Write-Log "  $($lib.Title): $_" "WARNING"
    }
}

# Add metadata columns to all libraries
$metadataCols = @(
    @{ Name = "DocType";    DisplayName = "Document Type"; Type = "Choice"; Choices = @("Policy","SOP","Form","Template","Training","Reference") }
    @{ Name = "Department"; DisplayName = "Department";    Type = "Choice"; Choices = @("Operations","Marketing","Finance","HR","IT") }
    @{ Name = "ReviewDate"; DisplayName = "Review Date";   Type = "DateTime" }
    @{ Name = "DocVersion"; DisplayName = "Version";       Type = "Number" }
    @{ Name = "DocStatus";  DisplayName = "Status";        Type = "Choice"; Choices = @("Draft","Under Review","Published","Archived") }
)

Write-Log "=== DCE-Docs: Metadata Columns ===" "STAGE"
foreach ($lib in $docLibs) {
    foreach ($col in $metadataCols) {
        try {
            if ($col.Choices) {
                Add-PnPField -List $lib.Title -InternalName $col.Name -DisplayName $col.DisplayName `
                    -Type $col.Type -Choices $col.Choices -AddToDefaultView -ErrorAction SilentlyContinue
            } else {
                Add-PnPField -List $lib.Title -InternalName $col.Name -DisplayName $col.DisplayName `
                    -Type $col.Type -AddToDefaultView -ErrorAction SilentlyContinue
            }
        } catch { }
    }
    Write-Log "  Metadata applied to: $($lib.Title)" "SUCCESS"
}

Disconnect-PnPOnline -ErrorAction SilentlyContinue

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host "`n$('=' * 60)" -ForegroundColor Green
Write-Host "  PHASE 3.1 COMPLETE" -ForegroundColor Green
Write-Host "$('=' * 60)" -ForegroundColor Green
Write-Host ""

Write-Log "Sites created:      $($results.SitesCreated.Count)" "SUCCESS"
Write-Log "Libraries created:  $($results.LibsCreated.Count)" "SUCCESS"
Write-Log "Lists created:      $($results.ListsCreated.Count)" "SUCCESS"

if ($results.Errors.Count -gt 0) {
    Write-Log "Errors: $($results.Errors.Count)" "ERROR"
    $results.Errors | ForEach-Object { Write-Log "  $_" "ERROR" }
} else {
    Write-Log "Zero errors!" "SUCCESS"
}
