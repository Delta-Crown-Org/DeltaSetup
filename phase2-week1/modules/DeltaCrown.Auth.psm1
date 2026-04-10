# ============================================================================
# DeltaCrown.Auth.psm1
# Shared Authentication Module for Delta Crown Extensions
# ============================================================================
# DESCRIPTION: Centralized authentication handling supporting multiple methods:
#              - Interactive (dev/test environments)
#              - Certificate-based (production - RECOMMENDED)
#              - Managed Identity (Azure automation)
#              - Environment variables (CI/CD pipelines)
# ============================================================================

#Requires -Version 5.1
#Requires -Modules @{ModuleName="PnP.PowerShell";ModuleVersion="2.0.0"}
#Requires -Modules @{ModuleName="Microsoft.Graph.Authentication";ModuleVersion="2.0.0"}

$script:AuthContext = @{}
$script:ConfigPath = $null

#region Configuration

<#
.SYNOPSIS
    Loads authentication configuration from secure sources.
.DESCRIPTION
    Supports multiple configuration sources in order of precedence:
    1. Azure Key Vault (production)
    2. Environment variables (CI/CD)
    3. Encrypted local file (dev)
    4. Interactive prompts (fallback)
#>
function Import-DeltaCrownAuthConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath = $null,
        
        [Parameter()]
        [ValidateSet("Development", "Staging", "Production")]
        [string]$Environment = "Development",
        
        [Parameter()]
        [string]$KeyVaultName = $null
    )
    
    $config = @{}
    
    # Priority 1: Azure Key Vault (Production)
    if ($KeyVaultName -and $Environment -eq "Production") {
        try {
            $config = Get-DeltaCrownKeyVaultConfig -VaultName $KeyVaultName
            Write-Verbose "Loaded configuration from Azure Key Vault: $KeyVaultName"
            $config['_Source'] = "KeyVault"
            $config['_Environment'] = $Environment
            return $config
        }
        catch {
            Write-Warning "Failed to load from Key Vault: $_. Attempting fallback..."
        }
    }
    
    # Priority 2: Environment Variables
    if ($env:DCE_TENANT_ID -and $env:DCE_CLIENT_ID) {
        $config = @{
            TenantId = $env:DCE_TENANT_ID
            ClientId = $env:DCE_CLIENT_ID
            Thumbprint = $env:DCE_CERT_THUMBPRINT
            CertificatePath = $env:DCE_CERT_PATH
            CertificatePassword = $env:DCE_CERT_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
        }
        Write-Verbose "Loaded configuration from environment variables"
        $config['_Source'] = "Environment"
        $config['_Environment'] = $Environment
        return $config
    }
    
    # Priority 3: Encrypted Config File
    if ($ConfigPath -and (Test-Path $ConfigPath)) {
        try {
            $config = Import-CliXml -Path $ConfigPath
            Write-Verbose "Loaded configuration from encrypted file: $ConfigPath"
            $config['_Source'] = "EncryptedFile"
            $config['_Environment'] = $Environment
            return $config
        }
        catch {
            Write-Warning "Failed to load encrypted config: $_"
        }
    }
    
    # Priority 4: Development defaults (prompt required)
    if ($Environment -eq "Development") {
        $config = @{
            TenantId = $env:DCE_TENANT_ID
            ClientId = $env:DCE_CLIENT_ID
            Interactive = $true
            _Source = "Interactive"
            _Environment = $Environment
        }
        Write-Verbose "Using interactive authentication (Development mode)"
        return $config
    }
    
    throw "Unable to load authentication configuration. Provide ConfigPath, KeyVaultName, or environment variables."
}

<#
.SYNOPSIS
    Retrieves configuration from Azure Key Vault.
#>
function Get-DeltaCrownKeyVaultConfig {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$VaultName)
    
    # Ensure Az.KeyVault module
    if (!(Get-Module -ListAvailable Az.KeyVault)) {
        throw "Az.KeyVault module required for Key Vault access. Install with: Install-Module Az.KeyVault"
    }
    
    $secrets = @{}
    $requiredSecrets = @(
        "DCE-TenantId",
        "DCE-ClientId", 
        "DCE-CertThumbprint"
    )
    
    foreach ($secretName in $requiredSecrets) {
        $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $secretName -ErrorAction Stop
        $key = $secretName -replace "DCE-", "" -replace "Cert", "Certificate"
        $secrets[$key] = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
    }
    
    return $secrets
}

#endregion

#region SharePoint Authentication

<#
.SYNOPSIS
    Connects to SharePoint Online with proper authentication.
