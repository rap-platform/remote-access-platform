# ==============================================================================
# Remote Access Platform - macOS Desktop Packaging Script (PowerShell)
# Bundles rap-client.app & builds .dmg image via macdeployqt on macOS hosts
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\.."
$BuildDir    = "$ProjectRoot\build_macos"
$OutputDir   = "$ProjectRoot\dist\desktop\macos"

# Read version from VERSION file
$AppVersion = "0.3.0"
$VersionFile = "$ProjectRoot\VERSION"
if (Test-Path $VersionFile) {
    $Match = Get-Content $VersionFile | Where-Object { $_ -match '^\s*AppVersion\s*=\s*(.*)' }
    if ($Match) { $AppVersion = $Matches[1].Trim() }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "🖥️ Remote Access Platform — macOS Desktop Packaging Pipeline"       -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Target Version : $AppVersion"  -ForegroundColor Gray
Write-Host "Project Root   : $ProjectRoot" -ForegroundColor Gray
Write-Host "Output Folder  : $OutputDir"  -ForegroundColor Gray

# Check host OS platform
$IsMacOS = $IsMacOS -or ($PSVersionTable.OS -like "*Darwin*")
if (-not $IsMacOS) {
    Write-Host "`n[!] NOTICE: macOS Desktop packaging (.dmg / .app) requires a macOS host with Xcode & Qt 6." -ForegroundColor Yellow
    Write-Host "    - Windows hosts can compile Windows installers via build_and_package.bat" -ForegroundColor Yellow
    Write-Host "    - To build macOS DMG packages, run package-macos.sh or package-macos.ps1 on macOS." -ForegroundColor Yellow
    Write-Host "=================================================================" -ForegroundColor Gray
    exit 0
}

# Load .env file overrides if present
$EnvFile = "$ProjectRoot\.env"
$EnvOverrides = @{}
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | Where-Object { $_ -match '^\s*([^#=]+)\s*=\s*"?([^"]*)"?' } | ForEach-Object {
        $EnvOverrides[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}

# Locate CMake & macdeployqt
$CMakeCmd = if ($EnvOverrides.ContainsKey('MACOS_CMAKE_PATH')) { $EnvOverrides['MACOS_CMAKE_PATH'] } else { "cmake" }
$QtMacPath = if ($EnvOverrides.ContainsKey('QT_MACOS_PATH')) { $EnvOverrides['QT_MACOS_PATH'] } else { "" }

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# 1. CMake Configure & Build
Write-Host "`n--> Configuring & building macOS release binaries..." -ForegroundColor Yellow
if ($QtMacPath) {
    & $CMakeCmd -S $ProjectRoot -B $BuildDir -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=$QtMacPath
} else {
    & $CMakeCmd -S $ProjectRoot -B $BuildDir -DCMAKE_BUILD_TYPE=Release
}
& $CMakeCmd --build $BuildDir --config Release

# 2. Stage .app bundle & run macdeployqt
$AppBundle = "$BuildDir/apps/client/rap-client.app"
if (Test-Path $AppBundle) {
    if (Test-Path "$BuildDir/apps/agent/rap-agent") {
        Copy-Item -Path "$BuildDir/apps/agent/rap-agent" -Destination "$AppBundle/Contents/MacOS/" -Force
    }

    $MacDeployQt = if ($QtMacPath) { "$QtMacPath/bin/macdeployqt" } else { "macdeployqt" }
    if (Get-Command $MacDeployQt -ErrorAction SilentlyContinue) {
        Write-Host "`n--> Running macdeployqt to create standalone DMG..." -ForegroundColor Yellow
        & $MacDeployQt $AppBundle -qmldir="$ProjectRoot/apps/client/qml" -dmg
        
        Get-ChildItem -Path "$BuildDir/apps/client" -Filter "*.dmg" | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination "$OutputDir/RemoteAccessPlatform-$AppVersion.dmg" -Force
        }
    }
}

# 3. Checksums
Write-Host "`n--> Generating SHA-256 integrity checksums..." -ForegroundColor Yellow
$ChecksumFile = "$OutputDir/checksums.txt"
$ChecksumLines = @(
    "Remote Access Platform macOS Desktop V$AppVersion Release Integrity Checksums",
    "Date: $(Get-Date)",
    "========================================================================="
)

Get-ChildItem -Path $OutputDir -File | Where-Object { $_.Name -ne "checksums.txt" } | ForEach-Object {
    $Hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
    $ChecksumLines += "$($_.Name): $Hash"
}

$ChecksumLines | Out-File -FilePath $ChecksumFile -Encoding utf8

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "macOS DESKTOP PACKAGING COMPLETE!" -ForegroundColor Green
Write-Host "Output Directory: $OutputDir" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
