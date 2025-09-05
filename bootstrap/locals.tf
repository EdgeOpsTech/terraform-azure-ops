locals {
  common_tags = {
    Environment = var.environment
    Project     = "terraform-bootstrap"
    Owner       = var.github_owner
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }

  # Generate sanitized container names for each repository
  container_names = {
    for repo in var.github_repo : repo => lower(
      replace(
        replace(
          replace(repo, "[^a-zA-Z0-9-]", "-"),
          "--+", "-"
        ),
        "^-|-$", ""
      )
    )
  }
}