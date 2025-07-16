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
        '-NoExit',                     # keep window open for visibility
        '-File', "`"$scriptPath`""
    )
    if ($Force) { $elevateArgs += '-Force' }
    Start-Process 'pwsh.exe' -ArgumentList $elevateArgs -Verb RunAs
    exit
}

try {
    # 0) Ensure per-user policy allows script
    if ((Get-ExecutionPolicy -Scope CurrentUser) -ne 'RemoteSigned') {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    }

    # 1) Emoji toggle (disable on Cyrillic UI)
    $culture      = [Globalization.CultureInfo]::CurrentUICulture.Name
    $disableEmoji = $culture -match '^(ru|uk|bg|sr|mk|be|kk|ky|uz(-Cyrl)?)(-|$)'
    $EWarn        = if ($disableEmoji) { '' } else { '⚠️ ' }
    $EDone        = if ($disableEmoji) { '' } else { '✅ ' }

    # 2) Define winget source & package args as arrays for splatting
    $DefaultSource = 'winget'
    $SourceArgs    = @(
        '--source', $DefaultSource,
        '--accept-source-agreements'
    )
    $PackageArgs   = @(
        '--accept-package-agreements'
    )

    # 3) Ensure UTF-8 code page
    chcp 65001 | Out-Null

    # 4) Add winget to PATH on Win10 if missing
    try {
        Get-Command winget -ErrorAction Stop | Out-Null
    } catch {
        $wingetPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
        if (-not ($env:Path -split ';' | Where-Object { $_ -ieq $wingetPath })) {
            Write-Host "Adding winget path to user PATH..."
            [Environment]::SetEnvironmentVariable(
                'Path',
                "$env:Path;$wingetPath",
                [EnvironmentVariableTarget]::User
            )
            Write-Host "PATH updated; relaunching script..."
            Start-Process 'pwsh.exe' -ArgumentList @(
                '-NoProfile','-ExecutionPolicy','Bypass','-NoExit',
                '-File', "`"$MyInvocation.MyCommand.Definition`""
            ) -Verb RunAs
            exit
        }
    }

    # 5) Begin logging
    $LogFile = Join-Path $PSScriptRoot 'install-dev-env.log'
    Start-Transcript -Path $LogFile -Append

    # 6) Progress bar setup
    $global:Step       = 0
    $global:TotalSteps = 6
    function Show-Progress {
        param([string]$Activity)
        $global:Step++
        $p = [int](( $Step / $TotalSteps ) * 100)
        $p = [math]::Max(0, [math]::Min($p,100))
        Write-Progress -Activity "Installing Developer Tools" `
                       -Status "$Activity ($Step of $TotalSteps)" `
                       -PercentComplete $p
        Write-Host "`n[$Step/$TotalSteps] $Activity"
    }

    # 7) Initialize only the 'winget' source
    function Initialize-Winget {
        Write-Host "Authorizing only the '$DefaultSource' source..."
        try {
            winget source update @SourceArgs *> $null
            winget list          @SourceArgs *> $null
        } catch {
            Write-Warning "${EWarn}Unable to initialize winget source '$DefaultSource'."
            Write-Warning "Run:  winget source update @SourceArgs"
            pause; exit 1
        }
    }

    # 8) Simple Y/N prompt
    function Read-YesNo { param($Prompt) ; (Read-Host $Prompt) -match '^[Yy]' }

    # 9) Install or upgrade via winget (using array splatting)
    function Ensure-Installed {
        param($Id, $Name)

        $found = winget list --id $Id @SourceArgs 2>&1 |
                 Select-String "^$Id"

        if ($found) {
            if ($Force) {
                Write-Host "$Name already installed; upgrading..."
                winget upgrade --id $Id -e --silent @SourceArgs @PackageArgs
            } elseif (Read-YesNo "$Name is already installed. Update it? [Y/N]") {
                winget upgrade --id $Id -e --silent @SourceArgs @PackageArgs
            } else {
                Write-Host "Skipped $Name"
            }
        } else {
            Write-Host "Installing $Name..."
            winget install --id $Id -e --silent @SourceArgs @PackageArgs
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

    Show-Progress "Installing Visual Studio Code"
    Ensure-Installed -Id "Microsoft.VisualStudioCode" -Name "Visual Studio Code"

    Show-Progress "Installing Volta"
    Ensure-Installed -Id "Volta.Volta"               -Name "Volta"

    # 11) Completion
    Write-Progress -Activity "Installing Developer Tools" -Completed
    Write-Host "`n${EDone}Installation complete. You may restart your terminal now."

    Stop-Transcript
    Write-Host "Press any key to exit…"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)"
    Write-Host "Press any key to exit…"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
