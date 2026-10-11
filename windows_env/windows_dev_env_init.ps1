#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

########################################################################
# USER CONFIGURATION
########################################################################

$GIT_USER_NAME  = "Kevin Aimaier"
$GIT_USER_EMAIL = "kflyn825@outlook.com"

$SSH_KEY_PATH   = "$HOME\.ssh\id_ed25519"

########################################################################
# PACKAGES
########################################################################

$Packages = @(
    # Development
    "Git.Git",
    "Microsoft.VisualStudioCode",
    "Microsoft.PowerShell",
    "Notepad++.Notepad++",

    # Archive
    "RARLab.WinRAR",

    # PDF
    "SumatraPDF.SumatraPDF",

    # Media
    "VideoLAN.VLC",

    # Search
    "voidtools.Everything",

    # Disk Health
    "CrystalDewWorld.CrystalDiskInfo",

    # Remote Access
    "Mobatek.MobaXterm"
)

########################################################################
# INSTALL PACKAGES
########################################################################

Write-Host ""
Write-Host "========================================"
Write-Host " Installing Packages"
Write-Host "========================================"

foreach ($Package in $Packages)
{
    Write-Host "[PKG] $Package"

    try
    {
        winget install `
            --id $Package `
            --exact `
            --silent `
            --accept-package-agreements `
            --accept-source-agreements
    }
    catch
    {
        Write-Warning "Failed to install $Package"
    }
}

########################################################################
# VERIFY REQUIRED TOOLS
########################################################################

if (-not (Get-Command git -ErrorAction SilentlyContinue))
{
    throw "Git not found after installation."
}

if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue))
{
    throw "OpenSSH Client is not installed."
}

########################################################################
# START SSH AGENT
########################################################################

Write-Host ""
Write-Host "========================================"
Write-Host " Starting ssh-agent"
Write-Host "========================================"

Set-Service ssh-agent -StartupType Automatic

if ((Get-Service ssh-agent).Status -ne "Running")
{
    Start-Service ssh-agent
}

########################################################################
# CREATE .SSH DIRECTORY
########################################################################

$SSH_DIR = Split-Path $SSH_KEY_PATH

if (-not (Test-Path $SSH_DIR))
{
    New-Item `
        -ItemType Directory `
        -Path $SSH_DIR `
        -Force | Out-Null
}

########################################################################
# GENERATE SSH KEY
########################################################################

Write-Host ""
Write-Host "========================================"
Write-Host " SSH Key Setup"
Write-Host "========================================"

if (-not (Test-Path $SSH_KEY_PATH))
{
    Write-Host "[SSH] Generating ED25519 key..."
    Write-Host "[SSH] Press Enter twice for an empty passphrase."

    ssh-keygen `
        -t ed25519 `
        -C $GIT_USER_EMAIL `
        -f $SSH_KEY_PATH

    Write-Host "[SSH] Key generated."
}
else
{
    Write-Host "[SSH] Existing key found."
}

########################################################################
# ADD KEY TO AGENT
########################################################################

Write-Host "[SSH] Adding key to ssh-agent..."

ssh-add $SSH_KEY_PATH

########################################################################
# GIT CONFIGURATION
########################################################################

Write-Host ""
Write-Host "========================================"
Write-Host " Git Configuration"
Write-Host "========================================"

$GitConfig = @{
    "user.name"          = $GIT_USER_NAME
    "user.email"         = $GIT_USER_EMAIL
    "init.defaultBranch" = "main"
    "pull.rebase"        = "false"
    "core.autocrlf"      = "false"
    "credential.helper"  = "manager"
}

foreach ($Key in $GitConfig.Keys)
{
    git config --global $Key $GitConfig[$Key]
}

########################################################################
# SHOW GIT CONFIG
########################################################################

Write-Host ""
Write-Host "========================================"
Write-Host " Git Config"
Write-Host "========================================"

git config --global --list

########################################################################
# PRINT PUBLIC KEY
########################################################################

Write-Host ""
Write-Host "========================================"
Write-Host " SSH PUBLIC KEY"
Write-Host "========================================"
Write-Host ""

Get-Content "${SSH_KEY_PATH}.pub"

########################################################################
# COMPLETE
########################################################################

Write-Host ""
Write-Host "========================================"
Write-Host " Initialization Complete"
Write-Host "========================================"
Write-Host ""

Write-Host "Add the above SSH key to:"
Write-Host "  https://github.com/settings/keys"
Write-Host "  https://gitlab.com/-/profile/keys"
Write-Host ""

Write-Host "Verify:"
Write-Host "  ssh -T git@github.com"
Write-Host "  ssh -T git@gitlab.com"
Write-Host ""