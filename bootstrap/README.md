# Bootstrap Module

This module sets up the foundational Azure infrastructure for Terraform state management and GitHub Actions OIDC authentication.

## Features

- Creates Azure Storage Account for Terraform state management
- Sets up storage containers for different repositories
- Configures Azure AD application for GitHub Actions OIDC
- Creates federated identity credentials for GitHub Actions
- Assigns necessary RBAC roles for the service principal

## Backend Configuration

The bootstrap module now uses Azure Storage for its own state management. The backend configuration is defined in `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "edgeopstechtfstate"
    container_name       = "tf-state-submgmt-np-main"
    key                  = "terraform.tfstate"
    use_oidc             = true
    client_id            = "fb40e7aa-7931-4675-9295-b0d7620ebf9a"
  }
}
```

## Usage

### Initial Setup (First Time)

For the initial setup, you'll need to use local state first to create the storage infrastructure:

1. Comment out the backend configuration in `backend.tf` temporarily
2. Run the bootstrap module locally:
   ```bash
   cd bootstrap
   terraform init
   terraform plan
   terraform apply
   ```
3. Uncomment the backend configuration in `backend.tf`
4. Migrate the state to Azure Storage:
   ```bash
   terraform init -migrate-state
   ```

### Subsequent Deployments

Once the storage infrastructure is created, you can deploy from anywhere using:

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

## Outputs

The module outputs the backend configuration for other modules to use:

- `backend_config`: Backend configuration for other Terraform modules
- `arm_client_id`: Azure AD application client ID for GitHub Actions
- `arm_subscription_id`: Azure subscription ID
- `arm_tenant_id`: Azure AD tenant ID

## Variables

- `tenant_id`: Azure AD tenant ID
- `subscription_id`: Azure subscription ID
- `location`: Azure region for resources
- `resource_group_name`: Name of the resource group
- `github_owner`: GitHub organization/username
- `github_repo`: List of GitHub repository names
- `branches`: List of git branches for federated identities
- `environments`: List of GitHub environments
- `pull_request`: Whether to enable pull request federated identities 