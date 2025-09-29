#!/bin/bash

# Script to assign storage account permissions for state management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Storage account details
STORAGE_ACCOUNT="edgeopstechtfstate"
RESOURCE_GROUP="rg-tfstate"

print_info "Assigning Storage Blob Data Contributor role to current user..."

# Set subscription (get from storage account or ask user)
print_info "Setting Azure subscription context..."
SUBSCRIPTION_ID="57d390f5-f0dd-4db6-beba-16712e21d0fc"

# Set the subscription
az account set --subscription "$SUBSCRIPTION_ID"
print_info "Active subscription set to: $SUBSCRIPTION_ID"

# Get current user's object ID
USER_OBJECT_ID=$(az ad signed-in-user show --query id --output tsv)
print_info "Current user object ID: $USER_OBJECT_ID"

# Get storage account resource ID
STORAGE_ACCOUNT_ID=$(az storage account show \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query id \
    --output tsv)

print_info "Storage account ID: $STORAGE_ACCOUNT_ID"

# Assign Storage Blob Data Contributor role
print_info "Assigning Storage Blob Data Contributor role..."
az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee "$USER_OBJECT_ID" \
    --scope "$STORAGE_ACCOUNT_ID"

print_success "Storage Blob Data Contributor role assigned successfully!"

# Verify the assignment
print_info "Verifying role assignment..."
az role assignment list \
    --assignee "$USER_OBJECT_ID" \
    --scope "$STORAGE_ACCOUNT_ID" \
    --output table

print_success "Permission assignment completed!"
print_info "You may need to wait a few minutes for the permissions to propagate."