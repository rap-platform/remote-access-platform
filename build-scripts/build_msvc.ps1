# ==============================================================================
# Remote Access Platform - MSVC 2022 Windows Build Script
# Uses the Qt Creator CMake toolchain and build directory
# ==============================================================================

param(
    [switch]$Rebuild
)

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\.."

# ── Load .env file if it exists ────────────────────────────────────────────────
$EnvFile = "$ProjectRoot\.env"
$EnvOverrides = @{}
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | Where-Object { $_ -match '^\s*([^#=]+)\s*=\s*"?([^"]*)"?' } | ForEach-Object {
        $EnvOverrides[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}

# ── Qt Creator toolchain paths ──────────────────────────────────────────────────
$QtCMake   = if ($EnvOverrides.ContainsKey('QT_CMAKE_PATH')) { $EnvOverrides['QT_CMAKE_PATH'] } else { "C:\Qt_my\Tools\CMake_64\bin\cmake.exe" }
$QtNinja   = if ($EnvOverrides.ContainsKey('QT_NINJA_PATH')) { $EnvOverrides['QT_NINJA_PATH'] } else { "C:\Qt_my\Tools\Ninja\ninja.exe" }

# ── Build directory matching Qt Creator Release output ───────────────────────────
$BuildDir  = "$ProjectRoot\build\Desktop_Qt_6_11_1_MSVC2022_64bit_Release"

# ── Auto-locate Qt 6 MSVC installation ────────────────────────────────────────
$QtMsvcPath = if ($EnvOverrides.ContainsKey('QT_MSVC_PATH')) { $EnvOverrides['QT_MSVC_PATH'].Replace('\', '/') } else { "" }
if (-not $QtMsvcPath) {
    $SearchPaths = @(
        "C:\Qt_my\6.*\msvc2022_64",
        "C:\Qt\6.*\msvc2022_64",
        "G:\Qt\6.*\msvc2022_64"
    )
    foreach ($Pattern in $SearchPaths) {
        $Found = Get-Item $Pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if ($Found) { $QtMsvcPath = $Found[0].FullName.Replace('\', '/'); break }
    }
}

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Remote Access Platform - MSVC 2022 Windows Build"            -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Project Root : $ProjectRoot"                                      -ForegroundColor Gray
Write-Host "Build Dir    : $BuildDir"                                         -ForegroundColor Gray
Write-Host "CMake        : $QtCMake"                                          -ForegroundColor Gray

# ── Validate cmake executable ──────────────────────────────────────────────────
if (-not (Test-Path $QtCMake)) {
    Write-Host "ERROR: CMake not found at: $QtCMake" -ForegroundColor Red
    Write-Host "   Set the correct path in .env file (QT_CMAKE_PATH)" -ForegroundColor Red
    exit 1
}

if ($QtMsvcPath) {
    Write-Host "Qt MSVC Kit  : $QtMsvcPath" -ForegroundColor Green
} else {
    Write-Host "WARNING: Qt MSVC path not found - set QT_MSVC_PATH in .env" -ForegroundColor Yellow
}

# ── Create build directory ─────────────────────────────────────────────────────
if ($Rebuild -and (Test-Path $BuildDir)) {
    Write-Host "`n--> Cleaning build directory for rebuild..." -ForegroundColor Yellow
    Remove-Item -Path $BuildDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# ── 1. CMake Configure ─────────────────────────────────────────────────────────
Write-Host "`n--> Configuring CMake (Release, Ninja, MSVC 2022)..." -ForegroundColor Yellow

$ConfigArgs = @(
    "-S", "$ProjectRoot",
    "-B", "$BuildDir",
    "-G", "Ninja",
    "-DCMAKE_BUILD_TYPE=Release"
)

if ($QtMsvcPath) {
    $ConfigArgs += "-DCMAKE_PREFIX_PATH=$QtMsvcPath"
}

$OpenSslPath = if ($EnvOverrides.ContainsKey('OPENSSL_ROOT_DIR')) { $EnvOverrides['OPENSSL_ROOT_DIR'] } else { "C:\vcpkg\installed\x64-windows" }
if ($OpenSslPath -and (Test-Path $OpenSslPath)) {
    $ConfigArgs += "-DOPENSSL_ROOT_DIR=$OpenSslPath"
}

# Locate vcvars64.bat for MSVC environment setup
$VcvarsSearch = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
)
$VcvarsPath = ""
foreach ($P in $VcvarsSearch) {
    if (Test-Path $P) { $VcvarsPath = $P; break }
}

if ($VcvarsPath) {
    Write-Host "Found MSVC Environment script: $VcvarsPath" -ForegroundColor Green
    & cmd.exe /c "`"$VcvarsPath`" && `"$QtCMake`" $($ConfigArgs -join ' ')"
} else {
    & $QtCMake @ConfigArgs
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CMake configuration failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# ── 2. CMake Build ─────────────────────────────────────────────────────────────
Write-Host "`n--> Compiling target binaries..." -ForegroundColor Yellow
if ($VcvarsPath) {
    & cmd.exe /c "`"$VcvarsPath`" && `"$QtCMake`" --build `"$BuildDir`" --config Release"
} else {
    & $QtCMake --build $BuildDir --config Release
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n===========================================================" -ForegroundColor Green
    Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "===========================================================" -ForegroundColor Green
} else {
    Write-Host "`nERROR: Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
