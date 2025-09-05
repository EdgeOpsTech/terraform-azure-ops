# Terraform Backend Configuration

This directory contains environment-specific backend configurations to prevent state conflicts when switching between environments.

## Backend Configuration Files

- `dev.tfbackend` - Development environment state
- `test.tfbackend` - Test environment state  
- `stage.tfbackend` - Staging environment state
- `prod.tfbackend` - Production environment state

Each environment uses the same storage account but different state file keys to isolate state.

## Usage

### Initialize Terraform with Environment-Specific Backend

Instead of using the hardcoded backend in `providers.tf`, use the `-backend-config` flag:

```bash
# For development environment
terraform init -backend-config=backend/dev.tfbackend

# For test environment  
terraform init -backend-config=backend/test.tfbackend

# For staging environment
terraform init -backend-config=backend/stage.tfbackend

# For production environment
terraform init -backend-config=backend/prod.tfbackend
```

### Complete Workflow Example

```bash
# Switch to development environment
cd bootstrap/
terraform init -backend-config=../backend/dev.tfbackend
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"

# Switch to production environment  
terraform init -backend-config=../backend/prod.tfbackend
terraform plan -var="environment=prod"
terraform apply -var="environment=prod"
```

## Migrating Existing State

If you have existing state that needs to be migrated to the new backend structure:

### Automated Migration (Recommended)

Use the provided migration script:

```bash
# From project root directory
./migrate-state.sh dev    # Migrate to dev environment
./migrate-state.sh test   # Migrate to test environment
./migrate-state.sh stage  # Migrate to stage environment  
./migrate-state.sh prod   # Migrate to prod environment
```

The script will:
1. Create a backup of your current state
2. Initialize Terraform with the new backend configuration
3. Migrate the existing state to the new backend
4. Verify the migration was successful

### Manual Migration

If you prefer manual migration:

1. **Backup current state:**
   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   cp .terraform/terraform.tfstate .terraform/terraform.tfstate.backup
   ```

2. **Initialize with new backend:**
   ```bash
   terraform init -backend-config=backend/dev.tfbackend -migrate-state
   ```

3. **Verify migration:**
   ```bash
   terraform plan -var="environment=dev"
   ```

## Backend Configuration Details

All environments use the same Azure storage account but different state file keys:

- **Storage Account:** `edgeopstechtfstate`
- **Container:** `terraform-azure-ops`  
- **Resource Group:** `rg-tfstate`
- **Authentication:** OIDC (GitHub Actions)

### State File Keys by Environment:
- Dev: `dev.tfstate`
- Test: `test.tfstate`
- Stage: `stage.tfstate`  
- Prod: `prod.tfstate`

## Benefits

1. **Isolated State:** Each environment has its own state file
2. **No Resource Conflicts:** Resources won't be accidentally destroyed when switching environments
3. **Parallel Development:** Multiple environments can be managed simultaneously
4. **Consistent Backend:** Same storage account and container, different keys

## Troubleshooting

### State Lock Issues

If you encounter state lock issues:

```bash
# Check current locks
az storage blob list --account-name edgeopstechtfstate --container-name terraform-azure-ops --prefix "dev.tfstate"

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Backend Initialization Errors

1. Ensure you're authenticated to Azure:
   ```bash
   az login
   az account set --subscription "bba7ddf1-057e-4d04-afd9-4032cd79dc9d"
   ```

2. Verify storage account access:
   ```bash
   az storage container show --name terraform-azure-ops --account-name edgeopstechtfstate
   ```

### State File Recovery

If you need to recover from backup:

```bash
# List available backups
ls -la backups/

# Restore from backup (replace with your backup timestamp)
cp backups/20240905_143000/terraform.tfstate.backup terraform.tfstate
terraform init -backend-config=backend/dev.tfbackend -migrate-state
```

## Security Considerations

- All backend configurations use OIDC authentication
- State files are stored with private access in Azure Storage
- Backup files contain sensitive information - store securely
- Never commit state files to version control

## Integration with CI/CD

Update your GitHub Actions workflows to use environment-specific backends:

```yaml
- name: Terraform Init
  run: terraform init -backend-config=backend/${{ matrix.environment }}.tfbackend
  
- name: Terraform Plan  
  run: terraform plan -var="environment=${{ matrix.environment }}"
```