.DESCRIPTION
    Supports certificate-based auth (production) and interactive (dev).
    Implements retry logic and proper error handling.
#>
function Connect-DeltaCrownSharePoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^https://.*\.sharepoint\.com(/.*)?$')]
        [string]$Url,
        
        [Parameter()]
        [hashtable]$AuthConfig = $null,
        
        [Parameter()]
        [ValidateRange(1,5)]
        [int]$RetryCount = 3,
        
        [Parameter()]
        [switch]$ReturnConnection
    )
    
    # Load config if not provided
    if (!$AuthConfig) {
        $AuthConfig = Import-DeltaCrownAuthConfig
    }
    
    $attempt = 0
    $connected = $false
    $lastError = $null
    
    while ($attempt -lt $RetryCount -and !$connected) {
        $attempt++
        
        try {
            # Disconnect any existing sessions
            Disconnect-PnPOnline -ErrorAction SilentlyContinue
            
            # Certificate-based authentication (Production)
            if ($AuthConfig.CertificatePath -and (Test-Path $AuthConfig.CertificatePath)) {
                $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
                    $AuthConfig.CertificatePath,
                    $AuthConfig.CertificatePassword
                )
                
                Connect-PnPOnline -Url $Url -ClientId $AuthConfig.ClientId -Tenant $AuthConfig.TenantId -Certificate $cert -ErrorAction Stop
                Write-Verbose "Connected using certificate authentication"
            }
            # Thumbprint-based authentication
            elseif ($AuthConfig.Thumbprint) {
                Connect-PnPOnline -Url $Url -ClientId $AuthConfig.ClientId -Tenant $AuthConfig.TenantId -Thumbprint $AuthConfig.Thumbprint -ErrorAction Stop
                Write-Verbose "Connected using certificate thumbprint"
            }
            # Managed Identity (Azure)
            elseif ($AuthConfig.UseManagedIdentity) {
                Connect-PnPOnline -Url $Url -ManagedIdentity -ErrorAction Stop
                Write-Verbose "Connected using Managed Identity"
            }
            # Interactive (Development only)
            elseif ($AuthConfig.Interactive -or $AuthConfig._Environment -eq "Development") {
                # SECURITY WARNING for production
                if ($AuthConfig._Environment -eq "Production") {
                    throw "Interactive authentication is NOT allowed in Production environment!"
                }
                Connect-PnPOnline -Url $Url -Interactive -ErrorAction Stop
                Write-Verbose "Connected using interactive authentication (Development mode)"
            }
            else {
                throw "No valid authentication method available in configuration"
            }
            
            $connected = $true
            $script:AuthContext['SharePoint'] = @{
                Url = $Url
                ConnectedAt = Get-Date
                Method = if ($AuthConfig.CertificatePath) { "Certificate" } elseif ($AuthConfig.Thumbprint) { "Thumbprint" } elseif ($AuthConfig.UseManagedIdentity) { "ManagedIdentity" } else { "Interactive" }
            }
        }
        catch {
            $lastError = $_
            Write-Warning "Connection attempt $attempt failed: $($_.Exception.Message)"
            if ($attempt -lt $RetryCount) {
                Start-Sleep -Seconds (2 * $attempt)  # Exponential backoff
            }
        }
    }
    
    if (!$connected) {
        throw "Failed to connect to SharePoint after $RetryCount attempts. Last error: $lastError"
    }
    
    Write-Verbose "Successfully connected to SharePoint: $Url"
    
    if ($ReturnConnection) {
        return Get-PnPContext
    }
}

#endregion

#region Microsoft Graph Authentication

<#
.SYNOPSIS
    Connects to Microsoft Graph with proper authentication.
