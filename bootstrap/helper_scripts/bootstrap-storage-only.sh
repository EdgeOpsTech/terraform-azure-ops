#!/bin/bash

# Bootstrap Storage Only - Skip Azure AD setup
echo "🚀 Bootstrap Storage Infrastructure"
echo "=================================="

# Check if we're logged in
if ! az account show &>/dev/null; then
    echo "❌ Not logged into Azure. Please run 'az login' first."
    exit 1
fi

# Set environment variables for existing app
export ARM_USE_OIDC=true
export ARM_CLIENT_ID="80fe8753-50ba-4d1e-84e7-bc9711ef7429"
export ARM_TENANT_ID="78b776c8-c1c5-4f5b-b46e-4dcd278720b5"
export ARM_SUBSCRIPTION_ID="bba7ddf1-057e-4d04-afd9-4032cd79dc9d"
echo "✅ Environment variables set"

# Clean Terraform state to remove Azure AD resources (we'll skip them)
echo "🧹 Cleaning federated credential resources from state..."
terraform init

# Remove all federated credential resources from state  
terraform state list | grep "azuread_application_federated_identity_credential" | while read -r resource; do
    echo "Removing from state: $resource"
    terraform state rm "$resource" 2>/dev/null || true
done

# Remove Azure AD app and SP from state (we'll use existing ones)
terraform state rm "azuread_application.github_oidc" 2>/dev/null || true
terraform state rm "azuread_service_principal.github_oidc" 2>/dev/null || true

echo "✅ State cleaned"

# Create only storage infrastructure
echo "🚀 Creating storage infrastructure..."

# Create just the resource group and storage account manually
echo "📦 Creating resource group..."
az group create --name "rg-tfstate" --location "eastus" || true

echo "📦 Creating storage account..." 
az storage account create \
    --name "edgeopstechtfstate" \
    --resource-group "rg-tfstate" \
    --location "eastus" \
    --sku "Standard_GRS" \
    --kind "StorageV2" \
    --allow-blob-public-access false || true

echo "📦 Creating storage containers..."
REPOS=("terraform-azure-ops" "super-webapp" "azure-vm-setup" "kv-rbac-setup" "edgeops-sub-mgmt" "edgeops-keyvault-module")

for repo in "${REPOS[@]}"; do
    echo "Creating container: $repo"
    az storage container create \
        --name "$repo" \
        --account-name "edgeopstechtfstate" \
        --auth-mode login || true
done

# Create main container
az storage container create \
    --name "tf-state-submgmt-np-main" \
    --account-name "edgeopstechtfstate" \
    --auth-mode login || true

# Get service principal ID and assign roles
SP_ID="3d2f9979-65ef-40a2-80ee-f128bf5bf47c"
STORAGE_ACCOUNT_ID="/subscriptions/bba7ddf1-057e-4d04-afd9-4032cd79dc9d/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/edgeopstechtfstate"

echo "🔐 Assigning roles..."
az role assignment create \
    --assignee "$SP_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "$STORAGE_ACCOUNT_ID" || true

az role assignment create \
    --assignee "$SP_ID" \
    --role "Contributor" \
    --subscription "bba7ddf1-057e-4d04-afd9-4032cd79dc9d" || true

az role assignment create \
    --assignee "$SP_ID" \
    --role "User Access Administrator" \
    --subscription "bba7ddf1-057e-4d04-afd9-4032cd79dc9d" || true

echo ""
echo "🎉 Storage infrastructure created successfully!"
echo ""
echo "📋 What was created:"
echo "- Resource group: rg-tfstate"
echo "- Storage account: edgeopstechtfstate"
echo "- Storage containers for all repositories"  
echo "- Role assignments for service principal"
echo ""
echo "✅ Your existing Azure AD application is ready to use!"
echo "   Client ID: 80fe8753-50ba-4d1e-84e7-bc9711ef7429"