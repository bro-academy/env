param (
    [switch]$Force
)

# --- Auto-elevation: relaunch as Administrator if not already ---
$winPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $winPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath  = $MyInvocation.MyCommand.Definition
    $elevateArgs = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-NoExit',                     # keep window open to show output/errors
        '-File', "`"$scriptPath`""
    )
    if ($Force) { $elevateArgs += '-Force' }
    Start-Process 'pwsh.exe' -ArgumentList $elevateArgs -Verb RunAs
    exit
}

try {
    # 0) Ensure per-user ExecutionPolicy allows running this script
    if ((Get-ExecutionPolicy -Scope CurrentUser) -ne 'RemoteSigned') {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    }

    # 1) Emoji toggle based on UI culture (omit on Cyrillic locales)
    $culture      = [System.Globalization.CultureInfo]::CurrentUICulture.Name
    $disableEmoji = $culture -match '^(ru|uk|bg|sr|mk|be|kk|ky|uz(-Cyrl)?)(\-|$)'
    $EWarn        = if ($disableEmoji) { '' } else { '⚠️ ' }
    $EDone        = if ($disableEmoji) { '' } else { '✅ ' }

    # 2) Winget source and package agreement flags
    $DefaultSource = 'winget'
    $SourceArgs    = "--source $DefaultSource --accept-source-agreements"
    $PackageArgs   = "--accept-package-agreements"

    # 3) Ensure UTF-8 code page
    chcp 65001 | Out-Null

    # 4) Ensure winget.exe is on the PATH (Windows 10)
    try {
        Get-Command winget -ErrorAction Stop | Out-Null
    } catch {
        $wingetPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
        if (-not ($env:Path -split ';' | Where-Object { $_ -ieq $wingetPath })) {
            Write-Host "Adding winget path to PATH..."
            [Environment]::SetEnvironmentVariable(
                'Path',
                "$env:Path;$wingetPath",
                [EnvironmentVariableTarget]::User
            )
            Write-Host "Path updated. Relaunching script..."
            Start-Process 'pwsh.exe' -ArgumentList @(
                '-NoProfile','-ExecutionPolicy','Bypass','-NoExit',
                '-File', "`"$MyInvocation.MyCommand.Definition`""
            ) -Verb RunAs
            exit
        }
    }

    # 5) Start logging
    $LogFile = Join-Path $PSScriptRoot 'install-dev-env.log'
    Start-Transcript -Path $LogFile -Append

    # 6) Progress tracking setup
    $global:Step       = 0
    $global:TotalSteps = 6
    function Show-Progress {
        param([string]$Activity)
        $global:Step++
        $rawPercent = ($Step / $TotalSteps) * 100
        $percent    = [int]([math]::Max(0, [math]::Min($rawPercent, 100)))
        Write-Progress -Activity "Installing Developer Tools" `
                       -Status "$Activity ($Step of $TotalSteps)" `
                       -PercentComplete $percent
        Write-Host "`n[$Step/$TotalSteps] $Activity"
    }

    # 7) Initialize only the 'winget' source
    function Initialize-Winget {
        Write-Host "Authorizing only the '$DefaultSource' source..."
        try {
            winget source update --name $DefaultSource $SourceArgs *> $null
            winget list --source $DefaultSource $SourceArgs *> $null
        } catch {
            Write-Warning "${EWarn}Unable to initialize winget source '$DefaultSource'."
            Write-Warning "Please run: winget source update --name $DefaultSource $SourceArgs"
            pause; exit 1
        }
    }

    # 8) Yes/No prompt helper
    function Read-YesNo {
        param([string]$Prompt)
        return (Read-Host $Prompt) -match '^[Yy]'
    }

    # 9) Install or upgrade packages via winget (using only the 'winget' source)
    function Ensure-Installed {
        param (
            [string]$Id,
            [string]$Name
        )
        $found = winget list --id $Id --source $DefaultSource $SourceArgs 2>&1 |
                 Select-String "^$Id"
        if ($found) {
            if ($Force) {
                Write-Host "$Name already installed; upgrading..."
                winget upgrade --id $Id --source $DefaultSource -e --silent $SourceArgs $PackageArgs
            } elseif (Read-YesNo "$Name is already installed. Update it? [Y/N]") {
                winget upgrade --id $Id --source $DefaultSource -e --silent $SourceArgs $PackageArgs
            } else {
                Write-Host "Skipped $Name"
            }
        } else {
            Write-Host "Installing $Name..."
            winget install --id $Id --source $DefaultSource -e --silent $SourceArgs $PackageArgs
        }
    }

    # 10) Main installation workflow
    Write-Host "`nStarting installation (Force = $Force)`n"

    Show-Progress "Initializing winget"
    Initialize-Winget

    Show-Progress "Installing PowerShell 7"
    Ensure-Installed -Id "Microsoft.PowerShell"      -Name "PowerShell 7"

    Show-Progress "Installing Windows Terminal"
    Ensure-Installed -Id "Microsoft.WindowsTerminal" -Name "Windows Terminal"

    Show-Progress "Installing Git"
    Ensure-Installed -Id "Git.Git"                   -Name "Git"

    Show-Progress "Installing GitHub CLI"
    Ensure-Installed -Id "GitHub.cli"                -Name "GitHub CLI"

    Show-Progress "Installing Visual Studio Code"
    Ensure-Installed -Id "Microsoft.VisualStudioCode" -Name "Visual Studio Code"

    Show-Progress "Installing Volta"
    Ensure-Installed -Id "Volta.Volta"               -Name "Volta"

    # 11) Finish up
    Write-Progress -Activity "Installing Developer Tools" -Completed
    Write-Host "`n${EDone}Installation complete. You can now restart Windows Terminal or run Volta-based commands."

    Stop-Transcript
    Write-Host "Press any key to exit…"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)"
    Write-Host "Press any key to exit…"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}