#>
function Connect-DeltaCrownGraph {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$RequiredScopes = @("Group.Read.All"),
        
        [Parameter()]
        [hashtable]$AuthConfig = $null,
        
        [Parameter()]
        [ValidateRange(1,5)]
        [int]$RetryCount = 3,
        
        [Parameter()]
        [switch]$UseDeviceCode
    )
    
    # Load config if not provided
    if (!$AuthConfig) {
        $AuthConfig = Import-DeltaCrownAuthConfig
    }
    
    $attempt = 0
    $connected = $false
    $lastError = $null
    
    while ($attempt -lt $RetryCount -and !$connected) {
        $attempt++
        
        try {
            # Disconnect any existing sessions
            Disconnect-MgGraph -ErrorAction SilentlyContinue
            
            # Certificate-based authentication (Production)
            if ($AuthConfig.CertificatePath -and (Test-Path $AuthConfig.CertificatePath)) {
                $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
                    $AuthConfig.CertificatePath,
                    $AuthConfig.CertificatePassword
                )
                
                Connect-MgGraph -ClientId $AuthConfig.ClientId -TenantId $AuthConfig.TenantId -Certificate $cert -NoWelcome -ErrorAction Stop
                Write-Verbose "Connected to Graph using certificate authentication"
            }
            # Thumbprint-based authentication
            elseif ($AuthConfig.Thumbprint) {
                Connect-MgGraph -ClientId $AuthConfig.ClientId -TenantId $AuthConfig.TenantId -CertificateThumbprint $AuthConfig.Thumbprint -NoWelcome -ErrorAction Stop
                Write-Verbose "Connected to Graph using certificate thumbprint"
            }
            # Managed Identity (Azure)
            elseif ($AuthConfig.UseManagedIdentity) {
                Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop
                Write-Verbose "Connected to Graph using Managed Identity"
            }
            # Client Secret (for service principals - less secure than cert)
            elseif ($AuthConfig.ClientSecret) {
                $secureSecret = $AuthConfig.ClientSecret | ConvertTo-SecureString -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential($AuthConfig.ClientId, $secureSecret)
                Connect-MgGraph -TenantId $AuthConfig.TenantId -ClientSecretCredential $credential -NoWelcome -ErrorAction Stop
                Write-Verbose "Connected to Graph using client secret"
            }
            # Device Code (CI/CD where interactive is not possible)
            elseif ($UseDeviceCode) {
                Connect-MgGraph -Scopes $RequiredScopes -UseDeviceCode -NoWelcome -ErrorAction Stop
                Write-Verbose "Connected to Graph using device code flow"
            }
            # Interactive (Development only)
            elseif ($AuthConfig.Interactive -or $AuthConfig._Environment -eq "Development") {
                # SECURITY WARNING for production
                if ($AuthConfig._Environment -eq "Production") {
                    throw "Interactive authentication is NOT allowed in Production environment!"
                }
                Connect-MgGraph -Scopes $RequiredScopes -NoWelcome -ErrorAction Stop
                Write-Verbose "Connected to Graph using interactive authentication (Development mode)"
            }
            else {
                throw "No valid authentication method available in configuration"
            }
            
            $connected = $true
            $context = Get-MgContext
            $script:AuthContext['Graph'] = @{
                TenantId = $context.TenantId
                Account = $context.Account
                Scopes = $context.Scopes
                ConnectedAt = Get-Date
                AuthMethod = if ($AuthConfig.CertificatePath) { "Certificate" } elseif ($AuthConfig.Thumbprint) { "CertificateThumbprint" } elseif ($AuthConfig.UseManagedIdentity) { "ManagedIdentity" } elseif ($AuthConfig.ClientSecret) { "ClientSecret" } elseif ($UseDeviceCode) { "DeviceCode" } else { "Interactive" }
            }
        }
        catch {
            $lastError = $_
            Write-Warning "Graph connection attempt $attempt failed: $($_.Exception.Message)"
            if ($attempt -lt $RetryCount) {
                Start-Sleep -Seconds (2 * $attempt)
            }
        }
    }
    
    if (!$connected) {
        throw "Failed to connect to Microsoft Graph after $RetryCount attempts. Last error: $lastError"
    }
    
    Write-Verbose "Successfully connected to Microsoft Graph"
    return $script:AuthContext['Graph']
}

#endregion


#region Exchange Online Authentication

<#
.SYNOPSIS
    Connects to Exchange Online with proper authentication.
.DESCRIPTION
    Supports certificate-based auth (production) and interactive (dev).
    Implements retry logic and proper error handling.
