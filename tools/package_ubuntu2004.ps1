# Ubuntu 20.04 LTS Automated Container Builder & Packager Script for Windows (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "================================================================="
Write-Host "   REMOTE ACCESS PLATFORM - UBUNTU 20.04 RELEASE BUILDER (WIN)  "
Write-Host "================================================================="

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = (Get-Item "$ScriptDir\..").FullName
$ImageName = "rap-ubuntu2004-builder:latest"

# Step 1: Check if cached build image exists, otherwise build it once
$imageCheck = docker image inspect $ImageName 2>$null
if (-not $imageCheck) {
    Write-Host "[+] Creating cached Ubuntu 20.04 build image ($ImageName)... (One-time setup)"
    docker build -t $ImageName -f "$ScriptDir\Dockerfile.ubuntu2004" "$ScriptDir"
} else {
    Write-Host "[+] Found cached build image ($ImageName). Skipping dependency installation!"
}

# Step 2: Run compilation in Docker container (normalizing line endings if repository was cloned on Windows)
Write-Host "[+] Executing compilation & packaging in container..."
docker run --rm -v "${RootDir}:/workspace" -w /workspace $ImageName bash -c "sed -i 's/\r$//' tools/*.sh && bash ./tools/package.sh"

Write-Host "================================================================="
Write-Host " 🎉 UBUNTU 20.04 RELEASE PACKAGE READY AT:"
Write-Host "    $RootDir\dist\rap-v1.0.0-linux-x86_64.tar.gz"
Write-Host "================================================================="
