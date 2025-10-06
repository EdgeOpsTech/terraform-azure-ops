variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
  default     = "f5222e6c-5fc6-48eb-8f03-73db18203b63"
  validation {
    condition     = length(var.tenant_id) > 0
    error_message = "A tenant_id must be specified."
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  default     = "bba7ddf1-057e-4d04-afd9-4032cd79dc9d"
  validation {
    condition     = length(var.subscription_id) > 0
    error_message = "A subscription_id must be specified."
  }
}

variable "location" {
  type        = string
  description = "Azure region to deploy resources"
  default     = "eastus"
  validation {
    condition     = length(var.location) > 0
    error_message = "A location must be specified."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for backend storage"
  default     = "rg-tfstate"
  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "A resource_group_name must be specified."
  }
}

variable "github_owner" {
  type        = string
  description = "GitHub organisation / user that owns the repo (e.g. 'my‑org')"
  default     = "EdgeOpsTech"
  validation {
    condition     = length(var.github_owner) > 0
    error_message = "A github_owner must be specified."
  }
}

variable "github_repo" {
  type        = list(string)
  description = "GitHub repository name (e.g. 'infra')"
  default     = ["terraform-azure-ops", "kv-rbac-setup", "super-webapp", "azure-vm-setup", "edgeops-sub-mgmt", "edgeops-keyvault-module"]
  validation {
    condition     = length(var.github_repo) > 0
    error_message = "At least one GitHub repository must be specified."
  }
}

variable "branches" {
  description = "List of git branches to add as subject identifiers"
  type        = list(string)
  default     = ["main", "feature/*"]
  validation {
    condition     = length(var.branches) > 0
    error_message = "At least one branch must be specified."
  }
}

# variable "tags" {
#   description = "List of git tags to add as subject identifiers"
#   type        = list(string)
#   default     = []
# }

variable "environments" {
  description = "List of GitHub environments to add as subject identifiers"
  type        = list(string)
  default     = ["dev"]
}

variable "pull_request" {
  description = "Add the 'pull request' subject identifier?"
  type        = bool
  default     = true
}
// Add dummy variable to test git commit
