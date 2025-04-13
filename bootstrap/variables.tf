variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
  default     = "f5222e6c-5fc6-48eb-8f03-73db18203b63"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  default     = "bba7ddf1-057e-4d04-afd9-4032cd79dc9d"
}

variable "location" {
  type        = string
  description = "Azure region to deploy resources"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for backend storage"
  default     = "rg-tfstate"
}

variable "github_owner" {
  type        = string
  description = "GitHub organisation / user that owns the repo (e.g. 'my‑org')"
  default     = "devulapallyabinay"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (e.g. 'infra')"
  default     = "terraform-infra"
}
