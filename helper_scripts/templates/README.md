# Terraform Backend Configuration Templates

This directory contains templates for setting up Terraform backend configuration in new repositories, allowing them to use the shared bootstrap resources without recreating them.

## Bootstrap vs Infrastructure

### Bootstrap (One-time setup per Azure subscription)
- Creates: Storage account, resource groups, service principals, OIDC configuration
- Deployed once per Azure subscription/environment
- Stores its own state locally or in a separate bootstrap backend
- Located in `bootstrap/` directory

### Infrastructure Repositories
- Use the backend configuration created by bootstrap
- Reference bootstrap outputs without recreating bootstrap resources
- Can be deployed to multiple repositories using the same backend

## How to Use These Templates in a New Repository

### 1. Copy Backend Configuration Files

Copy these files to your new repository:

```bash
# Backend configuration template
cp templates/backend-config.tf.example providers.tf

# Backend environment files
mkdir backend/
cp templates/backend/*.tfbackend.example backend/
rename them to remove .example extension

# Environment variable files
mkdir environments/
cp templates/environments/*.tfvars.example environments/
rename them to remove .example extension
```

### 2. Update Backend Configuration Values

After running bootstrap deployment, update the template files with actual values:

1. Get the bootstrap outputs:
   ```bash
   cd bootstrap/
   terraform output multi_app_backend_config
   ```

2. Update each `backend/*.tfbackend` file with:
   - `storage_account_name`: From bootstrap output
   - `container_name`: Your repository's container name
   - Keep `resource_group_name = "rg-tfstate"`
   - Keep `use_oidc = true`

### 3. Update Environment Variables

Update `environments/*.tfvars` files with:
- `tenant_id`: Your Azure tenant ID
- `subscription_id`: Your Azure subscription ID
- Add your application-specific variables

### 4. Initialize Terraform

```bash
# For development environment
terraform init -backend-config=backend/dev.tfbackend

# Plan with environment variables
terraform plan -var-file=environments/dev.tfvars

# Apply
terraform apply -var-file=environments/dev.tfvars
```

## Directory Structure for New Repository

```
your-new-repo/
├── providers.tf              # Backend configuration
├── backend/
│   ├── dev.tfbackend         # Dev backend config
│   ├── test.tfbackend        # Test backend config
│   ├── stage.tfbackend       # Staging backend config
│   └── prod.tfbackend        # Production backend config
├── environments/
│   ├── dev.tfvars           # Dev environment variables
│   ├── test.tfvars          # Test environment variables
│   ├── stage.tfvars         # Staging environment variables
│   └── prod.tfvars          # Production environment variables
├── main.tf                   # Your infrastructure code
├── variables.tf              # Variable definitions
└── outputs.tf               # Output definitions
```

## Benefits of This Approach

1. **No Recreation**: Bootstrap resources are created once and reused
2. **Consistency**: Same backend and tfvars structure across repositories
3. **Isolation**: Each repository has its own state file
4. **Environment Separation**: Different state files for different environments
5. **Security**: Uses OIDC authentication, no stored credentials