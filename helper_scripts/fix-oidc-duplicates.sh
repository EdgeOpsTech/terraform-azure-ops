#!/bin/bash

# Fix OIDC Federated Identity Credential Duplicates
# This script helps resolve the duplicate credential error

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Application IDs from the error messages
STAGE_APP_ID="a85e889f-f49f-40e9-b403-1ea854a45dbd"

print_info "OIDC Federated Identity Credential Duplicate Fix"
print_info "==============================================="
print_info "This script provides options to fix the duplicate credential error."
echo

print_warning "The error occurs because federated identity credentials already exist in Azure AD"
print_warning "but are not tracked in your Terraform state."
echo

echo "Choose an option:"
echo "1. Import existing credentials into Terraform state (recommended)"
echo "2. Delete existing credentials and let Terraform recreate them"
echo "3. Show current state and existing credentials"
echo "4. Exit"
echo

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        print_info "Option 1: Import existing credentials into Terraform state"
        print_warning "This will import the existing Azure AD credentials into your Terraform state."
        print_info "After import, Terraform will manage these existing credentials."
        echo
        
        print_info "You would need to run commands like:"
        echo "terraform import 'azuread_application_federated_identity_credential.environments_multi[\"stage-edgeops-sub-mgmt-test\"]' $STAGE_APP_ID/federatedIdentityCredential/CREDENTIAL_ID"
        echo
        print_warning "However, this requires knowing the exact credential IDs from Azure AD."
        print_warning "A better approach might be Option 2 (cleanup and recreate)."
        ;;
    
    2)
        print_info "Option 2: Delete existing credentials and let Terraform recreate them"
        print_warning "This will delete the existing federated identity credentials from Azure AD."
        print_info "After deletion, you can run 'terraform apply' to recreate them properly."
        echo
        
        read -p "Are you sure you want to delete existing credentials? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Listing existing federated identity credentials..."
            
            # List all credentials for the stage app
            print_info "Credentials for stage app ($STAGE_APP_ID):"
            az ad app federated-credential list \
                --id "$STAGE_APP_ID" \
                --query "[].{Name:name, Subject:subject, Description:description}" \
                --output table
            
            echo
            read -p "Delete all these credentials? This action cannot be undone! (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "Deleting existing federated identity credentials..."
                
                # Get all credential names and delete them
                credential_names=$(az ad app federated-credential list \
                    --id "$STAGE_APP_ID" \
                    --query "[].name" \
                    --output tsv)
                
                for name in $credential_names; do
                    print_info "Deleting credential: $name"
                    az ad app federated-credential delete \
                        --id "$STAGE_APP_ID" \
                        --federated-credential-id "$name" \
                        --only-show-errors || print_warning "Failed to delete $name (might not exist)"
                done
                
                print_success "Existing credentials deleted!"
                print_info "You can now run 'terraform apply' to recreate them."
            else
                print_info "Deletion cancelled."
            fi
        else
            print_info "Operation cancelled."
        fi
        ;;
    
    3)
        print_info "Option 3: Show current state and existing credentials"
        echo
        
        print_info "Terraform state for federated credentials:"
        terraform state list | grep "azuread_application_federated_identity_credential" || echo "No credentials in Terraform state"
        echo
        
        print_info "Existing credentials in Azure AD (stage app):"
        az ad app federated-credential list \
            --id "$STAGE_APP_ID" \
            --query "[].{Name:name, Subject:subject, Description:description}" \
            --output table
        echo
        
        print_info "To fix the issue, you can:"
        print_info "1. Import these existing credentials into Terraform state, or"
        print_info "2. Delete them from Azure AD and let Terraform recreate them"
        ;;
        
    4)
        print_info "Exiting..."
        exit 0
        ;;
        
    *)
        print_error "Invalid choice. Please run the script again."
        exit 1
        ;;
esac