#>
function Connect-DeltaCrownExchange {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$AuthConfig = $null,
        
        [Parameter()]
        [ValidateRange(1,5)]
        [int]$RetryCount = 3
    )
    
    if (!$AuthConfig) {
        $AuthConfig = Import-DeltaCrownAuthConfig
    }
    
    $attempt = 0
    $connected = $false
    $lastError = $null
    
    while ($attempt -lt $RetryCount -and !$connected) {
        $attempt++
        
        try {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
            
            # Certificate-based authentication (Production)
            if ($AuthConfig.CertificatePath -and (Test-Path $AuthConfig.CertificatePath)) {
                Connect-ExchangeOnline -CertificateFilePath $AuthConfig.CertificatePath -AppId $AuthConfig.ClientId -Organization "$($AuthConfig.TenantId)" -ShowBanner:$false -ErrorAction Stop
                Write-Verbose "Connected to Exchange Online using certificate"
            }
            elseif ($AuthConfig.Thumbprint) {
                Connect-ExchangeOnline -CertificateThumbprint $AuthConfig.Thumbprint -AppId $AuthConfig.ClientId -Organization "$($AuthConfig.TenantId)" -ShowBanner:$false -ErrorAction Stop
                Write-Verbose "Connected to Exchange Online using thumbprint"
            }
            elseif ($AuthConfig.Interactive -or $AuthConfig._Environment -eq "Development") {
                if ($AuthConfig._Environment -eq "Production") {
                    throw "Interactive authentication is NOT allowed in Production environment!"
                }
                Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
                Write-Verbose "Connected to Exchange Online using interactive authentication"
            }
            else {
                throw "No valid authentication method available for Exchange Online"
            }
            
            $connected = $true
            $script:AuthContext['Exchange'] = @{
                ConnectedAt = Get-Date
                Method = if ($AuthConfig.CertificatePath) { "Certificate" } elseif ($AuthConfig.Thumbprint) { "Thumbprint" } else { "Interactive" }
            }
        }
        catch {
            $lastError = $_
            Write-Warning "Exchange connection attempt $attempt failed: $($_.Exception.Message)"
            if ($attempt -lt $RetryCount) {
                Start-Sleep -Seconds (2 * $attempt)
            }
        }
    }
    
    if (!$connected) {
        throw "Failed to connect to Exchange Online after $RetryCount attempts. Last error: $lastError"
    }
    
    Write-Verbose "Successfully connected to Exchange Online"
}

#endregion

#region Security & Compliance Authentication

<#
.SYNOPSIS
    Connects to Security & Compliance Center (IPPS) with proper authentication.
.DESCRIPTION
    Supports certificate-based auth (production) and interactive (dev).
    Used for DLP policy management.
#>
function Connect-DeltaCrownIPPS {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$AuthConfig = $null,
        
        [Parameter()]
        [ValidateRange(1,5)]
        [int]$RetryCount = 3
    )
    
    if (!$AuthConfig) {
        $AuthConfig = Import-DeltaCrownAuthConfig
    }
    
    $attempt = 0
    $connected = $false
    $lastError = $null
    
    while ($attempt -lt $RetryCount -and !$connected) {
        $attempt++
        
        try {
            # Certificate-based authentication (Production)
            if ($AuthConfig.CertificatePath -and (Test-Path $AuthConfig.CertificatePath)) {
                Connect-IPPSSession -CertificateFilePath $AuthConfig.CertificatePath -AppId $AuthConfig.ClientId -Organization "$($AuthConfig.TenantId)" -ShowBanner:$false -ErrorAction Stop
                Write-Verbose "Connected to IPPS using certificate"
            }
            elseif ($AuthConfig.Thumbprint) {
                Connect-IPPSSession -CertificateThumbprint $AuthConfig.Thumbprint -AppId $AuthConfig.ClientId -Organization "$($AuthConfig.TenantId)" -ShowBanner:$false -ErrorAction Stop
                Write-Verbose "Connected to IPPS using thumbprint"
            }
            elseif ($AuthConfig.Interactive -or $AuthConfig._Environment -eq "Development") {
                if ($AuthConfig._Environment -eq "Production") {
                    throw "Interactive authentication is NOT allowed in Production environment!"
                }
                Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop
                Write-Verbose "Connected to IPPS using interactive authentication"
            }
            else {
                throw "No valid authentication method available for IPPS"
            }
            
            $connected = $true
            $script:AuthContext['IPPS'] = @{
                ConnectedAt = Get-Date
                Method = if ($AuthConfig.CertificatePath) { "Certificate" } elseif ($AuthConfig.Thumbprint) { "Thumbprint" } else { "Interactive" }
            }
        }
        catch {
            $lastError = $_
            Write-Warning "IPPS connection attempt $attempt failed: $($_.Exception.Message)"
            if ($attempt -lt $RetryCount) {
                Start-Sleep -Seconds (2 * $attempt)
            }
        }
    }
    
    if (!$connected) {
        throw "Failed to connect to IPPS after $RetryCount attempts. Last error: $lastError"
    }
    
    Write-Verbose "Successfully connected to Security & Compliance Center"
}

#endregion

#region Utility Functions

<#
.SYNOPSIS
    Disconnects all active connections.
