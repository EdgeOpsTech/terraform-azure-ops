# Fix Storage Account Permissions

The error you encountered is due to missing permissions on the storage account. Here are three ways to fix this:

## Option 1: Assign Storage Blob Data Contributor Role (Recommended)

```bash
# Run the permission assignment script
chmod +x assign-storage-permissions.sh
./assign-storage-permissions.sh
```

This will assign the "Storage Blob Data Contributor" role to your current user for the storage account.

## Option 2: Manual Role Assignment via Azure Portal

1. Go to Azure Portal → Storage Accounts → `edgeopstechtfstate`
2. Click on "Access Control (IAM)" in the left menu
3. Click "Add" → "Add role assignment"
4. Select "Storage Blob Data Contributor" role
5. Select "User, group, or service principal"
6. Search for and select your user account
7. Click "Review + assign"

## Option 3: Manual Role Assignment via Azure CLI

```bash
# Get your user object ID
USER_ID=$(az ad signed-in-user show --query id --output tsv)

# Get storage account resource ID
STORAGE_ID=$(az storage account show \
    --name "edgeopstechtfstate" \
    --resource-group "rg-tfstate" \
    --query id --output tsv)

# Assign the role
az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee "$USER_ID" \
    --scope "$STORAGE_ID"
```

## After Assigning Permissions

1. **Wait 5-10 minutes** for permissions to propagate
2. **Run the updated script** (it will automatically detect the correct auth method):

```bash
cd bootstrap/
chmod +x ../copy-bootstrap-state.sh
../copy-bootstrap-state.sh
```

## What the Updated Script Does

The updated script now:
- ✅ **Auto-detects authentication method** (tries login first, falls back to key)
- ✅ **Uses appropriate auth method** for all Azure CLI commands
- ✅ **Provides clear error messages** if authentication fails
- ✅ **Works with both RBAC and key-based authentication**

## Expected Output After Fix

```
[INFO] Determining authentication method...
[SUCCESS] Using authentication method: login
[INFO] Available state files in storage account:
Name                     Modified                    Size
bootstrap.tfstate        2025-09-05T13:40:42+00:00   126.25 KiB

Do you want to proceed? (y/N): y

[INFO] Processing dev environment...
[INFO] Auth method: login
[SUCCESS] State successfully copied to dev environment
[SUCCESS] All environments processed successfully!
```

## If You Still Get Permission Errors

The script will automatically try the account key method if login fails:

```
[WARNING] Login authentication failed, trying account key method...
[SUCCESS] Using authentication method: key
```

This ensures the script works regardless of your permission setup!

## Required Roles

For full functionality, you need one of these roles on the storage account:
- **Storage Blob Data Contributor** (recommended - read/write access)
- **Storage Blob Data Owner** (full access)
- Or access to storage account keys (automatic fallback)