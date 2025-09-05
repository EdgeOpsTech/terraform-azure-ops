# Updated GitHub Workflows Guide

The GitHub workflows have been updated to support the new backend configuration structure with environment-specific backend configs and tfvars files.

## What Changed

### Main Workflow (`tf-plan-apply.yml`)
- ✅ **Backend Configuration**: Automatically uses correct backend config based on working directory and environment
- ✅ **Environment-specific tfvars**: Automatically uses `environments/<env>.tfvars` files
- ✅ **Flexible Parameters**: Support for both bootstrap and infrastructure deployments
- ✅ **Error Handling**: Better error messages for missing files

### New Workflow Structure

The updated workflow automatically determines:

**For Bootstrap:**
- Backend config: `backend/bootstrap-<env>.tfbackend` 
- Variables: `environments/<env>.tfvars`

**For Infrastructure:**
- Backend config: `backend/<env>.tfbackend`
- Variables: `environments/<env>.tfvars`

## Usage Examples

### 1. Manual Workflow Dispatch

#### Deploy Bootstrap to Dev Environment
```yaml
# Use the main workflow with these parameters:
working_dir: "bootstrap"
environment: "dev"
```

#### Deploy Infrastructure to Test Environment  
```yaml
# Use the main workflow with these parameters:
working_dir: "infra" 
environment: "test"
```

### 2. Automatic Workflow Files

I've created example workflow files:

**Bootstrap Dev Deployment** (`.github/workflows/deploy-bootstrap-dev.yml`):
- Triggers on changes to `bootstrap/**` 
- Uses `bootstrap/backend/bootstrap-dev.tfbackend`
- Uses `bootstrap/environments/dev.tfvars`

**Infrastructure Dev Deployment** (`.github/workflows/deploy-infra-dev.yml`):
- Triggers on changes to `infra/**`
- Uses `infra/backend/dev.tfbackend` 
- Uses `infra/environments/dev.tfvars`

### 3. Workflow Call from Other Repositories

```yaml
jobs:
  deploy-my-app:
    uses: your-org/terraform-azure-ops/.github/workflows/tf-plan-apply.yml@main
    with:
      working_dir: "infra"
      environment: "prod"  
    secrets:
      ARM_CLIENT_ID_PROD: ${{ secrets.ARM_CLIENT_ID_PROD }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      GH_PAT: ${{ secrets.GH_PAT }}
      SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
```

## Required Directory Structure

Your repository should have this structure:

```
repository/
├── bootstrap/
│   ├── backend/
│   │   ├── bootstrap-dev.tfbackend
│   │   ├── bootstrap-test.tfbackend
│   │   ├── bootstrap-stage.tfbackend
│   │   └── bootstrap-prod.tfbackend
│   ├── environments/
│   │   ├── dev.tfvars
│   │   ├── test.tfvars
│   │   ├── stage.tfvars
│   │   └── prod.tfvars
│   └── main.tf, providers.tf, etc.
│
├── infra/
│   ├── backend/
│   │   ├── dev.tfbackend
│   │   ├── test.tfbackend
│   │   ├── stage.tfbackend
│   │   └── prod.tfbackend
│   ├── environments/
│   │   ├── dev.tfvars
│   │   ├── test.tfvars
│   │   ├── stage.tfvars
│   │   └── prod.tfvars
│   └── main.tf, providers.tf, etc.
│
└── .github/workflows/
    ├── tf-plan-apply.yml         # Main reusable workflow
    ├── deploy-bootstrap-dev.yml  # Bootstrap dev deployment
    └── deploy-infra-dev.yml      # Infrastructure dev deployment
```

## Workflow Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `working_dir` | No | `"infra"` | Directory to run terraform in (`bootstrap` or `infra`) |
| `environment` | No | `"dev"` | Environment to deploy (`dev`, `test`, `stage`, `prod`) |
| `tf_vars_file` | No | `""` | Custom tfvars file (optional - defaults to `environments/<env>.tfvars`) |

## What the Workflow Does

1. **Determines Backend Config**: 
   - Bootstrap: `backend/bootstrap-<env>.tfbackend`
   - Infrastructure: `backend/<env>.tfbackend`

2. **Initializes Terraform**: `terraform init -backend-config=<config-file>`

3. **Uses Environment Variables**: 
   - Custom file if `tf_vars_file` provided
   - Otherwise: `environments/<environment>.tfvars`

4. **Runs Plan/Apply**: Standard terraform plan and apply with environment-specific configuration

## Error Handling

The workflow now provides better error messages:
- ✅ Missing backend configuration files
- ✅ Missing environment tfvars files  
- ✅ OIDC authentication issues
- ✅ File listing for debugging

This makes it much easier to troubleshoot deployment issues!