#>
function Disconnect-DeltaCrownAll {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Disconnecting all Delta Crown connections..."
    
    try {
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
        Write-Verbose "Disconnected SharePoint"
    }
    catch { }
    
    try {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Write-Verbose "Disconnected Microsoft Graph"
    }
    catch { }
    

    try {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        Write-Verbose "Disconnected Exchange Online"
    }
    catch { }
    
    # Note: IPPS sessions are disconnected via Disconnect-ExchangeOnline
    $script:AuthContext.Clear()
    Write-Verbose "Cleared authentication context"
}

<#
.SYNOPSIS
    Gets current authentication status.
#>
function Get-DeltaCrownAuthStatus {
    [CmdletBinding()]
    param()
    
    return [PSCustomObject]@{
        SharePointConnected = $null -ne (Get-PnPContext -ErrorAction SilentlyContinue)
        GraphConnected = $null -ne (Get-MgContext -ErrorAction SilentlyContinue)
        AuthContext = $script:AuthContext.Clone()
        Timestamp = Get-Date
    }
}

<#
.SYNOPSIS
    Saves authentication configuration to encrypted file.
#>
function Export-DeltaCrownAuthConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,
        
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    # Ensure directory exists
    $directory = Split-Path -Parent $Path
    if (!(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    # Export as encrypted CLIXML (Windows only)
    if ($IsWindows -or $PSVersionTable.PSEdition -eq "Desktop") {
        $Config | Export-Clixml -Path $Path -Force
        Write-Verbose "Exported encrypted configuration to: $Path"
    }
    else {
        # Fallback for non-Windows: use base64 encoding (less secure!)
        Write-Warning "Non-Windows platform detected. Using less secure encoding. Consider using environment variables or Key Vault instead."
        $json = $Config | ConvertTo-Json -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $encoded = [Convert]::ToBase64String($bytes)
        $encoded | Out-File -FilePath $Path -Force
    }
}

#endregion

#region Business Premium Warning

<#
.SYNOPSIS
    Displays prominent Business Premium license warning.
.DESCRIPTION
    Business Premium does NOT include Information Barriers.
    This warning must be acknowledged before proceeding.
#>
function Show-DeltaCrownBusinessPremiumWarning {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ForceAcknowledgment = $false
    )
    
    $warning = @"
`n╔══════════════════════════════════════════════════════════════════════════════╗
║ ⚠️  CRITICAL SECURITY WARNING - BUSINESS PREMIUM LICENSE LIMITATIONS      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  Your tenant uses Microsoft 365 Business Premium, which DOES NOT include:    ║
║                                                                               ║
║  ❌ Information Barriers (crucial for franchise isolation)                   ║
║  ❌ Advanced threat protection for SharePoint/OneDrive                       ║
║  ❌ Customer Lockbox                                                         ║
║                                                                               ║
║  COMPENSATING CONTROLS THAT MUST BE IMPLEMENTED:                             ║
║                                                                               ║
║  1. SITE-LEVEL ISOLATION: Each brand gets dedicated site collections       ║
║  2. UNIQUE PERMISSIONS: Break inheritance on ALL brand sites                 ║
║  3. CUSTOM GROUPS: Use Azure AD dynamic groups per brand                   ║
║  4. NO 'EVERYONE' GROUPS: Explicit user assignment only                     ║
║  5. REGULAR AUDITS: Monthly permission reviews required                     ║
║  6. DLP POLICIES: Configure Data Loss Prevention rules                       ║
║                                                                               ║
║  FAILURE TO IMPLEMENT THESE CONTROLS MAY RESULT IN:                          ║
║  • Cross-brand data leakage                                                  ║
║  • Compliance violations                                                     ║
║  • Franchisee data access by unauthorized users                              ║
║                                                                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
"@
    
    Write-Host $warning -ForegroundColor Red
    
    if ($ForceAcknowledgment) {
        $ack = Read-Host "`nType 'I UNDERSTAND' to acknowledge and continue"
        if ($ack -ne "I UNDERSTAND") {
            throw "Business Premium acknowledgment required. Operation cancelled."
        }
        Write-Host "Acknowledgment recorded.`n" -ForegroundColor Green
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Connect-DeltaCrownSharePoint'
    'Connect-DeltaCrownGraph'
    'Connect-DeltaCrownExchange'
    'Connect-DeltaCrownIPPS'
    'Disconnect-DeltaCrownAll'
    'Get-DeltaCrownAuthStatus'
    'Import-DeltaCrownAuthConfig'
    'Export-DeltaCrownAuthConfig'
    'Show-DeltaCrownBusinessPremiumWarning'
)
