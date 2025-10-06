environment = "test"
# location    = "eastus"
location = "westus3"

# GitHub Configuration
github_owner = "EdgeOpsTech"
github_repo = [
  "terraform-azure-ops",
  "super-webapp",
  "azure-vm-setup",
  "edgeops-sub-mgmt",
  "edgeops-keyvault-module",
  "edgeops-automation-utils"
]


branches     = ["main", "dev", "feature/*"]
environments = ["dev", "test"]
pull_request = true
