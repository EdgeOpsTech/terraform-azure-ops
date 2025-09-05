#!/bin/bash

# Minimal Bootstrap - Focus on core infrastructure
echo "🚀 Minimal Bootstrap - Core Infrastructure Only"
echo "==============================================="

# Check if we're logged in
if ! az account show &>/dev/null; then
    echo "❌ Not logged into Azure. Please run 'az login' first."
    exit 1
fi

# Set environment variables
export ARM_USE_OIDC=true
export ARM_CLIENT_ID="80fe8753-50ba-4d1e-84e7-bc9711ef7429"
export ARM_TENANT_ID="78b776c8-c1c5-4f5b-b46e-4dcd278720b5"
export ARM_SUBSCRIPTION_ID="bba7ddf1-057e-4d04-afd9-4032cd79dc9d"
echo "✅ Environment variables set"

# Clean all duplicates first
echo "🧹 Removing ALL Azure AD applications to start fresh..."
APP_DISPLAY_NAME="github-EdgeOpsTech-terraform"
az ad app list --display-name "$APP_DISPLAY_NAME" --query "[].id" -o tsv | while read -r app_id; do
    if [ -n "$app_id" ] && [ "$app_id" != "null" ]; then
        echo "Deleting app: $app_id"
        # Delete service principal first
        SP_ID=$(az ad sp list --filter "appId eq '$app_id'" --query "[0].id" -o tsv)
        if [ -n "$SP_ID" ] && [ "$SP_ID" != "null" ]; then
            az ad sp delete --id "$SP_ID" 2>/dev/null || true
        fi
        # Delete application
        az ad app delete --id "$app_id" 2>/dev/null || true
    fi
done

echo "✅ Cleanup completed"

# Clean Terraform state completely
echo "🧹 Cleaning Terraform state..."
terraform init
rm -f terraform.tfstate*
echo "✅ State reset"

# Now create just the core infrastructure
echo "🚀 Creating core infrastructure..."
terraform plan -out=tfplan-minimal

if terraform apply tfplan-minimal; then
    echo ""
    echo "🎉 Minimal bootstrap completed successfully!"
    echo ""
    echo "📋 What was created:"
    echo "- Azure AD application and service principal"
    echo "- Basic federated identity credentials"  
    echo "- Storage account: edgeopstechtfstate"
    echo "- Resource group: rg-tfstate"
    echo "- Storage containers for Terraform state"
    echo "- Role assignments"
    echo ""
    echo "💡 Note: Some federated credentials may need to be added manually"
    echo "   if you hit Azure AD application limits."
else
    echo "❌ Bootstrap failed. Check errors above."
    exit 1
fi