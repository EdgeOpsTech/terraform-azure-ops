# ──────────────────────────────────────────────
# Put your real infrastructure here.
# The workflows you posted already run:
#   terraform init   (uses OIDC → ARM_USE_OIDC=true)
#   terraform plan
#   terraform apply (on main)
# ──────────────────────────────────────────────

# Example resource to prove it works
resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "eastus"
}
# input resource group name
