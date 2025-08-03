# Workflow Updates for Multi-Module Support

## Overview

Updated all GitHub Actions workflows to support both `infra` and `bootstrap` modules using matrix strategy.

## Changes Made

### 1. tf-plan-apply.yml
- **Added matrix strategy** to run for both `infra` and `bootstrap` modules
- **Updated job names** to include the module name (e.g., "Terraform Plan - infra", "Terraform Plan - bootstrap")
- **Modified artifact names** to be module-specific (e.g., `tfplan-infra`, `tfplan-bootstrap`)
- **Updated plan summaries** to show which module the plan is for
- **Applied changes to both plan and apply jobs**

### 2. tf-unit-tests.yml
- **Added matrix strategy** for both modules
- **Updated job names** to include module name
- **Modified Checkov scan** to scan the specific module directory
- **Updated SARIF category** to be module-specific

### 3. tf-drift.yml
- **Added matrix strategy** for both modules
- **Updated job names** to include module name
- **Modified drift detection** to create module-specific issues
- **Updated artifact names** to be module-specific

## How It Works

### Matrix Strategy
```yaml
strategy:
  matrix:
    working_dir: [infra, bootstrap]
```

This creates parallel jobs for each module:
- **infra**: Runs Terraform operations on the `infra/` directory
- **bootstrap**: Runs Terraform operations on the `bootstrap/` directory

### Job Naming
Jobs are now named with the module:
- `Terraform Plan - infra`
- `Terraform Plan - bootstrap`
- `Terraform Apply - infra`
- `Terraform Apply - bootstrap`

### Artifact Management
Each module gets its own artifacts:
- `tfplan-infra` and `tfplan-bootstrap`
- Separate drift detection for each module
- Module-specific security scan results

## Benefits

1. **Parallel Execution**: Both modules run simultaneously, reducing total workflow time
2. **Independent Management**: Each module can be managed separately
3. **Clear Visibility**: Easy to see which module is being processed
4. **Isolated Issues**: Drift detection creates separate issues for each module
5. **Consistent Process**: Same validation, testing, and deployment process for both modules

## Usage

### Automatic Triggers
- **Push to main**: Runs plan/apply for both modules
- **Pull requests**: Runs plan for both modules
- **Scheduled drift detection**: Checks both modules nightly

### Manual Triggers
- **Unit tests**: Can be triggered manually for both modules
- **Drift detection**: Can be triggered manually for both modules

## Backend Configuration

Both modules now use Azure Storage for state management:
- **infra**: Uses `terraform-azure-ops` container with `terraform.tfstate` key
- **bootstrap**: Uses `terraform-azure-ops` container with `bootstrap-tfstate.tfstate` key

## Next Steps

1. **Test the workflows** by pushing changes to trigger the new matrix jobs
2. **Monitor the execution** to ensure both modules are processed correctly
3. **Review drift detection** to ensure module-specific issues are created
4. **Verify security scans** are running for both modules 