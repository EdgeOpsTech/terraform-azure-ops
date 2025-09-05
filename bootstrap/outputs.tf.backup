# Azure AD Application Outputs
output "arm_client_id" {
  description = "Azure AD Application Client ID for GitHub Actions"
  value       = azuread_application.github_oidc.client_id
}

output "arm_subscription_id" {
  description = "Azure Subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "arm_tenant_id" {
  description = "Azure Tenant ID"
  value       = var.tenant_id
  sensitive   = true
}

# Storage Account Information
output "storage_account_name" {
  description = "Terraform state storage account name"
  value       = azurerm_storage_account.tfstate.name
}

output "storage_resource_group" {
  description = "Resource group containing the storage account"
  value       = azurerm_resource_group.tfstate.name
}

# Container Information
output "container_names" {
  description = "Map of repository names to their container names"
  value       = { for repo, container in azurerm_storage_container.tfstate : repo => container.name }
}

# Backend Configuration
output "backend_config" {
  description = "Terraform backend configuration for each repository"
  value = {
    for repo in var.github_repo : repo => {
      resource_group_name  = azurerm_resource_group.tfstate.name
      storage_account_name = azurerm_storage_account.tfstate.name
      container_name       = azurerm_storage_container.tfstate[local.container_names[repo]].name
      key                  = "terraform.tfstate"
      use_oidc             = true
      client_id            = azuread_application.github_oidc.client_id
    }
  }
}

# GitHub Secrets Instructions
output "github_secrets" {
  description = "GitHub secrets that need to be configured"
  value = {
    ARM_CLIENT_ID       = azuread_application.github_oidc.client_id
    ARM_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
    ARM_TENANT_ID       = var.tenant_id
  }
  sensitive = true
}

# Service Principal Information
output "service_principal_object_id" {
  description = "Service Principal Object ID"
  value       = azuread_service_principal.github_oidc.object_id
}