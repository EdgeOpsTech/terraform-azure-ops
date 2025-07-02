variable "location" {
  type        = string
  description = "Azure region to deploy resources"
  default     = "eastus"
  validation {
    condition     = length(var.location) > 0
    error_message = "A location must be specified."
  }
}
