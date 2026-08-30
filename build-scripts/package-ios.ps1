# ==============================================================================
# Remote Access Platform - iOS Mobile Packaging Script (PowerShell)
# Builds Release iOS IPA Archives on macOS hosts (or notifies Windows hosts)
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\.."
$MobileDir   = "$ProjectRoot\apps\mobile"
$OutputDir   = "$ProjectRoot\dist\mobile\ios"

# Read version from VERSION file
$AppVersion = "0.3.0"
$VersionFile = "$ProjectRoot\VERSION"
if (Test-Path $VersionFile) {
    $Match = Get-Content $VersionFile | Where-Object { $_ -match '^\s*AppVersion\s*=\s*(.*)' }
    if ($Match) { $AppVersion = $Matches[1].Trim() }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "📱 Remote Access Platform — iOS Mobile Build Pipeline"             -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Target Version : $AppVersion" -ForegroundColor Gray
Write-Host "Mobile Folder  : $MobileDir"  -ForegroundColor Gray
Write-Host "Output Folder  : $OutputDir"  -ForegroundColor Gray

# Check host OS platform
$IsMacOS = $IsMacOS -or ($PSVersionTable.OS -like "*Darwin*")
if (-not $IsMacOS) {
    Write-Host "`n[!] NOTICE: iOS IPA compilation requires macOS with Xcode installed." -ForegroundColor Yellow
    Write-Host "    - Windows hosts can compile Android APKs/AABs via package-android.ps1" -ForegroundColor Yellow
    Write-Host "    - To build iOS IPAs, run package-ios.sh or package-ios.ps1 on a macOS host." -ForegroundColor Yellow
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

# Locate Flutter executable
$FlutterCmd = if ($EnvOverrides.ContainsKey('FLUTTER_ROOT')) { "$($EnvOverrides['FLUTTER_ROOT'])/bin/flutter" } else { "flutter" }
try {
    Get-Command $FlutterCmd -ErrorAction Stop | Out-Null
    Write-Host "Using Flutter SDK: $FlutterCmd" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter SDK not found. Set FLUTTER_ROOT in .env or add flutter to PATH." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
Set-Location $MobileDir

# 1. Resolve dependencies
Write-Host "`n--> Resolving Flutter and CocoaPods workspace dependencies..." -ForegroundColor Yellow
& $FlutterCmd pub get

if (Test-Path "ios") {
    Set-Location "ios"
    if (Get-Command "pod" -ErrorAction SilentlyContinue) {
        & pod install
    }
    Set-Location $MobileDir
}

# 2. Check for ExportOptions.plist
$ExportPlist = "$MobileDir/ios/ExportOptions.plist"
if (-not (Test-Path $ExportPlist)) {
    $ExportPlist = "$MobileDir/ios/ExportOptions.plist.example"
}

# 3. Compile iOS IPA Archive
Write-Host "`n--> Compiling iOS Release IPA Archive..." -ForegroundColor Yellow
if (Test-Path $ExportPlist) {
    & $FlutterCmd build ipa --release --export-options-plist=$ExportPlist
} else {
    & $FlutterCmd build ipa --release
}

# 4. Stage output artifacts
$BuildIpaDir = "$MobileDir/build/ios/ipa"
if (Test-Path $BuildIpaDir) {
    Get-ChildItem -Path $BuildIpaDir -Filter "*.ipa" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination "$OutputDir/RemoteAccessPlatform-$AppVersion.ipa" -Force
    }
    Write-Host "`nSUCCESS: iOS IPA generated at $OutputDir/RemoteAccessPlatform-$AppVersion.ipa" -ForegroundColor Green
} else {
    Write-Host "`nNOTICE: iOS build completed; archive staged at $MobileDir/build/ios/archive" -ForegroundColor Yellow
}

# 5. Generate Checksums
Write-Host "`n--> Generating SHA-256 integrity checksums..." -ForegroundColor Yellow
$ChecksumFile = "$ProjectRoot/dist/mobile/checksums.txt"
New-Item -ItemType Directory -Force -Path "$ProjectRoot/dist/mobile" | Out-Null

$ChecksumLines = @(
    "Remote Access Platform Mobile V$AppVersion Release Integrity Checksums",
    "Date: $(Get-Date)",
    "========================================================================="
)

Get-ChildItem -Path $OutputDir -File | ForEach-Object {
    $Hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
    $ChecksumLines += "$($_.Name): $Hash"
}

$ChecksumLines | Out-File -FilePath $ChecksumFile -Encoding utf8

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "iOS PACKAGING COMPLETE!" -ForegroundColor Green
Write-Host "Output Directory : $OutputDir" -ForegroundColor Green
Write-Host "Checksums File   : $ChecksumFile" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
