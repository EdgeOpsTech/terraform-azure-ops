locals {
  common_tags = {
    Project   = "terraform-bootstrap"
    Owner     = var.github_owner
    ManagedBy = "Terraform"
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
