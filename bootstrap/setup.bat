@echo off
setlocal enabledelayedexpansion

REM Bootstrap Setup Script for Windows
REM This script helps with the initial setup of the bootstrap module

echo 🚀 Bootstrap Module Setup
echo =========================

REM Check if we're in the bootstrap directory
if not exist "main.tf" (
    echo ❌ Error: Please run this script from the bootstrap directory
    exit /b 1
)

REM Check if backend.tf exists
if exist "backend.tf" (
    echo 📋 Backend configuration found in backend.tf
    echo ⚠️  Note: For initial setup, you may need to temporarily comment out the backend configuration
    echo    in backend.tf if the storage infrastructure doesn't exist yet.
    echo.
)

echo 🔧 Initializing Terraform...
terraform init

echo 📋 Planning deployment...
terraform plan

echo.
set /p response="❓ Do you want to apply the changes? (y/N): "

if /i "%response%"=="y" (
    echo 🚀 Applying changes...
    terraform apply
    echo.
    echo ✅ Bootstrap module deployed successfully!
    echo.
    echo 📝 Next steps:
    echo 1. If you commented out the backend configuration, uncomment it now
    echo 2. Run 'terraform init -migrate-state' to move state to Azure Storage
    echo 3. You can now deploy from anywhere using the Azure Storage backend
) else (
    echo ❌ Deployment cancelled
)

pause 