#!/bin/bash

# Bootstrap Fix - Comprehensive Cleanup and Rebuild
# This script completely removes and recreates the Azure AD application to avoid any conflicts

echo "🚀 Bootstrap Fix v2 - Complete Cleanup and Rebuild"
echo "================================================="

# Check if we're logged in
if ! az account show &>/dev/null; then
    echo "❌ Not logged into Azure. Please run 'az login' first."
    exit 1
fi

# Set environment variables
export ARM_USE_OIDC=true
export ARM_CLIENT_ID="80fe8753-50ba-4d1e-84e7-bc9711ef7429"
export ARM_TENANT_ID="78b776c8-c1c5-4f5b-b46e-4dcd278720b5"
export ARM_SUBSCRIPTION_ID="57d390f5-f0dd-4db6-beba-16712e21d0fc"
echo "✅ Environment variables set"

# Remove the entire Azure AD application to start fresh
echo "🗑️ Removing Azure AD application to start completely fresh..."
APP_DISPLAY_NAME="github-EdgeOpsTech-terraform"
APP_ID=$(az ad app list --display-name "$APP_DISPLAY_NAME" --query "[0].id" -o tsv)

if [ -n "$APP_ID" ] && [ "$APP_ID" != "null" ]; then
    echo "Found existing app: $APP_ID"
    
    # Get service principal ID
    SP_ID=$(az ad sp list --display-name "$APP_DISPLAY_NAME" --query "[0].id" -o tsv)
    if [ -n "$SP_ID" ] && [ "$SP_ID" != "null" ]; then
        echo "Deleting service principal: $SP_ID"
        az ad sp delete --id "$SP_ID"
    fi
    
    # Delete the application
    echo "Deleting Azure AD application: $APP_ID"
    az ad app delete --id "$APP_ID"
    
    echo "✅ Azure AD application deleted"
    
    # Wait for deletion to propagate
    echo "⏳ Waiting for deletion to propagate..."
    sleep 30
else
    echo "No existing application found"
fi

# Clean up Terraform state
echo "🧹 Cleaning up Terraform state..."
terraform init

# Remove all federated credential resources from state
terraform state list | grep "azuread_application_federated_identity_credential" | while read -r resource; do
    echo "Removing from state: $resource"
    terraform state rm "$resource" 2>/dev/null || true
done

# Remove application and service principal from state
terraform state rm "azuread_application.github_oidc" 2>/dev/null || true
terraform state rm "azuread_service_principal.github_oidc" 2>/dev/null || true

# Handle resource group import
if ! terraform state show azurerm_resource_group.tfstate &>/dev/null; then
    echo "📦 Importing existing resource group..."
    # Try to import the resource group - handle if it doesn't exist
    if az group show --name "rg-tfstate" &>/dev/null; then
        RESOURCE_GROUP_ID="/subscriptions/57d390f5-f0dd-4db6-beba-16712e21d0fc/resourceGroups/rg-tfstate"
        terraform import azurerm_resource_group.tfstate "$RESOURCE_GROUP_ID" || true
    fi
fi

echo "✅ State cleaned"

# Now run terraform apply to rebuild everything
echo "🚀 Applying Terraform configuration..."
terraform plan -out=tfplan
if terraform apply tfplan; then
    echo ""
    echo "🎉 Bootstrap completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "- Azure AD application recreated"
    echo "- Federated identity credentials configured"
    echo "- Storage account and containers ready"
    echo "- Role assignments configured"
    echo ""
else
    echo "❌ Bootstrap failed. Check the errors above."
    exit 1
fi