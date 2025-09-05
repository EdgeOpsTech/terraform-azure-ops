# Bootstrap State Migration Guide

This guide will help you migrate your existing bootstrap resources to the new environment-specific backend structure without recreating any resources.

## Current Situation

Based on your screenshot, you have existing bootstrap resources deployed with state files:
- `bootstrap-tfstate.tfstate` 
- `bootstrap.tfstate`
- `terraform.tfstate`

## Migration Goal

Migrate to environment-specific bootstrap state files:
- `bootstrap-dev.tfstate`
- `bootstrap-test.tfstate` 
- `bootstrap-stage.tfstate`
- `bootstrap-prod.tfstate`

## Step-by-Step Migration

### Step 1: Prepare for Migration

```bash
# Navigate to bootstrap directory
cd bootstrap/

# Check current state
terraform show

# Verify which environment your current resources represent
# Look at the tfvars file you used for the original deployment
ls environments/
```

### Step 2: Run Migration Script

**For Development Environment (most common):**
```bash
# Make the script executable
chmod +x ../migrate-bootstrap-state.sh

# Run migration to dev environment
../migrate-bootstrap-state.sh dev
```

**For Other Environments:**
```bash
# If your current bootstrap represents test environment
../migrate-bootstrap-state.sh test

# If your current bootstrap represents stage environment  
../migrate-bootstrap-state.sh stage

# If your current bootstrap represents prod environment
../migrate-bootstrap-state.sh prod
```

### Step 3: Verify Migration

After running the migration script, verify everything is working:

```bash
# Check that terraform can read the state
terraform show

# Run a plan to ensure no changes are detected
terraform plan -var-file=environments/dev.tfvars

# List all resources to confirm they're still there
terraform state list
```

### Step 4: Deploy to Other Environments (Optional)

If you need bootstrap resources for other environments:

```bash
# For test environment
terraform init -backend-config=backend/bootstrap-test.tfbackend -reconfigure
terraform plan -var-file=environments/test.tfvars
terraform apply -var-file=environments/test.tfvars

# For stage environment
terraform init -backend-config=backend/bootstrap-stage.tfbackend -reconfigure
terraform plan -var-file=environments/stage.tfvars
terraform apply -var-file=environments/stage.tfvars
```

## What the Migration Script Does

1. **Backs up current state** to `backups/bootstrap-migration-YYYYMMDD_HHMMSS/`
2. **Migrates state** from local/existing backend to new environment-specific backend
3. **Verifies migration** by running terraform plan
4. **Preserves all resources** - no resources are recreated or destroyed

## After Migration

### New Workflow for Bootstrap

```bash
# Development environment
cd bootstrap/
terraform init -backend-config=backend/bootstrap-dev.tfbackend
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Test environment  
terraform init -backend-config=backend/bootstrap-test.tfbackend
terraform plan -var-file=environments/test.tfvars
terraform apply -var-file=environments/test.tfvars
```

### Infrastructure Workflow (After Bootstrap Migration)

```bash
# Development infrastructure
cd ../infra/
terraform init -backend-config=backend/dev.tfbackend
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

## State File Structure After Migration

```
Azure Storage Container: terraform-azure-ops
├── bootstrap-dev.tfstate      # Bootstrap resources for dev
├── bootstrap-test.tfstate     # Bootstrap resources for test  
├── bootstrap-stage.tfstate    # Bootstrap resources for stage
├── bootstrap-prod.tfstate     # Bootstrap resources for prod
├── infra-dev.tfstate         # Infrastructure resources for dev
├── infra-test.tfstate        # Infrastructure resources for test
├── infra-stage.tfstate       # Infrastructure resources for stage
└── infra-prod.tfstate        # Infrastructure resources for prod
```

## Rollback Plan

If something goes wrong, you can rollback using the backups:

```bash
# Find your backup directory
cat .last_backup_location

# Restore from backup
cp backups/bootstrap-migration-YYYYMMDD_HHMMSS/terraform.tfstate.backup terraform.tfstate
cp -r backups/bootstrap-migration-YYYYMMDD_HHMMSS/.terraform.backup .terraform

# Reinitialize
terraform init
```

## Important Notes

- **No resources will be recreated** - this is purely a state migration
- **Always backup before migration** - the script does this automatically
- **Run from bootstrap/ directory** - the script checks this
- **Verify after migration** - run `terraform plan` to ensure no changes
- **One environment at a time** - migrate your existing resources to one environment first