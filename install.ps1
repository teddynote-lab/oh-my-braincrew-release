#Requires -Version 5.1
# install.ps1 — Download and install the latest oh-my-braincrew binary from GitHub Releases
# Usage: iwr -useb https://raw.githubusercontent.com/teddynote-lab/oh-my-braincrew-release/main/install.ps1 | iex
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$Repo        = "teddynote-lab/oh-my-braincrew-release"
$BinaryName  = "oh-my-braincrew"
$InstallDir  = "$env:LOCALAPPDATA\oh-my-braincrew"
$GitHubApi   = "https://api.github.com/repos/$Repo/releases/latest"

# --- Helpers ---
function Write-Info {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Write-Err {
    param([string]$Message)
    Write-Error "ERROR: $Message"
}

# --- Architecture detection ---
function Get-Architecture {
    # Windows ARM is rare; default to amd64 for all Windows targets.
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -match "ARM") {
        Write-Info "ARM architecture detected; defaulting to amd64 binary."
    }
    return "amd64"
}

# --- Fetch latest release tag ---
function Get-LatestTag {
    try {
        $headers = @{ "Accept" = "application/vnd.github+json" }
        $release = Invoke-RestMethod -Uri $GitHubApi -Headers $headers -UseBasicParsing
        if (-not $release.tag_name) {
            Write-Err "Could not parse tag_name from GitHub API response."
        }
        return $release.tag_name
    }
    catch {
        Write-Err "Failed to fetch latest release from $GitHubApi. Check your internet connection. $_"
    }
}

# --- Download a file ---
function Invoke-Download {
    param(
        [string]$Url,
        [string]$Destination
    )
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
    }
    catch {
        Write-Err "Download failed: $Url`n$_"
    }
}

# --- Verify SHA-256 checksum ---
function Confirm-Checksum {
    param(
        [string]$BinaryPath,
        [string]$ChecksumFile
    )
    $binaryBasename = [System.IO.Path]::GetFileName($BinaryPath)

    $checksumContent = Get-Content $ChecksumFile -ErrorAction Stop
    $matchLine = $checksumContent | Where-Object { $_ -match [regex]::Escape($binaryBasename) }

    if (-not $matchLine) {
        Write-Err "No checksum entry found for '$binaryBasename' in $([System.IO.Path]::GetFileName($ChecksumFile))."
    }

    # Checksum files use format: <hash>  <filename>
    $expectedHash = ($matchLine -split '\s+')[0].ToUpper()

    $actualHash = (Get-FileHash -Path $BinaryPath -Algorithm SHA256).Hash.ToUpper()

    if ($actualHash -ne $expectedHash) {
        Write-Err "SHA-256 checksum mismatch for '$binaryBasename'.`n  Expected: $expectedHash`n  Actual:   $actualHash`nAborting installation."
    }

    Write-Info "Checksum verified."
}

# --- Update user PATH ---
function Add-ToUserPath {
    param([string]$Directory)
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")

    $paths = $currentPath -split ";" | Where-Object { $_ -ne "" }
    if ($paths -contains $Directory) {
        return $false
    }

    $newPath = ($paths + $Directory) -join ";"
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    return $true
}

# --- Main ---
function Invoke-Install {
    $TmpDir = $null
    try {
        Write-Info "Detecting architecture..."
        $arch = Get-Architecture
        Write-Info "Architecture: windows/$arch"

        Write-Info "Fetching latest release..."
        $tag = Get-LatestTag
        Write-Info "Latest release: $tag"

        # Asset naming follows the pattern: oh-my-braincrew_windows_amd64.exe
        $assetName  = "${BinaryName}_windows_${arch}.exe"
        $baseUrl    = "https://github.com/$Repo/releases/download/$tag"
        $binaryUrl  = "$baseUrl/$assetName"
        $checksumUrl = "$baseUrl/checksums-sha256.txt"

        $TmpDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $TmpDir | Out-Null

        $binaryPath   = [System.IO.Path]::Combine($TmpDir, $assetName)
        $checksumPath = [System.IO.Path]::Combine($TmpDir, "checksums-sha256.txt")

        Write-Info "Downloading binary..."
        Invoke-Download -Url $binaryUrl -Destination $binaryPath

        Write-Info "Downloading checksums..."
        Invoke-Download -Url $checksumUrl -Destination $checksumPath

        Write-Info "Verifying checksum..."
        Confirm-Checksum -BinaryPath $binaryPath -ChecksumFile $checksumPath

        Write-Info "Installing to $InstallDir..."
        if (-not (Test-Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir | Out-Null
        }

        $installPath = [System.IO.Path]::Combine($InstallDir, "$BinaryName.exe")
        Copy-Item -Path $binaryPath -Destination $installPath -Force

        Write-Info "Installation complete: $installPath"

        $pathUpdated = Add-ToUserPath -Directory $InstallDir
        if ($pathUpdated) {
            Write-Host ""
            Write-Host "PATH updated: '$InstallDir' added to your user PATH."
            Write-Host "Restart your terminal (or open a new PowerShell window) for the change to take effect."
            Write-Host ""
        }

        Write-Host ""
        Write-Host "==> Run '$BinaryName --version' to verify the installation."
        Write-Host ""
    }
    finally {
        if ($TmpDir -and (Test-Path $TmpDir)) {
            Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Invoke-Install
