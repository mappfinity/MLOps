# Install Docker Desktop on H: using the WSL 2 backend.
# Application files: H:\Apps\Docker
# Docker WSL data:   H:\DockerData
# Requires Windows PowerShell 5.1+ and an internet connection.

$ErrorActionPreference = 'Stop'
$InstallDir = 'H:\Apps\Docker'
$DataRoot   = 'H:\DockerData'
$Installer  = Join-Path $env:TEMP 'Docker Desktop Installer.exe'
$DownloadUrl = 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe'

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

# Self-elevate. Docker's all-users/custom-location install requires administrator rights.
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Requesting administrator approval...' -ForegroundColor Yellow
    $quotedScript = '"' + $PSCommandPath + '"'
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File $quotedScript"
    try {
        $process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -Wait -PassThru
        exit $process.ExitCode
    }
    catch {
        Write-Error "Could not start the elevated installer. $($_.Exception.Message)"
        exit 1
    }
}

try {
    Write-Step 'Checking prerequisites'

    if (-not (Test-Path -LiteralPath 'H:\')) {
        throw 'Drive H: was not found. Connect or mount the drive, then run this script again.'
    }

    if (-not (Get-Command 'wsl.exe' -ErrorAction SilentlyContinue)) {
        throw 'WSL was not found. Install WSL first, restart Windows if prompted, and run this script again.'
    }

    # Avoid silently treating an existing installation as a fresh install: installer flags
    # do not migrate an existing Docker Desktop installation or its data.
    $uninstallRoots = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $dockerEntry = Get-ItemProperty -Path $uninstallRoots -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq 'Docker Desktop' } |
        Select-Object -First 1

    $knownInstallPaths = @(
        "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
        "$env:LOCALAPPDATA\Programs\DockerDesktop\Docker Desktop.exe",
        'H:\Apps\Docker\Docker Desktop.exe'
    )
    $existingPath = $knownInstallPaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($dockerEntry -or $existingPath) {
        throw 'Docker Desktop appears to be installed already. This script is for a fresh install and will not move existing app files, images, containers, or volumes. Back up/migrate the existing installation separately before proceeding.'
    }

    # Docker's current Windows installer supports these flags. Update WSL first.
    Write-Step 'Updating WSL'
    & wsl.exe --update
    if ($LASTEXITCODE -ne 0) {
        throw "The 'wsl --update' command failed (exit code $LASTEXITCODE). Fix/update WSL, then run this script again."
    }

    $wslVersion = & wsl.exe --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not verify the modern WSL installation. Ensure WSL is updated (wsl --update), then rerun this script.'
    }
    $wslVersion | ForEach-Object { Write-Host $_ }

    Write-Step 'Creating target folders'
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    New-Item -ItemType Directory -Path $DataRoot -Force | Out-Null

    Write-Step 'Downloading official Docker Desktop installer'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $Installer -UseBasicParsing

    if (-not (Test-Path -LiteralPath $Installer) -or (Get-Item -LiteralPath $Installer).Length -lt 10MB) {
        throw 'The downloaded installer is missing or unexpectedly small. Delete the temporary installer and try again.'
    }

    $signature = Get-AuthenticodeSignature -FilePath $Installer
    if ($signature.Status -ne 'Valid') {
        throw "The downloaded installer signature is not valid (status: $($signature.Status)). The installer will not be run."
    }

    Write-Step 'Installing Docker Desktop on H:'
    Write-Host "Application: $InstallDir"
    Write-Host "WSL data:    $DataRoot"
    Write-Host 'The installer may show a progress window. Do not close this PowerShell window.'

    $installArgs = @(
        'install',
        "--installation-dir=$InstallDir",
        "--wsl-default-data-root=$DataRoot",
        '--backend=wsl-2'
    )
    $installerProcess = Start-Process -FilePath $Installer -ArgumentList $installArgs -Wait -PassThru
    if ($installerProcess.ExitCode -ne 0) {
        throw "Docker Desktop installer exited with code $($installerProcess.ExitCode). Review the installer message and retry if needed."
    }

    Write-Step 'Installation finished'
    Write-Host 'Open Docker Desktop from the Start menu and accept the terms when prompted.' -ForegroundColor Green
    Write-Host 'Then check Settings > Resources > Advanced and confirm the disk image location is on H:.'
    Write-Host 'In Settings > Resources > WSL Integration, enable integration for Ubuntu if you installed Ubuntu.'
    Write-Host "Test in Ubuntu with: docker version; docker run --rm hello-world"
}
catch {
    Write-Host "`nINSTALLATION FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
