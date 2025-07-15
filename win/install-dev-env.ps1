param (
    [switch]$Force
)

# --- Auto-elevation: relaunch script as Administrator if not already ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent())
    .IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Force) { $argList += " -Force" }
    Start-Process -FilePath pwsh -ArgumentList $argList -Verb RunAs
    exit
}

# --- 0) Ensure we can run this script even if LocalMachine policy is restrictive ---
try {
    if ((Get-ExecutionPolicy -Scope CurrentUser) -ne 'RemoteSigned') {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    }
} catch {
    Write-Warning "Could not set execution policy for CurrentUser: $_"
}

# --- 1) Emoji toggle based on UI culture ---
$culture = [System.Globalization.CultureInfo]::CurrentUICulture.Name
$disableEmoji = $false
if ($culture -match '^(ru|uk|bg|sr|mk|be|kk|ky|uz(-Cyrl)?)(\-|$)') {
    $disableEmoji = $true
}
$EWarn = if ($disableEmoji) { '' } else { '⚠️ ' }
$EDone = if ($disableEmoji) { '' } else { '✅ ' }

# --- 2) Define winget agreement flags ---
$AgreementArgs = "--accept-source-agreements --accept-package-agreements"

# Ensure UTF-8 so any remaining Unicode still works
chcp 65001 > $null

# --- 3) Ensure winget is on PATH (Windows 10) ---
try {
    Get-Command winget -ErrorAction Stop | Out-Null
} catch {
    $wingetPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    if (-not ($env:Path -split ';' | Where-Object { $_ -ieq $wingetPath })) {
        Write-Host "Adding winget path to PATH for Windows 10..."
        $newPath = "$env:Path;$wingetPath"
        [Environment]::SetEnvironmentVariable('Path', $newPath, [EnvironmentVariableTarget]::User)
        Write-Host "Path updated. Relaunching terminal and script to apply changes..."
        # Launch a new elevated PowerShell window and rerun the script
        Start-Process -FilePath pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($MyInvocation.BoundParameters.Keys | ForEach-Object { "-$_ $($MyInvocation.BoundParameters[$_])" } )" -Verb RunAs
        exit
    }
}

# ---- Begin logging ----
$LogFile = "$PSScriptRoot\install-dev-env.log"
Start-Transcript -Path $LogFile -Append

# ---- Progress tracking ----
$global:Step     = 0
$global:TotalSteps = 6

function Show-Progress {
    param ([string]$Activity)
    $global:Step++
    $rawPercent = ($Step / $TotalSteps) * 100
    $percent    = [int]([math]::Max(0, [math]::Min($rawPercent, 100)))
    Write-Progress `
      -Activity "Installing Developer Tools" `
      -Status "$Activity ($Step of $TotalSteps)" `
      -PercentComplete $percent
    Write-Host "`n[$Step/$TotalSteps] $Activity"
}

# ---- Initialization of winget ----
function Initialize-Winget {
    Write-Host "Checking & authorizing winget source agreements..."
    try {
        winget list $AgreementArgs *> $null
    } catch {
        Write-Warning "${EWarn}Unable to initialize winget. Please run 'winget source update $AgreementArgs' once and accept the terms, then rerun this script."
        pause
        exit 1
    }
}

# ---- Yes/No prompt helper ----
function Read-YesNo {
    param ([string]$Prompt)
    $response = Read-Host $Prompt
    return $response -match '^[Yy]'
}

# ---- Install or update via winget ----
function Ensure-Installed {
    param (
        [string]$Id,
        [string]$Name
    )
    $installed = winget list --id $Id $AgreementArgs 2>&1 | Select-String $Id
    if ($installed) {
        if ($Force) {
            Write-Host "$Name is already installed. Updating..."
            winget upgrade --id $Id -e --silent $AgreementArgs
        } else {
            if (Read-YesNo "$Name is already installed. Update it? [Y/N]") {
                winget upgrade --id $Id -e --silent $AgreementArgs
            } else {
                Write-Host "Skipped $Name"
            }
        }
    } else {
        Write-Host "Installing $Name..."
        winget install --id $Id -e --silent $AgreementArgs
    }
}

# ---- Main installation steps ----
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

# ---- Complete ----
Write-Progress -Activity "Installing Developer Tools" -Completed
Write-Host "`n${EDone}Installation complete. You can now restart Windows Terminal or run Volta-based commands after reloading session."

Stop-Transcript
pause
