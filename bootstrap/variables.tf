# Core Configuration
variable "environment" {
  description = "Environment name (dev, test, stage, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, stage, prod."
  }
}

# Azure Configuration
variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
  default     = "f5222e6c-5fc6-48eb-8f03-73db18203b63"
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  default     = "bba7ddf1-057e-4d04-afd9-4032cd79dc9d"
  sensitive   = true
}

variable "location" {
  type        = string
  description = "Azure region to deploy resources"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for terraform state"
  default     = "rg-tfstate"
}

variable "storage_account_name" {
  description = "Name of the storage account for terraform state"
  type        = string
  default     = "edgeopstechtfstate"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

# GitHub Configuration
variable "github_owner" {
  type        = string
  description = "GitHub organization or user name"
  default     = "EdgeOpsTech"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$", var.github_owner))
    error_message = "GitHub owner must be a valid GitHub username or organization name."
  }
}

variable "github_repo" {
  type        = list(string)
  description = "List of GitHub repositories for OIDC access"
  default     = ["terraform-azure-ops", "kv-rbac-setup", "super-webapp", "azure-vm-setup", "edgeops-sub-mgmt", "edgeops-keyvault-module"]

  validation {
    condition     = length(var.github_repo) > 0
    error_message = "At least one GitHub repository must be specified."
  }
}

variable "branches" {
  description = "List of GitHub branches for federated credentials"
  type        = list(string)
  default     = ["main", "dev", "feature/*", "release/*"]
}

variable "environments" {
  description = "List of GitHub environments for federated credentials"
  type        = list(string)
  default     = ["dev", "test", "stage", "prod"]
}

variable "pull_request" {
  description = "Add the 'pull request' subject identifier?"
  type        = bool
  default     = true
}
