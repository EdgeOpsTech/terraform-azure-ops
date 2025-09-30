variable "location" {
  type        = string
  description = "Azure region to deploy resources"
  # default     = "eastus"  # Old region - not allowed by policy
  default = "westus3" # New allowed region
  validation {
    condition     = length(var.location) > 0
    error_message = "A location must be specified."
  }
}
