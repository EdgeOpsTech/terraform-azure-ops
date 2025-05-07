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

provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "edgeopstechtfstate"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  for_each              = toset(var.github_repo)
  name                  = lower(replace(replace(replace(each.key, "[^a-zA-Z0-9-]", "-"), "--+", "-"), "^-|-$", ""))
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}


data "azuread_client_config" "current" {}

resource "azuread_application" "github_oidc" {
  display_name = "github-${var.github_owner}-terraform"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "github_oidc" {
  client_id = azuread_application.github_oidc.client_id
}
# Add Federated Identity Credentials for GitHub Actions
# resource "azuread_application_federated_identity_credential" "github" {
#   application_id = azuread_application.github_oidc.id # ✅ NEW: replaces deprecated `application_object_id`
#   display_name   = "github-actions"
#   issuer         = "https://token.actions.githubusercontent.com"
#   subject        = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main"
#   audiences      = ["api://AzureADTokenExchange"]
# }

# resource "azuread_application_federated_identity_credential" "github-production" {
#   application_id = azuread_application.github_oidc.id # ✅ NEW: replaces deprecated `application_object_id`
#   display_name   = "github-actions-production"
#   issuer         = "https://token.actions.githubusercontent.com"
#   subject        = "repo:${var.github_owner}/${var.github_repo}:environment:production"
#   audiences      = ["api://AzureADTokenExchange"]
# }

# resource "azuread_application_federated_identity_credential" "github_prs" {
#   application_id = azuread_application.github_oidc.id
#   display_name   = "github-actions-pull-requests"

#   issuer    = "https://token.actions.githubusercontent.com"
#   subject   = "repo:EdgeOpsTech/terraform-azure-ops:pull_request"
#   audiences = ["api://AzureADTokenExchange"]
# }

# resource "azuread_application_federated_identity_credential" "github_prs-production" {
#   application_id = azuread_application.github_oidc.id
#   display_name   = "github-actions-pull-requests-production"

#   issuer    = "https://token.actions.githubusercontent.com"
#   subject   = "repo:EdgeOpsTech/terraform-azure-ops:pull_request:environment:production"
#   audiences = ["api://AzureADTokenExchange"]
# }

# resource "azuread_application_federated_identity_credential" "branches" {
#   for_each       = toset(var.branches)
#   application_id = azuread_application.github_oidc.id
#   display_name   = "github-${var.github_owner}.${var.github_repo}-${each.value}"
#   description    = "GitHub federated identity credentials"
#   subject        = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${each.value}"
#   audiences      = ["api://AzureADTokenExchange"]
#   issuer         = "https://token.actions.githubusercontent.com"
# }

# resource "azuread_application_federated_identity_credential" "tags" {
#   for_each       = toset(var.tags)
#   application_id = "/applications/${azuread_application.this.object_id}"
#   display_name   = "github-${var.github_organization_name}.${var.github_repository_name}-${each.value}"
#   description    = "GitHub federated identity credentials"
#   subject        = "repo:${var.github_organization_name}/${var.github_repository_name}:ref:refs/tags/${each.value}"
#   audiences      = ["api://AzureADTokenExchange"]
#   issuer         = "https://token.actions.githubusercontent.com"
# }

# resource "azuread_application_federated_identity_credential" "environments" {
#   for_each       = toset(var.environments)
#   application_id = azuread_application.github_oidc.id
#   display_name   = "github-${var.github_owner}.${var.github_repo}-${each.value}"
#   description    = "GitHub federated identity credentials"
#   subject        = "repo:${var.github_owner}/${var.github_repo}:environment:${each.value}"
#   audiences      = ["api://AzureADTokenExchange"]
#   issuer         = "https://token.actions.githubusercontent.com"
# }

# resource "azuread_application_federated_identity_credential" "pull_request" {
#   count          = var.pull_request ? 1 : 0
#   application_id = azuread_application.github_oidc.id
#   display_name   = "github-${var.github_owner}.${var.github_repo}-pr"
#   description    = "GitHub federated identity credentials"
#   subject        = "repo:${var.github_owner}/${var.github_repo}:pull_request"
#   audiences      = ["api://AzureADTokenExchange"]
#   issuer         = "https://token.actions.githubusercontent.com"
# }

# 🔁 Exact branch federated identities for each repo
resource "azuread_application_federated_identity_credential" "branches" {
  for_each = {
    for repo in var.github_repo :
    repo => flatten([
      for branch in var.branches :
      can(regex(".*\\*", branch)) ? [] : [{
        repo   = repo
        branch = branch
      }]
    ])
  }

  application_id = azuread_application.github_oidc.id
  display_name   = "github-${var.github_owner}.${each.key}-${each.value[0].branch}"
  description    = "GitHub federated identity for branch ${each.value[0].branch}"
  subject        = "repo:${var.github_owner}/${each.key}:ref:refs/heads/${each.value[0].branch}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
}


# 🔁 Environments
resource "azuread_application_federated_identity_credential" "environments" {
  for_each = {
    for repo in var.github_repo :
    "${repo}-${join("-", var.environments)}" => {
      repo         = repo
      environments = var.environments
    }
  }

  application_id = azuread_application.github_oidc.id
  display_name   = "github-${var.github_owner}.${each.value.repo}-${each.value.environments[0]}"
  description    = "GitHub federated identity for environment ${each.value.environments[0]}"
  subject        = "repo:${var.github_owner}/${each.value.repo}:environment:${each.value.environments[0]}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
}

# 🔁 Pull request federated identity per repo
resource "azuread_application_federated_identity_credential" "pull_request" {
  for_each = var.pull_request ? {
    for repo in var.github_repo : repo => repo
  } : {}

  application_id = azuread_application.github_oidc.id
  display_name   = "github-${var.github_owner}.${each.value}-pr"
  description    = "GitHub federated identity for pull_request"
  subject        = "repo:${var.github_owner}/${each.value}:pull_request"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
}


data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "sub_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_oidc.id
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_oidc.id
}

resource "azurerm_role_assignment" "rbac_assigner" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.github_oidc.id
}


output "arm_client_id" {
  description = "Set this as the GitHub secret ARM_CLIENT_ID"
  value       = azuread_application.github_oidc.client_id
}

output "arm_subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "arm_tenant_id" {
  value = var.tenant_id
}

output "backend_config" {
  value = join("\n\n", [
    for repo in var.github_repo : <<EOT
resource_group_name  = "${azurerm_resource_group.tfstate.name}"
storage_account_name = "${azurerm_storage_account.tfstate.name}"
container_name       = "${azurerm_storage_container.tfstate[repo].name}"
# key                  = "terraform-${repo}.tfstate"
key                  = "terraform.tfstate"

use_oidc  = true
client_id = "${azuread_application.github_oidc.client_id}"
EOT
  ])
}

