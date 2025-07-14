param (
    [switch]$Force
)

# Ensure UTF-8
chcp 65001 > $null

# Check for admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    pause
    exit 1
}

# Log file
$LogFile = "$PSScriptRoot\install-dev-env.log"
Start-Transcript -Path $LogFile -Append

# Progress
$global:Step = 0
$global:TotalSteps = 6

function Show-Progress {
    param ([string]$Activity)
    $global:Step++
    $percent = [int](($Step / $TotalSteps) * 100)
    Write-Progress -Activity "Installing Developer Tools" -Status "$Activity ($Step of $TotalSteps)" -PercentComplete $percent
    Write-Host "`n[$Step/$TotalSteps] $Activity"
}

function Initialize-Winget {
    Write-Host "Checking winget..."
    try {
        winget list > $null
    } catch {
        Write-Warning "⚠️ Winget not initialized. Please run 'winget list' manually once and accept the terms. Then rerun this script."
        pause
        exit 1
    }
}

function Read-YesNo {
    param ([string]$Prompt)
    $response = Read-Host $Prompt
    return $response -match '^(Y|y)'
}

function Ensure-Installed {
    param (
        [string]$Id,
        [string]$Name
    )
    $installed = winget list --id $Id | Select-String $Id
    if ($installed) {
        if ($Force) {
            Write-Host "$Name is already installed. Updating..."
            winget upgrade --id $Id -e --silent
        } else {
            if (Read-YesNo "$Name is already installed. Update it? [Y/N]") {
                winget upgrade --id $Id -e --silent
            } else {
                Write-Host "Skipped $Name"
            }
        }
    } else {
        Write-Host "Installing $Name..."
        winget install --id $Id -e --silent
    }
}

# ---- Begin ----
Write-Host "`nStarting installation (Force = $Force)"

Show-Progress "Initializing winget"
Initialize-Winget

Show-Progress "Installing PowerShell 7"
Ensure-Installed -Id "Microsoft.PowerShell" -Name "PowerShell 7"

Show-Progress "Installing Windows Terminal"
Ensure-Installed -Id "Microsoft.WindowsTerminal" -Name "Windows Terminal"

Show-Progress "Installing Git"
Ensure-Installed -Id "Git.Git" -Name "Git"

Show-Progress "Installing GitHub CLI"
Ensure-Installed -Id "GitHub.cli" -Name "GitHub CLI"

Show-Progress "Installing Visual Studio Code"
Ensure-Installed -Id "Microsoft.VisualStudioCode" -Name "Visual Studio Code"

Show-Progress "Installing Volta"
Ensure-Installed -Id "Volta.Volta" -Name "Volta"

Write-Progress -Activity "Installing Developer Tools" -Completed
Write-Host "`n✅ Installation complete. You can now restart Windows Terminal or run Volta-based commands after reloading session."

Stop-Transcript
pause
