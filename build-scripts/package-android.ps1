# ==============================================================================
# Remote Access Platform - Android Mobile Packaging Script (PowerShell)
# Builds Release APKs and Google Play Store App Bundle (AAB) on Windows hosts
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\.."
$MobileDir   = "$ProjectRoot\apps\mobile"
$OutputDir   = "$ProjectRoot\dist\mobile\android"

# Read version from VERSION file
$AppVersion = "0.3.0"
$VersionFile = "$ProjectRoot\VERSION"
if (Test-Path $VersionFile) {
    $Match = Get-Content $VersionFile | Where-Object { $_ -match '^\s*AppVersion\s*=\s*(.*)' }
    if ($Match) { $AppVersion = $Matches[1].Trim() }
}

$PubspecFile = "$MobileDir\pubspec.yaml"
if (Test-Path $PubspecFile) {
    (Get-Content $PubspecFile) -replace '^\s*version:\s*.*', "version: $AppVersion+1" | Set-Content $PubspecFile
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "📱 Remote Access Platform — Android Mobile Build Pipeline"            -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Target Version : $AppVersion" -ForegroundColor Gray
Write-Host "Mobile Folder  : $MobileDir"  -ForegroundColor Gray
Write-Host "Output Folder  : $OutputDir"  -ForegroundColor Gray

# Load .env file overrides
$EnvFile = "$ProjectRoot\.env"
$EnvOverrides = @{}
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | Where-Object { $_ -match '^\s*([^#=]+)\s*=\s*"?([^"]*)"?' } | ForEach-Object {
        $EnvOverrides[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}

# Locate Flutter
$FlutterCmd = if ($EnvOverrides.ContainsKey('FLUTTER_ROOT')) { "$($EnvOverrides['FLUTTER_ROOT'])\bin\flutter.bat" } else { "flutter" }
try {
    Get-Command $FlutterCmd -ErrorAction Stop | Out-Null
    Write-Host "Using Flutter SDK: $FlutterCmd" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter SDK not found. Set FLUTTER_ROOT in .env or add flutter to PATH." -ForegroundColor Red
    exit 1
}

# 1. Prepare JNI directories
Write-Host "`n--> Staging JNI Native Libraries..." -ForegroundColor Yellow
foreach ($Abi in @("arm64-v8a", "armeabi-v7a", "x86_64")) {
    $JniDir = "$MobileDir\android\app\src\main\jniLibs\$Abi"
    New-Item -ItemType Directory -Force -Path $JniDir | Out-Null
    
    $NativeLib = "$ProjectRoot\build\libs\common\librap_common.dll"
    if (Test-Path $NativeLib) {
        Copy-Item -Path $NativeLib -Destination "$JniDir\librap_common.so" -Force
    }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Set-Location $MobileDir

# 2. Resolve Flutter packages
Write-Host "`n--> Resolving Flutter workspace dependencies..." -ForegroundColor Yellow
& $FlutterCmd pub get

# 3. Build Universal APK
Write-Host "`n--> Compiling Universal Release APK..." -ForegroundColor Yellow
& $FlutterCmd build apk --release

# 4. Build Split APKs
Write-Host "`n--> Compiling Per-ABI Split APKs..." -ForegroundColor Yellow
& $FlutterCmd build apk --split-per-abi --release

# 5. Build App Bundle (AAB)
Write-Host "`n--> Compiling Google Play App Bundle (AAB)..." -ForegroundColor Yellow
& $FlutterCmd build appbundle --release

# 6. Copy output artifacts to dist/mobile/android
Write-Host "`n--> Copying release artifacts..." -ForegroundColor Yellow
$BuildApkDir    = "$MobileDir\build\app\outputs\flutter-apk"
$BuildBundleDir = "$MobileDir\build\app\outputs\bundle\release"

if (Test-Path "$BuildApkDir\app-release.apk") {
    Copy-Item -Path "$BuildApkDir\app-release.apk" -Destination "$OutputDir\RemoteAccessPlatform-$AppVersion.apk" -Force
}

if (Test-Path "$BuildApkDir\app-arm64-v8a-release.apk") {
    Copy-Item -Path "$BuildApkDir\app-arm64-v8a-release.apk" -Destination "$OutputDir\RemoteAccessPlatform-$AppVersion-arm64-v8a.apk" -Force
}

if (Test-Path "$BuildBundleDir\app-release.aab") {
    Copy-Item -Path "$BuildBundleDir\app-release.aab" -Destination "$OutputDir\RemoteAccessPlatform-$AppVersion.aab" -Force
}

# 7. Generate Checksums
Write-Host "`n--> Generating SHA-256 integrity checksums..." -ForegroundColor Yellow
$ChecksumFile = "$ProjectRoot\dist\mobile\checksums.txt"
New-Item -ItemType Directory -Force -Path "$ProjectRoot\dist\mobile" | Out-Null

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
Write-Host "ANDROID PACKAGING COMPLETE!" -ForegroundColor Green
Write-Host "Output Directory : $OutputDir" -ForegroundColor Green
Write-Host "Checksums File   : $ChecksumFile" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
