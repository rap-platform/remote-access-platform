@echo off
setlocal

REM ==== CONFIGURATION ====
REM Default Inno Setup Compiler path (short path format for Program Files (x86))
set "ISCC_PATH=C:\Progra~2\Inno Setup 6\ISCC.exe"
if not exist "%ISCC_PATH%" set "ISCC_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

REM Script directory location
set "ROOT_DIR=%~dp0"
set "PROJECT_ROOT=%ROOT_DIR%..\..\"

REM Load .env file overrides if available
set "ENV_FILE=%PROJECT_ROOT%.env"
if exist "%ENV_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        if "%%A"=="ISCC_PATH" set "ISCC_PATH=%%~B"
    )
)

REM Read version from centralized VERSION file
set "APP_VERSION="
if exist "%PROJECT_ROOT%VERSION" (
    for /f "usebackq tokens=1,2 delims==" %%i in ("%PROJECT_ROOT%VERSION") do (
        if "%%i"=="AppVersion" set "APP_VERSION=%%j"
    )
)
if "%APP_VERSION%"=="" set "APP_VERSION=0.3.0"
if not "%~1"=="" set "APP_VERSION=%~1"

REM Inno setup installer paths
set "RAP_ISS=%ROOT_DIR%rap-client\RemoteAccessPlatform.iss"
set "RAP_OUT=%ROOT_DIR%rap-client\Output"

echo.
echo ==========================================
echo    Remote Access Platform Installer Build  
echo    Version: %APP_VERSION%
echo ==========================================
echo.

REM ==== VALIDATE ISCC ====
if not exist "%ISCC_PATH%" goto ISCC_ERROR

REM ==== VALIDATE ISS FILE ====
if not exist "%RAP_ISS%" goto ISS_ERROR

REM ==== STAGE DEPLOYMENT IF NEEDED ====
if not exist "%ROOT_DIR%rap-client-build\rap-client.exe" (
    echo WARNING: Staging directory rap-client-build\rap-client.exe not found!
    echo Please run build_and_package.bat to build and stage the binaries first.
)

REM ==== BUILD INSTALLER ====
echo Building Remote Access Platform Windows installer...
"%ISCC_PATH%" /DMyAppVersion="%APP_VERSION%" "%RAP_ISS%"
if errorlevel 1 goto BUILD_FAIL

echo SUCCESS: Remote Access Platform installer built.
echo Output: %RAP_OUT%
echo.

REM ==== FINAL SUCCESS ====
echo ==========================================
echo    INSTALLER BUILT SUCCESSFULLY
echo ==========================================
echo.

REM ==== LIST OUTPUT FILES ====
if exist "%RAP_OUT%" dir "%RAP_OUT%"

echo.
goto END

REM ==== ERROR HANDLERS ====

:ISCC_ERROR
echo ERROR: Inno Setup compiler not found at:
echo %ISCC_PATH%
goto FAIL

:ISS_ERROR
echo ERROR: Inno Setup script (.iss) not found:
echo %RAP_ISS%
goto FAIL

:BUILD_FAIL
echo.
echo ERROR: Installer build FAILED
goto FAIL

:FAIL
echo.
echo ==========================================
echo     BUILD FAILED
echo ==========================================
echo.
exit /b 1

:END
endlocal
exit /b 0
