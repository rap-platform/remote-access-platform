@echo off
setlocal enabledelayedexpansion

REM =========================================================================
REM             Remote Access Platform Master Build & Package Script
REM             Delegates CMake and Compilation to build_msvc.ps1
REM =========================================================================

set "ROOT_DIR=%~dp0"
set "PROJECT_ROOT=%ROOT_DIR%..\..\"
set "APP_VERSION="

if exist "%PROJECT_ROOT%VERSION" (
    for /f "usebackq tokens=1,2 delims==" %%i in ("%PROJECT_ROOT%VERSION") do (
        if "%%i"=="AppVersion" set "APP_VERSION=%%j"
    )
)
if "%APP_VERSION%"=="" set "APP_VERSION=0.3.0"
if not "%~1"=="" set "APP_VERSION=%~1"

echo.
echo =========================================================================
echo    STARTING REMOTE ACCESS PLATFORM AUTOMATED BUILD PIPELINE
echo    Target Version: %APP_VERSION%
echo =========================================================================
echo.

REM ==== 1. BUILD PROJECT USING POWERSHELL SCRIPT ====
echo [1/4] Executing MSVC Build Pipeline...
choice /C RBS /M "Do you want to [R]ebuild, [B]uild, or [S]kip build?"
if errorlevel 3 (
    echo Skipping build step...
) else if errorlevel 2 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%PROJECT_ROOT%build-scripts\build_msvc.ps1'"
    if errorlevel 1 (
        echo ERROR: build_msvc.ps1 failed.
        goto FAIL
    )
) else if errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%PROJECT_ROOT%build-scripts\build_msvc.ps1' -Rebuild"
    if errorlevel 1 (
        echo ERROR: build_msvc.ps1 failed.
        goto FAIL
    )
)
echo.

REM ==== 2. STAGE & DEPLOY BINARIES & QT RUNTIME ====
echo [2/4] Executing Qt Deployment and Staging Pipeline...
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%PROJECT_ROOT%build-scripts\deploy_msvc.ps1'"
if errorlevel 1 (
    echo ERROR: deploy_msvc.ps1 failed.
    goto FAIL
)
echo.

REM ==== 3. RUN INSTALLER COMPILER ====
echo [3/4] Building Windows Installer via Inno Setup...
call "%ROOT_DIR%build_installers.bat" "%APP_VERSION%"
if errorlevel 1 (
    echo ERROR: build_installers.bat failed.
    goto FAIL
)
echo.

REM ==== 4. GENERATE CHECKSUMS AND ZIP ARCHIVE ====
echo [4/4] Generating Integrity Checksums ^& Archiving Release Bundle...
set "RAP_OUT=%ROOT_DIR%rap-client\Output\version-%APP_VERSION%"
set "SETUP_EXE=%RAP_OUT%\RemoteAccessPlatform-Setup-V%APP_VERSION%.exe"
set "ZIP_OUT=%ROOT_DIR%rap-client\Output\version-%APP_VERSION%.zip"

if exist "%SETUP_EXE%" (
    echo Generating Integrity Checksums...
    for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%SETUP_EXE%" SHA256 ^| findstr /v "CertUtil"') do (
        set "SHA256_HASH=%%H"
        set "SHA256_HASH=!SHA256_HASH: =!"
    )
    echo !SHA256_HASH! *RemoteAccessPlatform-Setup-V%APP_VERSION%.exe> "%RAP_OUT%\RemoteAccessPlatform-Setup-V%APP_VERSION%.exe.sha256"

    for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%SETUP_EXE%" MD5 ^| findstr /v "CertUtil"') do (
        set "MD5_HASH=%%H"
        set "MD5_HASH=!MD5_HASH: =!"
    )
    echo !MD5_HASH! *RemoteAccessPlatform-Setup-V%APP_VERSION%.exe> "%RAP_OUT%\RemoteAccessPlatform-Setup-V%APP_VERSION%.exe.md5"

    (
    echo Remote Access Platform V%APP_VERSION% Release Integrity Checksums
    echo Date: %DATE% %TIME%
    echo =========================================================================
    echo File: RemoteAccessPlatform-Setup-V%APP_VERSION%.exe
    echo SHA-256: !SHA256_HASH!
    echo MD5:    !MD5_HASH!
    ) > "%RAP_OUT%\checksums.txt"
    echo Integrity checksum files written successfully.

    echo Zipping version-%APP_VERSION% output directory...
    if exist "%ZIP_OUT%" del /f /q "%ZIP_OUT%"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%RAP_OUT%\*' -DestinationPath '%ZIP_OUT%' -Force"
    echo Zip archive created at: %ZIP_OUT%
) else (
    echo WARNING: Setup executable not found, skipping checksums and zip archive.
)
echo.

echo =========================================================================
echo    SUCCESS: REMOTE ACCESS PLATFORM PACKAGING PIPELINE COMPLETE
echo =========================================================================
echo Output Artifacts:
echo    Installer Setup: %RAP_OUT%\RemoteAccessPlatform-Setup-V%APP_VERSION%.exe
echo    Integrity Files: %RAP_OUT%\checksums.txt
echo    Zip Archive    : %ZIP_OUT%
echo =========================================================================
echo.
goto END

:FAIL
echo.
echo =========================================================================
echo    ERROR: PIPELINE BUILD FAILED
echo =========================================================================
echo.
exit /b 1

:END
endlocal
exit /b 0
