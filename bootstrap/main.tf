terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

########################################
#  Providers
########################################
provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

########################################
#  Resource group + storage account
########################################
resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
}

# resource "random_string" "storage_suffix" {
#   length  = 8
#   lower   = true
#   numeric = false
#   special = false
# }

resource "azurerm_storage_account" "tfstate" {
  name                     = "edgeopstechtfstate"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  # ❌ Removed invalid property:
  # allow_blob_public_access = false

  min_tls_version = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

########################################
#  GitHub OIDC app & federated identity
########################################
# ✅ Declare missing data source
data "azuread_client_config" "current" {}

resource "azuread_application" "github_oidc" {
  display_name = "github-${var.github_owner}-${var.github_repo}-terraform"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "github_oidc" {
  application_id = azuread_application.github_oidc.application_id
}

resource "azuread_application_federated_identity_credential" "github" {
  application_object_id = azuread_application.github_oidc.object_id
  display_name          = "github-actions"

  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/*"
  audiences = ["api://AzureADTokenExchange"]
}

########################################
#  Role assignments
########################################
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "sub_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

########################################
#  Outputs for GitHub secrets & backend
########################################
output "arm_client_id" {
  description = "Set this as the GitHub secret ARM_CLIENT_ID"
  value       = azuread_application.github_oidc.application_id
}

output "arm_subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "arm_tenant_id" {
  value = var.tenant_id
}

output "backend_config" {
  description = "Paste into infra/backend.tf"
  value       = <<EOT
resource_group_name  = "${azurerm_resource_group.tfstate.name}"
storage_account_name = "${azurerm_storage_account.tfstate.name}"
container_name       = "${azurerm_storage_container.tfstate.name}"
key                  = "terraform.tfstate"

# --- OIDC ---
use_oidc  = true
client_id = "${azuread_application.github_oidc.application_id}"
EOT
}
