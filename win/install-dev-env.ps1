param (
    [switch]$Force
)

# Auto-elevate if not already running as admin
$winPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $winPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath  = $MyInvocation.MyCommand.Definition
    $elevateArgs = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-NoExit',                      # keep window open for errors/output
        '-File', "`"$scriptPath`""
    )
    if ($Force) { $elevateArgs += '-Force' }
    Start-Process 'pwsh.exe' -ArgumentList $elevateArgs -Verb RunAs
    exit
}

try {
    # 0) Ensure per-user ExecutionPolicy is RemoteSigned
    if ((Get-ExecutionPolicy -Scope CurrentUser) -ne 'RemoteSigned') {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    }

    # 1) Emoji toggle on Cyrillic-based UI cultures
    $culture      = [Globalization.CultureInfo]::CurrentUICulture.Name
    $disableEmoji = $culture -match '^(ru|uk|bg|sr|mk|be|kk|ky|uz(-Cyrl)?)(\-|$)'
    $EWarn        = if ($disableEmoji) { '' } else { '⚠️ ' }
    $EDone        = if ($disableEmoji) { '' } else { '✅ ' }

    # 2) Winget agreement flags, split by intent
    $SourceArgs  = '--accept-source-agreements'
    $PackageArgs = '--accept-package-agreements'

    # 3) UTF-8 code page
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

    # 5) Start transcript logging
    $LogFile = Join-Path $PSScriptRoot 'install-dev-env.log'
    Start-Transcript -Path $LogFile -Append

    # 6) Progress‐bar helper
    $global:Step       = 0
    $global:TotalSteps = 6
    function Show-Progress {
        param([string]$Activity)
        $global:Step++
        $p = [int](($Step / $TotalSteps) * 100)
        $p = [math]::Max(0, [math]::Min($p,100))
        Write-Progress -Activity "Installing Developer Tools" `
                       -Status "$Activity ($Step of $TotalSteps)" `
                       -PercentComplete $p
        Write-Host "`n[$Step/$TotalSteps] $Activity"
    }

    # 7) Initialize winget (source‐only)
    function Initialize-Winget {
        Write-Host "Authorizing winget sources..."
        try {
            winget source update $SourceArgs *> $null
            winget list $SourceArgs *> $null
        } catch {
            Write-Warning "${EWarn}Unable to initialize winget sources. Please run 'winget source update $SourceArgs' manually and accept the terms."
            pause; exit 1
        }
    }

    # 8) Yes/No prompt
    function Read-YesNo { param($Prompt) ; (Read-Host $Prompt) -match '^[Yy]' }

    # 9) Install or upgrade via winget (both flags)
    function Ensure-Installed {
        param($Id, $Name)
        $found = winget list --id $Id $SourceArgs 2>&1 | Select-String "^$Id"
        if ($found) {
            if ($Force) {
                Write-Host "$Name already installed; upgrading..."
                winget upgrade --id $Id -e --silent $SourceArgs $PackageArgs
            } elseif (Read-YesNo "$Name is already installed. Update it? [Y/N]") {
                winget upgrade --id $Id -e --silent $SourceArgs $PackageArgs
            } else {
                Write-Host "Skipped $Name"
            }
        } else {
            Write-Host "Installing $Name..."
            winget install --id $Id -e --silent $SourceArgs $PackageArgs
        }
    }

    # 10) Main workflow
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

    Show-Progress "Installing VS Code"
    Ensure-Installed -Id "Microsoft.VisualStudioCode" -Name "Visual Studio Code"

    Show-Progress "Installing Volta"
    Ensure-Installed -Id "Volta.Volta"               -Name "Volta"

    # 11) Done
    Write-Progress -Activity "Installing Developer Tools" -Completed
    Write-Host "`n${EDone}Installation complete."

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
