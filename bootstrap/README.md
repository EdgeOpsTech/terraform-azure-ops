# Bootstrap Terraform Configuration

This directory contains the bootstrap Terraform configuration that sets up the foundational infrastructure for managing Terraform state and GitHub Actions OIDC authentication.

## What This Creates

- **Azure Resource Group**: Container for Terraform state resources
- **Storage Account**: Stores Terraform state files with versioning and retention
- **Storage Containers**: One per GitHub repository for isolated state management
- **Azure AD Application**: For GitHub Actions OIDC authentication
- **Service Principal**: With appropriate permissions for Terraform operations
- **Federated Identity Credentials**: For secure GitHub Actions authentication
- **RBAC Assignments**: Contributor, Storage Blob Data Contributor, User Access Administrator

## Prerequisites

- Azure CLI installed and logged in
- Terraform >= 1.6 installed
- Appropriate Azure permissions (Global Administrator or equivalent)

## Quick Start (Recommended)

For the initial bootstrap setup, use the automated setup script:

```bash
# Navigate to bootstrap directory
cd bootstrap

# Set environment variables (choose your platform)
# Windows (PowerShell):
$env:TF_VAR_tenant_id="f5222e6c-5fc6-48eb-8f03-73db18203b63"
$env:TF_VAR_subscription_id="bba7ddf1-057e-4d04-afd9-4032cd79dc9d"

# Linux/macOS:
export TF_VAR_tenant_id="f5222e6c-5fc6-48eb-8f03-73db18203b63"
export TF_VAR_subscription_id="bba7ddf1-057e-4d04-afd9-4032cd79dc9d"

# Login to Azure
az login

# Run the setup script
./setup.sh
```

This script will set up OIDC federated credentials for all environments (dev, test, stage, prod).

## Manual Setup (Alternative)

## Local Development

### Initial Setup

1. **Login to Azure:**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Set Required Environment Variables:**
   ```bash
   # Windows (PowerShell)
   $env:TF_VAR_tenant_id="f5222e6c-5fc6-48eb-8f03-73db18203b63"
   $env:TF_VAR_subscription_id="bba7ddf1-057e-4d04-afd9-4032cd79dc9d"

   # Windows (CMD)
   set TF_VAR_tenant_id=f5222e6c-5fc6-48eb-8f03-73db18203b63
   set TF_VAR_subscription_id=bba7ddf1-057e-4d04-afd9-4032cd79dc9d

   # Linux/macOS
   export TF_VAR_tenant_id="f5222e6c-5fc6-48eb-8f03-73db18203b63"
   export TF_VAR_subscription_id="bba7ddf1-057e-4d04-afd9-4032cd79dc9d"
   ```

### Running Terraform Commands

#### Development Environment
```bash
# Navigate to bootstrap directory
cd bootstrap

# Initialize Terraform
terraform init

# Plan with dev environment
terraform plan -var-file="environments/dev.tfvars"

# Apply with dev environment
terraform apply -var-file="environments/dev.tfvars"

# Destroy (if needed)
terraform destroy -var-file="environments/dev.tfvars"
```

#### Test Environment
```bash
terraform plan -var-file="environments/test.tfvars"
terraform apply -var-file="environments/test.tfvars"
```

#### Stage Environment
```bash
terraform plan -var-file="environments/stage.tfvars"
terraform apply -var-file="environments/stage.tfvars"
```

#### Production Environment
```bash
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

### Useful Commands

#### Validate Configuration
```bash
# Check syntax and validate
terraform validate

# Format code
terraform fmt -recursive

# Security scan (if tfsec is installed)
tfsec .
```

#### State Management
```bash
# Show current state
terraform show

# List resources
terraform state list

# Show specific resource
terraform state show azurerm_storage_account.tfstate

# Import existing resource (if needed)
terraform import azurerm_resource_group.tfstate /subscriptions/sub-id/resourceGroups/rg-tfstate
```

#### Outputs
```bash
# Show all outputs
terraform output

# Show specific output
terraform output arm_client_id
terraform output backend_config
```

## Environment Configuration

Each environment has its own tfvars file in the `environments/` directory:

- `dev.tfvars` - Development environment (eastus)
- `test.tfvars` - Test environment (eastus)
- `stage.tfvars` - Staging environment (centralus)
- `prod.tfvars` - Production environment (westus2)

## GitHub Secrets Setup

After applying the bootstrap configuration, you'll need to set these GitHub secrets:

```bash
# Get the values from terraform output
terraform output github_secrets
```

Required secrets:
- `ARM_CLIENT_ID_DEV` - Client ID for Dev SP (dev app)
- `ARM_CLIENT_ID_NONPROD` - Client ID for Nonprod SP (test + stage app)
- `ARM_CLIENT_ID_PROD` - Client ID for Prod SP (prod app)
- `ARM_SUBSCRIPTION_ID` - Azure Subscription ID
- `ARM_TENANT_ID` - Azure Tenant ID
- `GH_PAT` - GitHub Personal Access Token
- `SLACK_BOT_TOKEN` - Slack Bot Token (for notifications)

## Troubleshooting

### Common Issues

1. **Permission Denied:**
   ```bash
   # Ensure you have sufficient Azure permissions
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

2. **Storage Account Name Conflict:**
   ```bash
   # Check if storage account name is available
   az storage account check-name --name edgeopstechtfstate
   ```

3. **Backend Configuration:**
   ```bash
   # If backend fails, initialize without backend first
   terraform init -backend=false
   ```

### Debug Mode
```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform plan -var-file="environments/dev.tfvars"
```

## File Structure

```
bootstrap/
├── README.md                 # This file
├── providers.tf             # Terraform and provider configuration
├── variables.tf             # Input variables
├── locals.tf               # Local values
├── data.tf                 # Data sources
├── main.tf                 # Core infrastructure
├── github-oidc.tf          # GitHub OIDC setup
├── rbac.tf                 # Role assignments
├── outputs.tf              # Output values
└── environments/           # Environment-specific configs
    ├── dev.tfvars
    ├── test.tfvars
    ├── stage.tfvars
    └── prod.tfvars
```

## CI/CD Integration

This bootstrap configuration is automatically deployed via GitHub Actions:

- **Dev Branch** → Dev environment
- **Main Branch** → Test environment
- **Release Branch** → Stage environment
- **Manual Dispatch** → Prod environment

See `.github/workflows/caller-tf-plan-apply.yml` for the complete workflow configuration.
