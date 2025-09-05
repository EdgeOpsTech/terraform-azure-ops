# Azure AD Application for GitHub OIDC
resource "azuread_application" "github_oidc" {
  display_name = "github-${var.github_owner}-terraform"
  owners       = [data.azuread_client_config.current.object_id]

  tags = ["terraform", "github-actions", "oidc"]
}

# Service Principal for the Azure AD Application
resource "azuread_service_principal" "github_oidc" {
  client_id = azuread_application.github_oidc.client_id

  tags = ["terraform", "github-actions", "oidc"]
}

# Federated Identity Credentials for branches
resource "azuread_application_federated_identity_credential" "branches" {
  for_each = {
    for item in flatten([
      for repo in var.github_repo : [
        for branch in var.branches : {
          key    = "${repo}-${branch}"
          repo   = repo
          branch = branch
        } if !can(regex(".*\\*", branch))
      ]
    ]) : item.key => item
  }

  application_id = azuread_application.github_oidc.id
  display_name   = "github-${var.github_owner}-${each.value.repo}-${each.value.branch}"
  description    = "GitHub federated identity for ${each.value.repo} branch ${each.value.branch}"
  subject        = "repo:${var.github_owner}/${each.value.repo}:ref:refs/heads/${each.value.branch}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
}

# Federated Identity Credentials for environments
resource "azuread_application_federated_identity_credential" "environments" {
  for_each = {
    for item in flatten([
      for repo in var.github_repo : [
        for env in var.environments : {
          key = "${repo}-${env}"
          repo = repo
          env  = env
        }
      ]
    ]) : item.key => item
  }

  application_id = azuread_application.github_oidc.id
  display_name   = "github-${var.github_owner}-${each.value.repo}-${each.value.env}"
  description    = "GitHub federated identity for ${each.value.repo} environment ${each.value.env}"
  subject        = "repo:${var.github_owner}/${each.value.repo}:environment:${each.value.env}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
}

# Federated Identity Credentials for pull requests
resource "azuread_application_federated_identity_credential" "pull_request" {
  for_each = var.pull_request ? {
    for repo in var.github_repo : repo => repo
  } : {}

  application_id = azuread_application.github_oidc.id
  display_name   = "github-${var.github_owner}-${each.value}-pr"
  description    = "GitHub federated identity for ${each.value} pull requests"
  subject        = "repo:${var.github_owner}/${each.value}:pull_request"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
}