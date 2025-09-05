# Setting Up New Repository with Shared Bootstrap

This guide explains how to set up a new repository that uses the shared bootstrap resources without recreating them.

## Directory Structure

```
terraform-azure-ops/                    # Bootstrap repository
├── bootstrap/                          # Bootstrap resources (one-time setup)
│   ├── providers.tf                   # Local backend
│   ├── main.tf                        # Creates storage account, OIDC, etc.
│   └── environments/                  # Bootstrap environment configs
└── infra/                            # Infrastructure using bootstrap backend
    ├── providers.tf                  # Remote backend configuration
    ├── backend/                      # Backend configs for each environment
    │   ├── dev.tfbackend
    │   ├── test.tfbackend
    │   ├── stage.tfbackend
    │   └── prod.tfbackend
    └── environments/                 # Infrastructure environment variables
```

## Bootstrap Setup (One-time per Azure Subscription)

1. **Deploy Bootstrap Resources:**
   ```bash
   cd bootstrap/
   terraform init
   terraform plan -var-file=environments/dev.tfvars
   terraform apply -var-file=environments/dev.tfvars
   ```

2. **Get Backend Configuration Values:**
   ```bash
   terraform output multi_app_backend_config
   ```

## Infrastructure Setup (This Repository)

1. **Update Backend Configurations:**
   
   Update `infra/backend/*.tfbackend` files with bootstrap outputs:
   
   ```hcl
   # infra/backend/dev.tfbackend
   resource_group_name  = "rg-tfstate"                    # From bootstrap
   storage_account_name = "edgeopstechtfstate"            # From bootstrap output
   container_name       = "terraform-azure-ops"           # From bootstrap output  
   key                  = "dev.tfstate"                   # Environment specific
   use_oidc             = true
   ```

2. **Initialize Infrastructure:**
   ```bash
   cd infra/
   terraform init -backend-config=backend/dev.tfbackend
   terraform plan -var-file=environments/dev.tfvars
   terraform apply -var-file=environments/dev.tfvars
   ```

## New Repository Setup

When creating a new repository that should use the same bootstrap resources:

1. **Copy Structure:**
   ```bash
   # In your new repository
   mkdir infra
   cp terraform-azure-ops/infra/providers.tf infra/
   cp -r terraform-azure-ops/infra/backend infra/
   cp -r terraform-azure-ops/infra/environments infra/
   ```

2. **Update Backend Configs:**
   
   Update container names in `infra/backend/*.tfbackend`:
   ```hcl
   resource_group_name  = "rg-tfstate"                    # Same
   storage_account_name = "edgeopstechtfstate"            # Same  
   container_name       = "your-new-repo-name"            # CHANGE THIS
   key                  = "dev.tfstate"                   # Same
   use_oidc             = true                            # Same
   ```

3. **Create Your Infrastructure:**
   ```bash
   cd infra/
   # Add your main.tf, variables.tf, etc.
   terraform init -backend-config=backend/dev.tfbackend
   terraform plan -var-file=environments/dev.tfvars
   ```

## Key Benefits

- **No Bootstrap Recreation**: Bootstrap runs once, creates storage account and OIDC
- **Shared Resources**: Multiple repos use same storage account with different containers
- **Environment Isolation**: Each environment has separate state files
- **Consistent Structure**: Same backend/tfvars pattern across repositories

## Bootstrap vs Infrastructure

| Aspect | Bootstrap | Infrastructure |
|--------|-----------|----------------|
| **Purpose** | Creates shared backend resources | Uses shared backend resources |
| **Backend** | Local state | Remote state in Azure Storage |
| **Frequency** | Once per Azure subscription | Once per repository |
| **Resources** | Storage account, OIDC, containers | Application infrastructure |
| **State Storage** | Local files | Azure Storage containers |