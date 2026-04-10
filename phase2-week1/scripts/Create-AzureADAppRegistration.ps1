# ============================================================================
# Create-AzureADAppRegistration.ps1
# Azure AD App Registration Helper for Delta Crown Extensions
# ============================================================================
# DESCRIPTION: Creates an Azure AD App Registration with certificate-based
#              authentication for SharePoint and Microsoft Graph access.
#              Run this ONCE to set up production authentication.
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="Microsoft.Graph.Applications";ModuleVersion="2.0.0"}
#Requires -Modules @{ModuleName="Microsoft.Graph.Identity.DirectoryManagement";ModuleVersion="2.0.0"}

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$AppName = "Delta Crown Extensions Automation",
    
    [Parameter()]
    [string]$CertOutputPath = ".\phase2-week1\certs",
    
    [Parameter()]
    [ValidateRange(1, 24)]
    [int]$CertValidityMonths = 12,
    
    [Parameter()]
    [switch]$CreateSelfSignedCert = $true,
    
    [Parameter()]
    [switch]$SkipCertCreation = $false,
    
    [Parameter()]
    [string]$ExistingCertThumbprint = $null
)

# Error handling
$ErrorActionPreference = "Stop"

# ============================================================================
# LOGGING
# ============================================================================
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# ============================================================================
# REQUIRED PERMISSIONS
# ============================================================================
$RequiredPermissions = @(
    # Microsoft Graph Application Permissions
    @{ Resource = "Microsoft Graph"; Scope = "Group.Read.All"; Type = "Application" },
    @{ Resource = "Microsoft Graph"; Scope = "Group.ReadWrite.All"; Type = "Application" },
    @{ Resource = "Microsoft Graph"; Scope = "Directory.Read.All"; Type = "Application" },
    @{ Resource = "Microsoft Graph"; Scope = "User.Read.All"; Type = "Application" },
    
    # SharePoint Application Permissions
    @{ Resource = "SharePoint"; Scope = "Sites.FullControl.All"; Type = "Application" },
    @{ Resource = "SharePoint"; Scope = "Sites.Read.All"; Type = "Application" }
)

