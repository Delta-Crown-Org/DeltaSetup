# ============================================================================
# DeltaCrown.Config.psd1
# Centralized Configuration for Delta Crown Extensions
# ============================================================================
# DESCRIPTION: Single source of truth for all script configuration.
#              Modify this file to customize deployment parameters.
# ============================================================================

@{
    # =========================================================================
    # ENVIRONMENT SETTINGS
    # =========================================================================
    Environment = @{
        Name = "Development"  # Development, Staging, Production
        RequireAcknowledgment = $false  # Set to $true in Production
    }
    
    # =========================================================================
    # TENANT CONFIGURATION
    # =========================================================================
    Tenant = @{
        Name = "deltacrownext"
        AdminUrl = "https://deltacrownext-admin.sharepoint.com"
        DefaultTimeZone = 10  # US Central
        DefaultLanguage = 1033  # English (US)
    }
    
    # =========================================================================
    # MODULE REQUIREMENTS
    # =========================================================================
    RequiredModules = @{
        "PnP.PowerShell" = @{
            MinimumVersion = "2.0.0"
            Required = $true
        }
        "Microsoft.Graph.Authentication" = @{
            MinimumVersion = "2.0.0"
            Required = $true
        }
        "Microsoft.Graph.Groups" = @{
            MinimumVersion = "2.0.0"
            Required = $true
        }
        "Microsoft.Graph.Identity.DirectoryManagement" = @{
            MinimumVersion = "2.0.0"
            Required = $true
        }
        "Az.KeyVault" = @{
            MinimumVersion = "4.0.0"
            Required = $false  # Only needed for Key Vault auth
        }
    }
    
    # =========================================================================
    # BRANDING CONFIGURATION
    # =========================================================================
    Branding = @{
        Colors = @{
            Gold = "#C9A227"
            Black = "#1A1A1A"
            White = "#FFFFFF"
            GoldLight = "#D4B43F"
            GoldDark = "#B08D1F"
        }
        
        ThemeName = "Delta Crown Extensions Theme"
        
        ThemePalette = @{
            themePrimary = "#C9A227"
            themeLighterAlt = "#FBF7EA"
            themeLighter = "#F2E8C4"
            themeLight = "#E8D798"
            themeTertiary = "#D4B44F"
            themeSecondary = "#C9A227"
            themeDarkAlt = "#B08D1F"
            themeDark = "#947719"
            themeDarker = "#6D5813"
            neutralLighterAlt = "#F8F8F8"
            neutralLighter = "#F4F4F4"
            neutralLight = "#EAEAEA"
            neutralQuaternaryAlt = "#DADADA"
            neutralQuaternary = "#D0D0D0"
            neutralTertiaryAlt = "#C8C8C8"
            neutralTertiary = "#A19F9D"
            neutralSecondary = "#605E5C"
            neutralSecondaryAlt = "#8A8886"
            neutralPrimaryAlt = "#3B3A39"
            neutralPrimary = "#1A1A1A"
            neutralDark = "#201F1E"
            black = "#1A1A1A"
            white = "#FFFFFF"
            bodyBackground = "#FFFFFF"
            bodyText = "#1A1A1A"
        }
    }
    
    # =========================================================================
    # SITE CONFIGURATION
    # =========================================================================
    Sites = @{
        CorpHub = @{
            Url = "/sites/corp-hub"
            Title = "Corporate Shared Services"
            Description = "Central hub for shared franchise resources"
            Template = "SITEPAGEPUBLISHING#0"  # Communication Site
        }
        
        CorpAssociated = @(
            @{ 
                Url = "/sites/corp-hr"
                Title = "Corporate HR"
                Description = "Human Resources shared services"
                Template = "SITEPAGEPUBLISHING#0"
            },
            @{ 
                Url = "/sites/corp-it"
                Title = "Corporate IT"
                Description = "IT support and infrastructure services"
                Template = "SITEPAGEPUBLISHING#0"
            },
            @{ 
                Url = "/sites/corp-finance"
                Title = "Corporate Finance"
                Description = "Financial services and reporting"
                Template = "SITEPAGEPUBLISHING#0"
            },
            @{ 
                Url = "/sites/corp-training"
                Title = "Corporate Training"
                Description = "Training and development resources"
                Template = "SITEPAGEPUBLISHING#0"
            }
        )
        
        DCEHub = @{
            Url = "/sites/dce-hub"
            Title = "Delta Crown Extensions Hub"
            Description = "Delta Crown Extensions operational hub"
            Template = "SITEPAGEPUBLISHING#0"
        }
    }
    
    # =========================================================================
    # NAVIGATION CONFIGURATION
    # =========================================================================
    Navigation = @{
        CorpHub = @(
            @{ Title = "Home"; Url = "/sites/corp-hub"; IsHome = $true },
            @{ Title = "HR Resources"; Url = "/sites/corp-hr"; IsHome = $false },
            @{ Title = "IT Support"; Url = "/sites/corp-it"; IsHome = $false },
            @{ Title = "Finance"; Url = "/sites/corp-finance"; IsHome = $false },
            @{ Title = "Training"; Url = "/sites/corp-training"; IsHome = $false }
        )
        
        DCEHub = @(
            @{ Title = "Home"; Url = "/sites/dce-hub"; IsHome = $true },
            @{ Title = "Operations"; Url = "/sites/dce-hub/SitePages/Operations.aspx"; IsHome = $false },
            @{ Title = "Client Services"; Url = "/sites/dce-hub/SitePages/Client-Services.aspx"; IsHome = $false },
            @{ Title = "Marketing"; Url = "/sites/dce-hub/SitePages/Marketing.aspx"; IsHome = $false },
            @{ Title = "Document Center"; Url = "/sites/dce-hub/SitePages/Document-Center.aspx"; IsHome = $false }
        )
    }
    
    # =========================================================================
    # AZURE AD DYNAMIC GROUPS
    # =========================================================================
    DynamicGroups = @(
        @{
            DisplayName = "SG-DCE-AllStaff"
            Description = "All Delta Crown Extensions staff - auto-populated based on department or company attribute"
            MailNickname = "sg-dce-allstaff"
            MembershipRule = @'
(user.department -contains "Delta Crown") -or 
(user.companyName -contains "Delta Crown Extensions")
'@
            MembershipRuleProcessingState = "On"
            GroupTypes = @("DynamicMembership")
            SecurityEnabled = $true
            MailEnabled = $false
            Visibility = "Private"
        },
        @{
            DisplayName = "SG-DCE-Leadership"
            Description = "Delta Crown Extensions leadership team - Managers, Directors, and VPs"
            MailNickname = "sg-dce-leadership"
            MembershipRule = @'
(user.companyName -contains "Delta Crown") -and 
(
    (user.jobTitle -contains "Manager") -or 
    (user.jobTitle -contains "Director") -or 
    (user.jobTitle -contains "VP") -or 
    (user.jobTitle -contains "Vice President") -or
    (user.jobTitle -contains "Chief") -or
    (user.jobTitle -contains "President")
)
'@
            MembershipRuleProcessingState = "On"
            GroupTypes = @("DynamicMembership")
            SecurityEnabled = $true
            MailEnabled = $false
            Visibility = "Private"
        }
    )
    
    # =========================================================================
    # RETRY AND TIMEOUT SETTINGS
    # =========================================================================
    RetrySettings = @{
        MaxRetries = 3
        InitialDelaySeconds = 2
        MaxDelaySeconds = 60
        TimeoutSeconds = 120
    }
    
    # =========================================================================
    # LOGGING SETTINGS
    # =========================================================================
    Logging = @{
        LogPath = "phase2-week1/logs"
        ArchiveDays = 30
        MinLevel = "INFO"  # DEBUG, INFO, SUCCESS, WARNING, ERROR, CRITICAL
        IncludeTimestamps = $true
        IncludeContext = $true
    }
    
    # =========================================================================
    # SECURITY SETTINGS
    # =========================================================================
    Security = @{
        # COMPENSATING CONTROLS FOR BUSINESS PREMIUM
        # (No Information Barriers available)
        CompensatingControls = @(
            "SITE-LEVEL-ISOLATION: Each brand gets dedicated site collections"
            "UNIQUE-PERMISSIONS: Break inheritance on ALL brand sites"
            "CUSTOM-GROUPS: Use Azure AD dynamic groups per brand"
            "NO-EVERYONE-GROUPS: Explicit user assignment only"
            "REGULAR-AUDITS: Monthly permission reviews required"
            "DLP-POLICIES: Configure Data Loss Prevention rules"
        )
        
        # Forbidden groups that should NEVER be used
        ForbiddenGroups = @(
            "Everyone"
            "Everyone except external users"
            "All Users"
            "NT AUTHORITY\Authenticated Users"
        )
        
        # Required permission level for sensitive operations
        AdminRoles = @(
            "SharePoint Administrator"
            "Global Administrator"
        )
    }
    
    # =========================================================================
    # DOCUMENTATION PATHS
    # =========================================================================
    Paths = @{
        Modules = "phase2-week1/modules"
        Scripts = "phase2-week1/scripts"
        Logs = "phase2-week1/logs"
        Docs = "phase2-week1/docs"
        Templates = "phase2-week1/templates"
    }
}
