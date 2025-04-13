variable "location" {
  type    = string
  default = "eastus"
}

variable "github_owner" {
  description = "GitHub organization or owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}
