#!/bin/bash

# Bootstrap State Migration Script
# This script migrates existing bootstrap state to environment-specific backend configurations

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

# Function to check prerequisites
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
    local backup_dir="backups/bootstrap-migration-$(date +%Y%m%d_%H%M%S)"
    
    print_info "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    # Backup local state files
    if [ -f "terraform.tfstate" ]; then
        cp "terraform.tfstate" "$backup_dir/terraform.tfstate.backup"
        print_success "Local state backed up"
    fi
    
    if [ -f ".terraform/terraform.tfstate" ]; then
        cp ".terraform/terraform.tfstate" "$backup_dir/terraform.tfstate.backend.backup"
        print_success "Backend state reference backed up"
    fi
    
    # Backup .terraform directory
    if [ -d ".terraform" ]; then
        cp -r ".terraform" "$backup_dir/.terraform.backup"
        print_success "Terraform working directory backed up"
    fi
    
    echo "$backup_dir" > .last_backup_location
    print_success "Backup completed in: $backup_dir"
}

# Function to migrate bootstrap state to environment-specific backend
migrate_bootstrap_to_environment() {
    local env=$1
    local backend_config="backend/bootstrap-${env}.tfbackend"
    
    print_info "Migrating bootstrap state to $env environment..."
    
    # Check if backend config exists
    if [ ! -f "$backend_config" ]; then
        print_error "Backend configuration not found: $backend_config"
        exit 1
    fi
    
    print_info "Backend configuration:"
    cat "$backend_config"
    echo
    
    # Remove existing .terraform directory to ensure clean migration
    if [ -d ".terraform" ]; then
        print_info "Removing existing .terraform directory for clean migration"
        rm -rf ".terraform"
    fi
    
    # Initialize with new backend configuration
    print_info "Initializing Terraform with new backend configuration..."
    if [ -f "terraform.tfstate" ]; then
        # If local state exists, migrate it
        print_info "Local state found, migrating to remote backend..."
        terraform init -backend-config="$backend_config" -migrate-state
    else
        # If no local state, try to initialize and reconfigure
        print_info "No local state found, initializing with remote backend..."
        terraform init -backend-config="$backend_config" -reconfigure
    fi
    
    print_success "Bootstrap state migration completed for $env environment"
}

# Function to verify migration
verify_migration() {
    local env=$1
    
    print_info "Verifying bootstrap state migration..."
    
    # Check if terraform can read the state
    print_info "Checking state accessibility..."
    if terraform show >/dev/null 2>&1; then
        print_success "State is accessible and readable"
    else
        print_error "Cannot read terraform state after migration"
        return 1
    fi
    
    # Run terraform plan to ensure no changes are required
    print_info "Running terraform plan to verify no resource changes..."
    if terraform plan -var-file="environments/${env}.tfvars" -detailed-exitcode; then
        print_success "Migration verified - no resource changes detected"
    else
        local exit_code=$?
        if [ $exit_code -eq 2 ]; then
            print_warning "Terraform plan shows changes. This might indicate:"
            print_warning "1. Variables have changed"
            print_warning "2. Resource drift has occurred"
            print_warning "Please review the plan output carefully."
        else
            print_error "Terraform plan failed with exit code: $exit_code"
            return 1
        fi
    fi
}

# Function to show current state info
show_state_info() {
    print_info "Current bootstrap state information:"
    
    # Show backend configuration
    terraform show -json | jq -r '.terraform_version' 2>/dev/null || echo "Unable to determine terraform version"
    
    # Show resource count
    local resource_count=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources | length' 2>/dev/null || echo "Unknown")
    print_info "Number of resources in state: $resource_count"
    
    # List some key resources
    print_info "Key bootstrap resources:"
    terraform state list 2>/dev/null | head -10 || echo "Unable to list resources"
}

# Main migration function
main() {
    local env=${1:-""}
    
    if [ -z "$env" ]; then
        echo "Usage: $0 <environment>"
        echo "Environments: dev, test, stage, prod"
        echo
        echo "This script will:"
        echo "1. Backup current bootstrap state"
        echo "2. Migrate to environment-specific backend (bootstrap-<env>.tfstate)"
        echo "3. Verify migration success"
        echo
        echo "Make sure you are in the bootstrap/ directory before running this script"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "main.tf" ] || [ ! -d "backend" ]; then
        print_error "This script must be run from the bootstrap/ directory"
        print_error "Make sure you have main.tf and backend/ directory in current path"
        exit 1
    fi
    
    validate_environment "$env"
    check_prerequisites
    
    print_info "Starting bootstrap state migration for environment: $env"
    print_info "Working directory: $(pwd)"
    print_info "Target backend key: bootstrap-${env}.tfstate"
    
    # Show current state info
    show_state_info
    
    # Confirm before proceeding
    echo
    read -p "Do you want to proceed with bootstrap state migration to $env environment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Migration cancelled by user"
        exit 0
    fi
    
    # Create backup
    backup_current_state
    
    # Migrate state
    migrate_bootstrap_to_environment "$env"
    
    # Verify migration
    verify_migration "$env"
    
    print_success "Bootstrap state migration completed successfully!"
    print_info "Your bootstrap state is now stored as: bootstrap-${env}.tfstate"
    
    # Show final state info
    echo
    print_info "Final bootstrap state information:"
    show_state_info
    
    echo
    print_info "To deploy bootstrap to other environments, use:"
    print_info "terraform init -backend-config=backend/bootstrap-<other-env>.tfbackend"
    print_info "terraform plan -var-file=environments/<other-env>.tfvars"
    print_info "terraform apply -var-file=environments/<other-env>.tfvars"
}

# Run main function with all arguments
main "$@"