@echo off
setlocal enabledelayedexpansion

REM =========================================================================
REM             Remote Access Platform Master Build & Package Script
REM             Stages binaries into rap-client-build for Inno Setup
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
echo [1/5] Executing MSVC Build Pipeline...
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

REM ==== 2. STAGE COMPILED ARTIFACTS TO rap-client-build ====
echo [2/5] Staging files to local rap-client-build folder...
set "STAGE_DIR=%ROOT_DIR%rap-client-build"
set "BUILD_DIR=%PROJECT_ROOT%build\Desktop_Qt_6_11_1_MSVC2022_64bit_Release"
set "QT_MSVC_PATH=C:\Qt_my\6.11.1\msvc2022_64"

REM Load .env file overrides
set "ENV_FILE=%PROJECT_ROOT%.env"
if exist "%ENV_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        set "KEY=%%A"
        set "VAL=%%~B"
        if "!KEY!"=="BUILD_DIR" set "BUILD_DIR=!VAL!"
        if "!KEY!"=="BUILD_BIN_DIR" set "BUILD_DIR=!VAL!"
        if "!KEY!"=="QT_MSVC_PATH" set "QT_MSVC_PATH=!VAL!"
    )
)

REM Strip surrounding quotes from paths
set "BUILD_DIR=%BUILD_DIR:"=%"
set "QT_MSVC_PATH=%QT_MSVC_PATH:"=%"
set "STAGE_DIR=%STAGE_DIR:"=%"

if exist "%STAGE_DIR%" (
    echo Cleaning existing staging folder "%STAGE_DIR%"...
    rd /s /q "%STAGE_DIR%"
)
mkdir "%STAGE_DIR%"
mkdir "%STAGE_DIR%\qml"

echo Copying Release binaries and DLL dependencies...
set "CLIENT_EXE_FOUND=0"
if exist "%BUILD_DIR%\apps\client\rap-client.exe" (
    copy /Y "%BUILD_DIR%\apps\client\rap-client.exe" "%STAGE_DIR%\" >nul
    set "CLIENT_EXE_FOUND=1"
) else if exist "%BUILD_DIR%\rap-client.exe" (
    copy /Y "%BUILD_DIR%\rap-client.exe" "%STAGE_DIR%\" >nul
    set "CLIENT_EXE_FOUND=1"
) else if exist "%BUILD_DIR%\bin\rap-client.exe" (
    copy /Y "%BUILD_DIR%\bin\rap-client.exe" "%STAGE_DIR%\" >nul
    set "CLIENT_EXE_FOUND=1"
)

if exist "%BUILD_DIR%\apps\agent\rap-agent.exe" (
    copy /Y "%BUILD_DIR%\apps\agent\rap-agent.exe" "%STAGE_DIR%\" >nul
) else if exist "%BUILD_DIR%\rap-agent.exe" (
    copy /Y "%BUILD_DIR%\rap-agent.exe" "%STAGE_DIR%\" >nul
) else if exist "%BUILD_DIR%\bin\rap-agent.exe" (
    copy /Y "%BUILD_DIR%\bin\rap-agent.exe" "%STAGE_DIR%\" >nul
)

xcopy /Y /S /E "%BUILD_DIR%\*.dll" "%STAGE_DIR%\" >nul 2>&1

echo Copying QML assets...
xcopy /Y /S /E "%PROJECT_ROOT%apps\client\qml\*" "%STAGE_DIR%\qml\" >nul 2>&1

if "%CLIENT_EXE_FOUND%"=="0" (
    echo ERROR: Could not find rap-client.exe in %BUILD_DIR%!
    goto FAIL
)

REM ==== 3. RUN WINDEPLOYQT ON STAGED BINARY ====
echo [3/5] Running windeployqt on staged rap-client.exe...
set "WINDEPLOYQT=%QT_MSVC_PATH%\bin\windeployqt.exe"
if exist "%WINDEPLOYQT%" (
    "%WINDEPLOYQT%" --no-compiler-runtime --qmldir "%PROJECT_ROOT%apps\client\qml" --dir "%STAGE_DIR%" --release "%STAGE_DIR%\rap-client.exe"
) else (
    echo WARNING: windeployqt.exe not found at %WINDEPLOYQT%.
)
echo Staging complete.
echo.

REM ==== 4. RUN INSTALLER COMPILER ====
echo [4/5] Building Windows Installer via Inno Setup...
call "%ROOT_DIR%build_installers.bat" "%APP_VERSION%"
if errorlevel 1 (
    echo ERROR: build_installers.bat failed.
    goto FAIL
)
echo.

REM ==== 5. GENERATE CHECKSUMS AND ZIP ARCHIVE ====
echo [5/5] Generating Integrity Checksums ^& Archiving Release Bundle...
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
echo    Staged Folder  : %STAGE_DIR%
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
