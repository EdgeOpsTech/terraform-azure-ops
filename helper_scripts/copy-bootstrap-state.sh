#!/bin/bash

# Bootstrap State Copying Script
# Copies existing bootstrap.tfstate to all environment-specific state files

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

# Check if Azure CLI is available and user is logged in
check_azure_login() {
    print_info "Checking Azure CLI authentication..."
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed or not in PATH"
        exit 1
    fi
    
    if ! az account show &>/dev/null; then
        print_error "Not logged into Azure CLI. Please run: az login"
        exit 1
    fi
    
    print_success "Azure CLI authentication verified"
}

# Determine auth method to use
get_auth_method() {
    local storage_account="edgeopstechtfstate"
    local container="terraform-azure-ops"
    
    # Try login method first (redirect all output to suppress warnings)
    if az storage blob list \
        --account-name "$storage_account" \
        --container-name "$container" \
        --auth-mode login \
        --output none >/dev/null 2>&1; then
        echo "login"
        return 0
    fi
    
    # Try account key method (redirect all output to suppress warnings)
    if az storage blob list \
        --account-name "$storage_account" \
        --container-name "$container" \
        --auth-mode key \
        --output none >/dev/null 2>&1; then
        echo "key"
        return 0
    fi
    
    print_error "Neither login nor key authentication worked"
    print_error "You may need to:"
    print_error "1. Ensure you're logged into Azure: az login"
    print_error "2. Set subscription: az account set --subscription YOUR_SUBSCRIPTION_ID"
    print_error "3. Or assign Storage Blob Data Contributor role"
    return 1
}

# Function to copy state file in Azure Storage
copy_state_to_environment() {
    local env=$1
    local source_blob="bootstrap.tfstate"
    local target_blob="bootstrap-${env}.tfstate"
    local storage_account="edgeopstechtfstate"
    local container="terraform-azure-ops"
    local auth_method=$2
    
    print_info "Copying bootstrap state to $env environment..."
    print_info "Source: $source_blob"
    print_info "Target: $target_blob"
    print_info "Auth method: $auth_method"
    
    # Check if source blob exists
    if ! az storage blob exists \
        --account-name "$storage_account" \
        --container-name "$container" \
        --name "$source_blob" \
        --auth-mode "$auth_method" \
        --output tsv &>/dev/null; then
        print_error "Source state file '$source_blob' not found in storage account"
        print_info "Available blobs in container:"
        az storage blob list \
            --account-name "$storage_account" \
            --container-name "$container" \
            --auth-mode "$auth_method" \
            --output table \
            --query "[].{Name:name, Modified:properties.lastModified, Size:properties.contentLength}"
        return 1
    fi
    
    # Check if target already exists
    if az storage blob exists \
        --account-name "$storage_account" \
        --container-name "$container" \
        --name "$target_blob" \
        --auth-mode "$auth_method" \
        --output tsv &>/dev/null; then
        print_warning "Target state file '$target_blob' already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping $env environment"
            return 0
        fi
    fi
    
    # Copy the blob
    print_info "Copying state file..."
    if az storage blob copy start \
        --account-name "$storage_account" \
        --destination-container "$container" \
        --destination-blob "$target_blob" \
        --source-account-name "$storage_account" \
        --source-container "$container" \
        --source-blob "$source_blob" \
        --auth-mode "$auth_method" \
        --output none; then
        
        # Wait for copy to complete
        print_info "Waiting for copy operation to complete..."
        local max_attempts=30
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            local copy_status=$(az storage blob show \
                --account-name "$storage_account" \
                --container-name "$container" \
                --name "$target_blob" \
                --auth-mode "$auth_method" \
                --query "properties.copy.status" \
                --output tsv 2>/dev/null || echo "failed")
            
            if [ "$copy_status" = "success" ]; then
                print_success "State successfully copied to $env environment"
                return 0
            elif [ "$copy_status" = "failed" ]; then
                print_error "Copy operation failed for $env environment"
                return 1
            elif [ "$copy_status" = "pending" ]; then
                print_info "Copy in progress... (attempt $attempt/$max_attempts)"
                sleep 2
                ((attempt++))
            else
                # If blob exists and has content, consider it successful
                local blob_size=$(az storage blob show \
                    --account-name "$storage_account" \
                    --container-name "$container" \
                    --name "$target_blob" \
                    --auth-mode "$auth_method" \
                    --query "properties.contentLength" \
                    --output tsv 2>/dev/null || echo "0")
                
                if [ "$blob_size" -gt 0 ]; then
                    print_success "State successfully copied to $env environment"
                    return 0
                fi
                
                print_info "Waiting for copy... (attempt $attempt/$max_attempts)"
                sleep 2
                ((attempt++))
            fi
        done
        
        print_error "Copy operation timed out for $env environment"
        return 1
    else
        print_error "Failed to start copy operation for $env environment"
        return 1
    fi
}

