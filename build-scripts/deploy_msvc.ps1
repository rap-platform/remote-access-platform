# ==============================================================================
# Remote Access Platform - MSVC Deploy & Packaging Script
# Reuses Qt Creator build output for standalone Windows distribution
# ==============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\.."

# ── Build dir and target deploy dir ───────────────────────────────────────────
$BuildDir  = "$ProjectRoot\build\Desktop_Qt_6_11_1_MSVC2022_64bit_Release"
$DeployDir = "$ProjectRoot\deploy_windows"

# ── Load .env file if it exists ────────────────────────────────────────────────
$EnvFile = "$ProjectRoot\.env"
$EnvOverrides = @{}
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | Where-Object { $_ -match '^\s*([^#=]+)\s*=\s*"?([^"]*)"?' } | ForEach-Object {
        $EnvOverrides[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}

# ── Auto-locate Qt 6 MSVC installation ────────────────────────────────────────
$QtMsvcPath = if ($EnvOverrides.ContainsKey('QT_MSVC_PATH')) { $EnvOverrides['QT_MSVC_PATH'] } else { "" }
if (-not $QtMsvcPath) {
    $SearchPaths = @(
        "C:\Qt_my\6.*\msvc2022_64",
        "C:\Qt\6.*\msvc2022_64",
        "G:\Qt\6.*\msvc2022_64"
    )
    foreach ($Pattern in $SearchPaths) {
        $Found = Get-Item $Pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if ($Found) { $QtMsvcPath = $Found[0].FullName; break }
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "📡 Remote Access Platform - Packaging Standalone Windows Release"   -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Build Dir    : $BuildDir"  -ForegroundColor Gray
Write-Host "Deploy Dir   : $DeployDir" -ForegroundColor Gray

# ── 1. Build if not already built ─────────────────────────────────────────────
$ClientExe = "$BuildDir\apps\client\rap-client.exe"
if (-not (Test-Path $ClientExe)) {
    Write-Host "`n--> Compiled binaries not found. Running build_msvc.ps1 first..." -ForegroundColor Yellow
    & "$ScriptDir\build_msvc.ps1"
}

if (-not (Test-Path $ClientExe)) {
    Write-Host "❌ Build output not found at $ClientExe even after build attempt. Aborting." -ForegroundColor Red
    exit 1
}

# ── 2. Setup deploy directory ─────────────────────────────────────────────────
if (Test-Path $DeployDir) { Remove-Item -Recurse -Force $DeployDir }

foreach ($SubDir in @("bin", "qml")) {
    New-Item -ItemType Directory -Force -Path "$DeployDir\$SubDir" | Out-Null
}

# ── 3. Copy executables & DLL dependencies ────────────────────────────────────
Write-Host "`n--> Copying compiled client and host agent binaries..." -ForegroundColor Yellow

Get-ChildItem -Path "$BuildDir" -Filter "*.exe" -Recurse -File |
    Copy-Item -Destination "$DeployDir\bin" -Force

Get-ChildItem -Path "$BuildDir" -Filter "*.dll" -Recurse -File |
    Copy-Item -Destination "$DeployDir\bin" -Force

# ── 4. Copy QML interface assets ──────────────────────────────────────────────
Write-Host "--> Copying QML interface assets..." -ForegroundColor Yellow
if (Test-Path "$ProjectRoot\apps\client\qml") {
    Copy-Item -Recurse -Force "$ProjectRoot\apps\client\qml\*" "$DeployDir\qml\"
}

# ── 5. windeployqt ────────────────────────────────────────────────────────────
if ($QtMsvcPath -and (Test-Path "$QtMsvcPath\bin\windeployqt.exe")) {
    Write-Host "--> Running windeployqt for standalone Qt runtime..." -ForegroundColor Yellow
    $TargetExe = "$DeployDir\bin\rap-client.exe"
    if (Test-Path $TargetExe) {
        & "$QtMsvcPath\bin\windeployqt.exe" `
            --no-compiler-runtime `
            --qmldir "$ProjectRoot\apps\client\qml" `
            --dir "$DeployDir\bin" `
            --release `
            "$TargetExe"
    } else {
        Write-Host "WARNING: target rap-client.exe not found in deploy directory." -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: windeployqt.exe not found at $QtMsvcPath\bin. Qt runtime DLLs must be added manually." -ForegroundColor Yellow
}

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "DEPLOYMENT STAGING COMPLETE!" -ForegroundColor Green
Write-Host "Output Directory: $DeployDir" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
