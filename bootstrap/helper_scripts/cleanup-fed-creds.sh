#!/bin/bash

# Complete cleanup of all federated credentials
APP_ID="ede051fb-f928-44d9-ba3a-d4de9beeda8e"

echo "🧹 Cleaning up ALL federated identity credentials..."

# Get all credentials
CREDS=$(az ad app federated-credential list --id $APP_ID --query "[].name" -o tsv)

# Delete each one
if [ -n "$CREDS" ]; then
    for cred in $CREDS; do
        echo "Deleting: $cred"
        az ad app federated-credential delete --id $APP_ID --federated-credential-id "$cred"
    done
    echo "✅ All federated credentials deleted"
else
    echo "No credentials to delete"
fi