environment = "prod"
# location    = "eastus"
location = "westus3"

# GitHub Configuration
github_owner = "EdgeOpsTech"
github_repo = [
  "terraform-azure-ops",
  "kv-rbac-setup",
  "super-webapp",
  "azure-vm-setup",
  "edgeops-sub-mgmt",
  "edgeops-keyvault-module"
]

branches     = ["main", "dev", "release/*", "feature/*"]
environments = ["dev", "test", "stage", "prod"]
pull_request = true