$RequiredDelegatedPermissions = @(
    # Microsoft Graph Delegated Permissions (for interactive scenarios)
    @{ Resource = "Microsoft Graph"; Scope = "Group.ReadWrite.All"; Type = "Delegated" },
    @{ Resource = "Microsoft Graph"; Scope = "Directory.ReadWrite.All"; Type = "Delegated" },
    @{ Resource = "Microsoft Graph"; Scope = "User.Read.All"; Type = "Delegated" }
)

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "=== Azure AD App Registration Setup ==="
    Write-Log "App Name: $AppName"
    Write-Log "Certificate Validity: $CertValidityMonths months"
    
    # ------------------------------------------------------------------------
    # STEP 1: Connect to Microsoft Graph with admin permissions
    # ------------------------------------------------------------------------
    Write-Log "`nConnecting to Microsoft Graph..."
    Write-Log "You must have Global Administrator or Application Administrator role."
    
    Connect-MgGraph -Scopes @(
        "Application.ReadWrite.All"
        "AppRoleAssignment.ReadWrite.All"
        "Directory.ReadWrite.All"
    ) -NoWelcome
    
    $context = Get-MgContext
    Write-Log "Connected as: $($context.Account)" "SUCCESS"
    Write-Log "Tenant ID: $($context.TenantId)"
    
    # ------------------------------------------------------------------------
    # STEP 2: Check for existing app
    # ------------------------------------------------------------------------
    Write-Log "`nChecking for existing app registration..."
    $existingApp = Get-MgApplication -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue
    
    if ($existingApp) {
        Write-Log "App '$AppName' already exists!" "WARNING"
        Write-Log "  - App ID: $($existingApp.AppId)"
        Write-Log "  - Object ID: $($existingApp.Id)"
        
        $continue = Read-Host "`nDo you want to update the existing app? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-Log "Operation cancelled by user."
            return
        }
        $app = $existingApp
    }
    else {
        # Create new app registration
        Write-Log "Creating new app registration..."
        
        $appParams = @{
            DisplayName = $AppName
            SignInAudience = "AzureADMyOrg"
            Description = "Service principal for Delta Crown Extensions SharePoint automation"
        }
        
        $app = New-MgApplication @appParams
        Write-Log "Created app registration" "SUCCESS"
        Write-Log "  - App ID: $($app.AppId)"
        Write-Log "  - Object ID: $($app.Id)"
        
        # Create service principal
        $spParams = @{
            AppId = $app.AppId
            AccountEnabled = $true
        }
        
        $servicePrincipal = New-MgServicePrincipal @spParams
        Write-Log "Created service principal" "SUCCESS"
        Write-Log "  - Service Principal ID: $($servicePrincipal.Id)"
    }
    
    # ------------------------------------------------------------------------
    # STEP 3: Create or use certificate
    # ------------------------------------------------------------------------
    $certThumbprint = $null
    $certPath = $null
    $certPassword = $null
    
    if (!$SkipCertCreation) {
        if ($CreateSelfSignedCert) {
            Write-Log "`nCreating self-signed certificate..."
            
            # Ensure cert directory exists
            if (!(Test-Path $CertOutputPath)) {
                New-Item -ItemType Directory -Path $CertOutputPath -Force | Out-Null
            }
            
            $certName = "DeltaCrownExtensions-$(Get-Date -Format 'yyyyMMdd')"
            $certPath = Join-Path $CertOutputPath "$certName.pfx"
            $cerPath = Join-Path $CertOutputPath "$certName.cer"
            
            # Generate secure password
            $certPassword = [System.Web.Security.Membership]::GeneratePassword(16, 4)
            $securePassword = ConvertTo-SecureString -String $certPassword -AsPlainText -Force
            
            # Create self-signed certificate
            $cert = New-SelfSignedCertificate `
                -Subject "CN=$certName" `
                -CertStoreLocation "Cert:\CurrentUser\My" `
                -KeyExportPolicy Exportable `
                -KeyLength 2048 `
                -KeyAlgorithm RSA `
                -NotAfter (Get-Date).AddMonths($CertValidityMonths) `
                -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider"
            
            $certThumbprint = $cert.Thumbprint
            
            # Export certificate
            Export-PfxCertificate `
                -Cert "Cert:\CurrentUser\My\$certThumbprint" `
                -FilePath $certPath `
                -Password $securePassword | Out-Null
            
            Export-Certificate `
                -Cert "Cert:\CurrentUser\My\$certThumbprint" `
                -FilePath $cerPath | Out-Null
            
            Write-Log "Certificate created successfully" "SUCCESS"
            Write-Log "  - Thumbprint: $certThumbprint"
            Write-Log "  - PFX Path: $certPath"
            Write-Log "  - CER Path: $cerPath"
            Write-Log "  - Valid until: $($cert.NotAfter)"
            
            # Save password securely
            $passwordPath = Join-Path $CertOutputPath "$certName-password.txt"
            $certPassword | Out-File -FilePath $passwordPath -Force
            Write-Log "  - Password saved to: $passwordPath"
            
            # Upload certificate to app registration
            Write-Log "`nUploading certificate to app registration..."
            $certBase64 = [Convert]::ToBase64String($cert.RawData)
            
            $certParams = @{
                ApplicationId = $app.Id
                KeyCredentials = @{
                    Type = "AsymmetricX509Cert"
                    Usage = "Verify"
                    Key = $certBase64
                }
            }
            
            Update-MgApplication @certParams
            Write-Log "Certificate uploaded to Azure AD" "SUCCESS"
        }
        elseif ($ExistingCertThumbprint) {
            $certThumbprint = $ExistingCertThumbprint
            Write-Log "Using existing certificate thumbprint: $certThumbprint"
        }
    }
    
    # ------------------------------------------------------------------------
    # STEP 4: Configure API Permissions
    # ------------------------------------------------------------------------
    Write-Log "`nConfiguring API permissions..."
    
    # Add required permissions
    foreach ($permission in $RequiredPermissions) {
        $resourceId = switch ($permission.Resource) {
            "Microsoft Graph" { "00000003-0000-0000-c000-000000000000" }
            "SharePoint" { "00000003-0000-0ff1-ce00-000000000000" }
            default { throw "Unknown resource: $($permission.Resource)" }
        }
        
        $appRoleId = switch ($permission.Scope) {
            "Group.Read.All" { "5b567255-7703-4780-807c-7be8301ae99b" }
            "Group.ReadWrite.All" { "62a82d76-70ea-41e2-9197-8f8d91f28f41" }
            "Directory.Read.All" { "7ab1d382-f21e-4acd-a1ba-275372dbdd1d" }
            "User.Read.All" { "df021288-bdef-4463-88db-98f22de89214" }
            "Sites.FullControl.All" { "678536fe-1083-478a-9554-604a1e526b98" }
            "Sites.Read.All" { "3b55498e-47ec-484f-8136-9010a7b7501f" }
            default { $null }
        }
        
        if ($appRoleId) {
            $permissionParams = @{
                ServicePrincipalId = $servicePrincipal.Id
                ResourceId = $resourceId
                AppRoleId = $appRoleId
            }
            
            try {
                New-MgServicePrincipalAppRoleAssignment @permissionParams | Out-Null
                Write-Log "  Added: $($permission.Resource) - $($permission.Scope)"
            }
            catch {
                Write-Log "  Already granted or error: $($permission.Scope)" "WARNING"
            }
        }
    }
    
    # ------------------------------------------------------------------------
    # STEP 5: Admin Consent
    # ------------------------------------------------------------------------
    Write-Log "`nAdmin consent required for application permissions!"
    Write-Log "Visit: https://portal.azure.com/#view/Microsoft_AAD_IAM/ConsentQuickStartBlade"
    Write-Log "Or run: Grant-MgServicePrincipalConsent -ServicePrincipalId $($servicePrincipal.Id)"
    
    # Alternative: Generate consent URL
    $consentUrl = "https://login.microsoftonline.com/$($context.TenantId)/adminconsent?client_id=$($app.AppId)"
    Write-Log "`nAdmin Consent URL:"
    Write-Log $consentUrl "SUCCESS"
    
    # ------------------------------------------------------------------------
    # STEP 6: Output Configuration
    # ------------------------------------------------------------------------
    Write-Log "`n=== CONFIGURATION SUMMARY ===" "SUCCESS"
    
    $config = @{
        AppName = $AppName
        AppId = $app.AppId
        ObjectId = $app.Id
        TenantId = $context.TenantId
        CertificateThumbprint = $certThumbprint
        CertificatePath = $certPath
        CertificatePassword = $certPassword
        Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-Log "`nUse these values in your scripts:`"
    Write-Log "  `$env:DCE_TENANT_ID = '$($context.TenantId)'"
    Write-Log "  `$env:DCE_CLIENT_ID = '$($app.AppId)'"
    if ($certThumbprint) {
        Write-Log "  `$env:DCE_CERT_THUMBPRINT = '$certThumbprint'"
    }
    if ($certPath) {
        Write-Log "  `$env:DCE_CERT_PATH = '$certPath'"
    }
    
    # Save configuration
    $configPath = Join-Path $CertOutputPath "app-config.json"
    $config | ConvertTo-Json | Out-File -FilePath $configPath -Force
    Write-Log "`nConfiguration saved to: $configPath"
    
    # ------------------------------------------------------------------------
    # STEP 7: Update instructions
    # ------------------------------------------------------------------------
    $instructions = @"

=== NEXT STEPS ===

1. ADMIN CONSENT REQUIRED:
   Visit: $consentUrl
   Or in Azure Portal > Enterprise Applications > $AppName > Permissions > Grant admin consent

2. CONFIGURE ENVIRONMENT VARIABLES:
   [Environment]::SetEnvironmentVariable('DCE_TENANT_ID', '$($context.TenantId)', 'User')
   [Environment]::SetEnvironmentVariable('DCE_CLIENT_ID', '$($app.AppId)', 'User')
   [Environment]::SetEnvironmentVariable('DCE_CERT_THUMBPRINT', '$certThumbprint', 'User')
   [Environment]::SetEnvironmentVariable('DCE_CERT_PATH', '$certPath', 'User')

3. TEST CONNECTION:
   Connect-PnPOnline -Url https://deltacrown.sharepoint.com `
       -ClientId $($app.AppId) `
       -Tenant $($context.TenantId) `
       -Thumbprint $certThumbprint

4. STORE CERTIFICATE SECURELY:
   - Backup $certPath to secure storage
   - Delete $passwordPath after recording password
   - Consider using Azure Key Vault for production

=== IMPORTANT SECURITY NOTES ===
- Certificate password was saved to: $passwordPath
- Delete this file after securely storing the password
- Certificate expires: $(if($cert) { $cert.NotAfter } else { "N/A" })
- Set up certificate renewal reminder before expiration
"@
    
    Write-Log $instructions "INFO"
    $instructions | Out-File -FilePath (Join-Path $CertOutputPath "SETUP-INSTRUCTIONS.txt") -Force
    
    Write-Log "`n=== App Registration Complete ===" "SUCCESS"
    
    return $config
}
catch {
    Write-Log "CRITICAL ERROR: $_" "ERROR"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    throw
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
