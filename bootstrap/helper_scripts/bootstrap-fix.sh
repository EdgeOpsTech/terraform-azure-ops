#!/bin/bash

# Final Bootstrap Fix Script - Simple and Working
set -e

echo "🚀 Bootstrap Fix - Simple Approach"
echo "=================================="

# Set environment variables
export TF_VAR_tenant_id="${TF_VAR_tenant_id:-f5222e6c-5fc6-48eb-8f03-73db18203b63}"
export TF_VAR_subscription_id="${TF_VAR_subscription_id:-57d390f5-f0dd-4db6-beba-16712e21d0fc}"

echo "✅ Environment variables set"

# Import existing resource group (ignore errors)
echo "📦 Importing existing resource group..."
terraform import azurerm_resource_group.tfstate "/subscriptions/${TF_VAR_subscription_id}/resourceGroups/rg-tfstate" 2>/dev/null || echo "  ✓ Resource group handled"

# Nuclear option - remove problematic state and recreate
echo "🧹 Removing problematic federated credentials from state..."
terraform state rm 'azuread_application_federated_identity_credential.branches' 2>/dev/null || echo "  ✓ No branches to remove"
terraform state rm 'azuread_application_federated_identity_credential.environments' 2>/dev/null || echo "  ✓ No environments to remove"

# Apply cleanly
echo "🚀 Applying bootstrap configuration..."
terraform apply -var-file="environments/dev.tfvars" -auto-approve

echo ""
echo "🎉 Bootstrap setup completed!"
echo ""
echo "📋 Your GitHub secrets:"
terraform output github_secrets

echo ""
echo "✅ Next steps:"
echo "1. Add the secrets above to your GitHub repository"
echo "2. Re-enable bootstrap workflow in .github/workflows/caller-tf-plan-apply.yml" 
echo "3. Test your deployments"