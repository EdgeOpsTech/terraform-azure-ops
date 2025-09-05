#!/bin/bash

# State Migration Script for Environment-Specific Backends
# This script helps migrate existing state to environment-specific backend configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if required tools are installed
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed or not in PATH"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to validate environment
validate_environment() {
    local env=$1
    if [[ ! "$env" =~ ^(dev|test|stage|prod)$ ]]; then
        print_error "Invalid environment: $env. Must be one of: dev, test, stage, prod"
        exit 1
    fi
}

# Function to backup current state
backup_current_state() {
    local env=$1
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    
    print_info "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    if [ -f "terraform.tfstate" ]; then
        cp "terraform.tfstate" "$backup_dir/terraform.tfstate.backup"
        print_success "Local state backed up"
    fi
    
    if [ -f ".terraform/terraform.tfstate" ]; then
        cp ".terraform/terraform.tfstate" "$backup_dir/terraform.tfstate.backend.backup"
        print_success "Backend state reference backed up"
    fi
    
    echo "$backup_dir" > .last_backup_location
    print_success "Backup completed in: $backup_dir"
}

# Function to migrate state to new backend
migrate_to_environment_backend() {
    local env=$1
    local backend_config="backend/${env}.tfbackend"
    
    print_info "Migrating state to $env environment backend..."
    
    # Check if backend config exists
    if [ ! -f "$backend_config" ]; then
        print_error "Backend configuration not found: $backend_config"
        exit 1
    fi
    
    print_info "Backend configuration:"
    cat "$backend_config"
    echo
    
    # Initialize with new backend configuration
    print_info "Initializing Terraform with new backend configuration..."
    terraform init -backend-config="$backend_config" -migrate-state -force-copy
    
    print_success "State migration completed for $env environment"
}

# Function to verify state migration
verify_migration() {
    local env=$1
    
    print_info "Verifying state migration..."
    
    # Run terraform plan to ensure no changes are required
    print_info "Running terraform plan to verify no resource changes..."
    if terraform plan -var="environment=$env" -detailed-exitcode; then
        print_success "State migration verified - no resource changes detected"
    else
        local exit_code=$?
        if [ $exit_code -eq 2 ]; then
            print_warning "Terraform plan shows changes. This might indicate state issues."
            print_info "Please review the plan output carefully."
        else
            print_error "Terraform plan failed with exit code: $exit_code"
            return 1
        fi
    fi
}

# Function to show current backend info
show_backend_info() {
    print_info "Current backend information:"
    terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "terraform_remote_state") | .values' 2>/dev/null || true
    
    print_info "Current state file location:"
    terraform show -json | jq -r '.terraform_version' 2>/dev/null || echo "Unable to determine current state"
}

# Main migration function
main() {
    local env=${1:-""}
    
    if [ -z "$env" ]; then
        echo "Usage: $0 <environment>"
        echo "Environments: dev, test, stage, prod"
        echo
        echo "This script will:"
        echo "1. Backup current state"
        echo "2. Migrate to environment-specific backend"
        echo "3. Verify migration success"
        exit 1
    fi
    
    validate_environment "$env"
    check_prerequisites
    
    print_info "Starting state migration for environment: $env"
    print_info "Working directory: $(pwd)"
    
    # Show current backend info
    show_backend_info
    
    # Confirm before proceeding
    echo
    read -p "Do you want to proceed with state migration to $env environment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Migration cancelled by user"
        exit 0
    fi
    
    # Create backup
    backup_current_state "$env"
    
    # Migrate state
    migrate_to_environment_backend "$env"
    
    # Verify migration
    verify_migration "$env"
    
    print_success "State migration completed successfully!"
    print_info "Your state is now managed with environment-specific backend: $env"
    
    # Show final backend info
    echo
    print_info "Final backend configuration:"
    show_backend_info
}

# Run main function with all arguments
main "$@"