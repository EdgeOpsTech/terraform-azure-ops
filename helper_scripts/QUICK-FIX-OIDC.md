# Quick Fix for OIDC Duplicate Credentials Error

## Problem
Terraform is trying to create federated identity credentials that already exist in Azure AD, causing this error:
```
Request_MultipleObjectsWithSameKeyValue: FederatedIdentityCredential with name github-EdgeOpsTech-stage-* already exists.
```

## Root Cause
The credentials exist in Azure AD but are not tracked in your Terraform state file.

## Quick Solution Options

### Option 1: Clean Slate Approach (Recommended)

**Delete existing credentials and let Terraform recreate them:**

```bash
# Navigate to bootstrap directory
cd bootstrap/

# Run the fix script
chmod +x ../fix-oidc-duplicates.sh
../fix-oidc-duplicates.sh

# Select Option 2 to delete existing credentials
# Then run terraform apply again
terraform apply -var-file=environments/dev.tfvars
```

### Option 2: Manual Cleanup (Alternative)

**Delete specific conflicting credentials:**

```bash
# For the stage app (ID: a85e889f-f49f-40e9-b403-1ea854a45dbd)
STAGE_APP_ID="a85e889f-f49f-40e9-b403-1ea854a45dbd"

# List existing credentials
az ad app federated-credential list --id $STAGE_APP_ID --output table

# Delete the conflicting ones (example)
az ad app federated-credential delete \
  --id $STAGE_APP_ID \
  --federated-credential-id "github-EdgeOpsTech-stage-edgeops-sub-mgmt-env-test"

# Repeat for other conflicting credentials...
```

### Option 3: Import into Terraform State (Advanced)

**Import existing credentials into Terraform state:**

```bash
# This requires knowing the exact credential IDs from Azure
# Not recommended unless you're comfortable with Terraform imports
```

## After Running the Fix

1. **Run Terraform Apply:**
   ```bash
   terraform apply -var-file=environments/dev.tfvars
   ```

2. **Verify Success:**
   ```bash
   terraform plan -var-file=environments/dev.tfvars
   # Should show "No changes" if successful
   ```

## Prevention

This issue happened because:
- Credentials were created previously outside of Terraform
- Or Terraform state was lost/corrupted
- Or there were multiple runs that created duplicates

To prevent future issues:
- Always use consistent state management
- Don't manually create OIDC credentials that Terraform manages
- Use proper state backends (which you now have setup)

## If You Want to Keep Existing Credentials

If the existing credentials are working and you want to keep them, you can:
1. Comment out the conflicting resources in your Terraform code temporarily
2. Or import them into Terraform state (complex process)

The cleanest approach is **Option 1** - delete and recreate through Terraform.