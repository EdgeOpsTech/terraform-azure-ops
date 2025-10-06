#!/bin/bash

# Bootstrap Setup Script
# This script helps with the initial setup of the bootstrap module

set -e

echo "🚀 Bootstrap Module Setup"
echo "========================="

# Check if we're in the bootstrap directory
if [ ! -f "main.tf" ]; then
    echo "❌ Error: Please run this script from the bootstrap directory"
    exit 1
fi

# Check if backend.tf exists and has backend configuration
if [ -f "backend.tf" ]; then
    echo "📋 Backend configuration found in backend.tf"
    echo "⚠️  Note: For initial setup, you may need to temporarily comment out the backend configuration"
    echo "   in backend.tf if the storage infrastructure doesn't exist yet."
    echo ""
fi

echo "🔧 Initializing Terraform..."
terraform init

echo "📋 Planning deployment..."
terraform plan

echo ""
echo "❓ Do you want to apply the changes? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "🚀 Applying changes..."
    terraform apply
    echo ""
    echo "✅ Bootstrap module deployed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. If you commented out the backend configuration, uncomment it now"
    echo "2. Run 'terraform init -migrate-state' to move state to Azure Storage"
    echo "3. You can now deploy from anywhere using the Azure Storage backend"
else
    echo "❌ Deployment cancelled"
fi 