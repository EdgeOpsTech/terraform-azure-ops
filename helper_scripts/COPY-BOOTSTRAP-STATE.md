# Copy Bootstrap State Across Environments

This approach copies your existing `bootstrap.tfstate` to all environment-specific state files (`bootstrap-dev.tfstate`, `bootstrap-test.tfstate`, etc.) so you can work with any environment immediately without backend initialization errors.

## Quick Start

```bash
# Navigate to bootstrap directory
cd bootstrap/

# Make script executable
chmod +x ../copy-bootstrap-state.sh

# Copy to all environments
../copy-bootstrap-state.sh

# Or copy to specific environments only
../copy-bootstrap-state.sh dev test
```

## What This Does

1. **Copies `bootstrap.tfstate`** to `bootstrap-dev.tfstate`, `bootstrap-test.tfstate`, etc. in Azure Storage
2. **Initializes terraform** for each environment with the copied state
3. **Verifies state access** to ensure everything works
4. **No resource changes** - same resources, just multiple state copies

## After Running the Script

You can immediately work with any environment:

```bash
# Development environment
terraform init -backend-config=backend/bootstrap-dev.tfbackend
terraform plan -var-file=environments/dev.tfvars

# Test environment  
terraform init -backend-config=backend/bootstrap-test.tfbackend
terraform plan -var-file=environments/test.tfvars

# Stage environment
terraform init -backend-config=backend/bootstrap-stage.tfbackend
terraform plan -var-file=environments/stage.tfvars
```

## Expected Output

```
[INFO] Bootstrap State Copying Script
[INFO] Environments to process: dev test stage prod
[INFO] Available state files in storage account:
Name                     Modified                    Size
bootstrap.tfstate        2025-09-05T13:40:42+00:00   126.25 KiB

Do you want to proceed? (y/N): y

[INFO] Processing dev environment...
[INFO] Copying bootstrap state to dev environment...
[SUCCESS] State successfully copied to dev environment
[SUCCESS] Terraform initialized for dev environment
[SUCCESS] State verification passed - 15 resources found

[INFO] Processing test environment...
[SUCCESS] State successfully copied to test environment
[SUCCESS] Terraform initialized for test environment

...

[SUCCESS] All environments processed successfully!
```

## Final State Structure

After running the script, your Azure Storage will have:

```
Container: terraform-azure-ops
├── bootstrap.tfstate          # Original state (kept)
├── bootstrap-dev.tfstate      # Copy for dev environment
├── bootstrap-test.tfstate     # Copy for test environment  
├── bootstrap-stage.tfstate    # Copy for stage environment
├── bootstrap-prod.tfstate     # Copy for prod environment
├── infra-dev.tfstate         # Future infrastructure state
├── infra-test.tfstate        # Future infrastructure state
└── ...
```

## Advantages of This Approach

1. **No Backend Errors** - All environments have existing state
2. **Immediate Usability** - Can switch between environments instantly
3. **Same Resources** - All environments reference the same actual Azure resources
4. **Safe Operation** - Only copies state files, no resource changes
5. **Environment Isolation** - Each environment has its own state file for future changes

## When to Use Different Environments

**Same Resources (Current Setup):**
- All environments point to same bootstrap resources
- Useful for testing configuration changes safely
- Different tfvars but same infrastructure

**Separate Resources (Future):**  
- Deploy different bootstrap resources per environment
- Useful for true environment isolation
- Each environment has its own storage accounts, service principals, etc.

## Working with Copied States

```bash
# Check what environment you're in
terraform workspace show  # (if using workspaces)
# OR check the backend config being used

# Always verify before making changes
terraform plan -var-file=environments/dev.tfvars

# Make sure you're in the right environment before applying
terraform apply -var-file=environments/dev.tfvars
```

## Rollback if Needed

The original `bootstrap.tfstate` remains untouched, so you can always go back to your previous setup by simply using that state file.

This approach eliminates the backend initialization errors and gives you immediate access to work with any environment!