# Function to initialize terraform with the copied state
initialize_environment() {
    local env=$1
    local backend_config="backend/bootstrap-${env}.tfbackend"
    
    print_info "Initializing terraform for $env environment..."
    
    if [ ! -f "$backend_config" ]; then
        print_error "Backend configuration not found: $backend_config"
        return 1
    fi
    
    # Remove .terraform directory for clean initialization
    if [ -d ".terraform" ]; then
        rm -rf ".terraform"
    fi
    
    # Initialize with the backend
    if terraform init -backend-config="$backend_config" -input=false; then
        print_success "Terraform initialized for $env environment"
        
        # Quick verification
        if terraform show >/dev/null 2>&1; then
            local resource_count=$(terraform state list 2>/dev/null | wc -l)
            print_success "State verification passed - $resource_count resources found"
        else
            print_warning "State verification failed, but initialization succeeded"
        fi
        
        return 0
    else
        print_error "Failed to initialize terraform for $env environment"
        return 1
    fi
}

# Function to show available state files
show_available_states() {
    local storage_account="edgeopstechtfstate"
    local container="terraform-azure-ops"
    local auth_method=$1
    
    print_info "Available state files in storage account:"
    az storage blob list \
        --account-name "$storage_account" \
        --container-name "$container" \
        --auth-mode "$auth_method" \
        --output table \
        --query "[?contains(name, '.tfstate')].{Name:name, Modified:properties.lastModified, Size:properties.contentLength}" || {
        print_warning "Could not list files with $auth_method authentication"
    }
}

# Main function
main() {
    local environments=("dev" "test" "stage" "prod")
    local selected_envs=()
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        # No arguments provided, copy to all environments
        selected_envs=("${environments[@]}")
    else
        # Validate provided environments
        for env in "$@"; do
            if [[ ! " ${environments[@]} " =~ " ${env} " ]]; then
                print_error "Invalid environment: $env. Must be one of: ${environments[*]}"
                exit 1
            fi
            selected_envs+=("$env")
        done
    fi
    
    print_info "Bootstrap State Copying Script"
    print_info "=============================="
    print_info "This script will copy bootstrap.tfstate to environment-specific state files"
    print_info "Environments to process: ${selected_envs[*]}"
    echo
    
    # Check if we're in the right directory
    if [ ! -f "main.tf" ] || [ ! -d "backend" ]; then
        print_error "This script must be run from the bootstrap/ directory"
        print_error "Make sure you have main.tf and backend/ directory in current path"
        exit 1
    fi
    
    check_azure_login
    
    # Determine which auth method to use
    print_info "Determining authentication method..."
    local auth_method
    if ! auth_method=$(get_auth_method); then
        exit 1
    fi
    print_success "Using authentication method: $auth_method"
    
    show_available_states "$auth_method"
    
    echo
    read -p "Do you want to proceed with copying bootstrap state to the selected environments? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled by user"
        exit 0
    fi
    
    # Copy state to each environment
    local success_count=0
    local total_count=${#selected_envs[@]}
    
    for env in "${selected_envs[@]}"; do
        echo
        print_info "Processing $env environment..."
        
        if copy_state_to_environment "$env" "$auth_method"; then
            if initialize_environment "$env"; then
                ((success_count++))
            fi
        fi
    done
    
    echo
    print_info "========================================="
    print_success "Completed processing $success_count of $total_count environments"
    
    if [ $success_count -eq $total_count ]; then
        print_success "All environments processed successfully!"
        echo
        print_info "You can now work with any environment using:"
        for env in "${selected_envs[@]}"; do
            print_info "  terraform init -backend-config=backend/bootstrap-${env}.tfbackend"
        done
    else
        print_warning "Some environments had issues. Check the output above for details."
    fi
    
    echo
    print_info "Final state files:"
    show_available_states "$auth_method"
}

# Show usage if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Bootstrap State Copying Script"
    echo "Usage: $0 [environment1] [environment2] ..."
    echo
    echo "Environments: dev, test, stage, prod"
    echo
    echo "Examples:"
    echo "  $0                    # Copy to all environments"
    echo "  $0 dev                # Copy to dev only"
    echo "  $0 dev test          # Copy to dev and test"
    echo
    echo "This script will:"
    echo "1. Copy bootstrap.tfstate to bootstrap-<env>.tfstate in Azure Storage"
    echo "2. Initialize terraform for each environment"
    echo "3. Verify state accessibility"
    exit 0
fi

# Run main function
main "$@"