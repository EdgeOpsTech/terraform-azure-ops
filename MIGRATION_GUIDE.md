# Split Terraform State per Environment on Azure Blob (without recreating resources)

This guide explains how to take an existing **single** Terraform state on Azure Blob Storage (e.g., `bootstrap.tfstate`) and split it into **multiple environment-specific states** (e.g., `bootstrap-dev.tfstate`, `bootstrap-test.tfstate`, `bootstrap-stage.tfstate`, `bootstrap-prod.tfstate`) **without destroying or recreating any resources**.

> **Key idea:** We are only moving and editing **state mappings**. Terraform resources in Azure/Entra are left untouched.

---

## Prerequisites

* Terraform ≥ **1.6**
* Backend is **AzureRM** (Azure Blob Storage)
* You can authenticate to your storage account (OIDC or service principal)
* You have access to the existing, working backend **key** (e.g., `bootstrap.tfstate`)

---

## Repository Layout (example)

```
backend/
  bootstrap-old.tfbackend        # points to the old state key (bootstrap.tfstate)
  bootstrap-dev.tfbackend        # points to new dev state key
  bootstrap-test.tfbackend       # points to new test state key
  bootstrap-stage.tfbackend      # points to new stage state key
  bootstrap-prod.tfbackend       # points to new prod state key
```

All files use the **same** `resource_group_name`, `storage_account_name`, and `container_name`. Only the `key` differs.

**Example `backend/bootstrap-old.tfbackend`:**

```hcl
resource_group_name  = "rg-tfstate"
storage_account_name = "edgeopstechtfstate"
container_name       = "terraform-azure-ops"
key                  = "bootstrap.tfstate"          # <- the big, current state
use_oidc             = true
```

**Example `backend/bootstrap-dev.tfbackend`:**

```hcl
resource_group_name  = "rg-tfstate"
storage_account_name = "edgeopstechtfstate"
container_name       = "terraform-azure-ops"
key                  = "bootstrap-dev.tfstate"      # <- new state per env
use_oidc             = true
```

> Repeat for **test**, **stage**, **prod** changing only the `key`.

---

## Step 0 – Make the backend block generic (optional but recommended)

In your Terraform code, you can keep the backend block **empty** so you don’t hardcode the key in code:

```hcl
terraform {
  required_version = ">= 1.6"
  backend "azurerm" {}
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.117" }
    azuread = { source = "hashicorp/azuread", version = "~> 2.50" }
    random  = { source = "hashicorp/random",  version = "~> 3.6" }
  }
}
```

You’ll pass `-backend-config=backend/…` at `terraform init` time. If you prefer hardcoding the old key, you **must** still use `-reconfigure` when switching to a new key.

---

## Step 1 – Attach to the **old** state and back it up

> Goal: Prove you’re reading the large, correct state; then export a backup.

```bash
# from the Terraform working directory
rm -rf .terraform
terraform init -reconfigure -backend-config=backend/bootstrap-old.tfbackend

# SANITY CHECK: you MUST see real resources
terraform state list

# BACKUP: this should be roughly the same size as the blob in the portal
terraform state pull > bootstrap-full-backup.tfstate
ls -lh bootstrap-full-backup.tfstate
```

If `terraform state list` is empty here, you are **not** attached to the right backend—fix `backend/bootstrap-old.tfbackend` and retry.

---

## Step 2 – Seed the **Dev** state from the backup

Attach to the new `dev` backend and seed the state.

**Option A — Interactive migrate** (copy on prompt):

```bash
terraform init -reconfigure -backend-config=backend/bootstrap-dev.tfbackend
# When prompted: "Copy existing state to the new backend?" → answer: yes
terraform state list          # should now show your resources
```

**Option B — Non‑interactive (pull → push):**

```bash
terraform init -reconfigure -backend-config=backend/bootstrap-dev.tfbackend
terraform state push -force bootstrap-full-backup.tfstate
terraform state list
```

In the Azure Portal, the size of `bootstrap-dev.tfstate` should now be similar to the old file (not a tiny 180 B).

---

## Step 3 – Repeat seeding for **Test** / **Stage** / **Prod**

For each environment:

```bash
terraform init -reconfigure -backend-config=backend/bootstrap-<env>.tfbackend
terraform state push -force bootstrap-full-backup.tfstate  # or do interactive migrate
terraform state list
```

At this point, **each** env state key contains the **same** full state (safe starting point).

---

## Step 4 – Trim each env state to only its own resources (optional)

If the original single state contains multiple environments mixed together, you can prune each new env’s state down to only that env’s resources. This does **not** delete resources in Azure; it only removes entries from the state file.

> Run these while attached to the **target env** backend.

### Example: Keep only `dev`-scoped resources + shared bootstrap

Inspect what belongs to dev:

```bash
terraform state list | grep '\["dev"\]'  # addresses tagged with ["dev"]
```

Remove all non‑dev entries (and skip `data.*` which don’t need pruning):

```bash
terraform state list \
  | grep -Ev '^\s*$|^data\.|(\["dev"\])|^azurerm_resource_group\.tfstate$|^azurerm_storage_account\.tfstate$|^azurerm_storage_container\.tfstate' \
  | xargs -n1 terraform state rm
```

> Adjust the keep-list to match your repo (e.g., keep certain shared containers like `azurerm_storage_container.tfstate["terraform-azure-ops"]`).

Repeat for **test**, **stage**, and **prod**, changing the filter to `\["test"\]`, `\["stage"\]`, or `\["prod"\]`.

**Important:** If a shared/global resource (e.g., one storage account) should live in **only one** state, keep it in a single env (or create a separate `bootstrap-global.tfstate`) and `state rm` it from the others.

---

## Step 5 – Lock your day‑to‑day workflow

Two common patterns:

**A. Backend via files (recommended):**

* Keep `terraform { backend "azurerm" {} }` in code.
* For each env workspace/dir/branch, run:

  ```bash
  terraform init -reconfigure -backend-config=backend/bootstrap-dev.tfbackend
  ```

**B. Hardcode per env (if you maintain separate folders/modules):**

* Hardcode the correct `key` per env in each folder’s backend block.

Either way, the **only** difference per env is the `key` value.

---

## Verification Checklist

* After seeding a new env key, `terraform state list` shows resources
* Portal shows blob size comparable to the old state
* `terraform plan` in each env shows **no recreations** (only drift, if any)

---

## Troubleshooting

**New state file is tiny / empty**

* You initialized a new backend key without migrating. Use interactive migrate (Step 2A) or push the backup (Step 2B).

**`terraform state pull` produced a tiny backup**

* You were attached to an empty backend when you pulled. Re‑attach to the old backend with `-reconfigure`, verify with `state list`, then pull again.

**`terraform state list` is empty after init**

* Wrong backend settings (RG, account, container, key). Fix the `.tfbackend` file and re‑run `init -reconfigure`.

**Accidentally removed too much with `state rm`**

* Restore from the backup: reattach to the env backend and `terraform state push -force bootstrap-full-backup.tfstate` (or a per‑env backup you took before pruning).

**AzureRM backend caching weirdness**

* Always include `-reconfigure` when switching `-backend-config` files to ignore cached `.terraform/` values.

---

## Safe Rollback

If anything goes wrong:

```bash
# Reattach to the target env backend
terraform init -reconfigure -backend-config=backend/bootstrap-dev.tfbackend
# Restore from the full backup you created in Step 1
terraform state push -force bootstrap-full-backup.tfstate
```

Take a fresh `state pull` after rollback to confirm integrity.

---

## FAQ

**Q: Does this destroy or recreate anything?**
**A:** No. `state push`/`state rm` operate on Terraform’s state mapping only; cloud resources remain as-is. Only a subsequent `terraform apply` could change resources, and your plan should show no re‑creations if addresses still map correctly.

**Q: Why not use Terraform Workspaces?**
**A:** Workspaces append the workspace name to the key and are fine for simple isolation. For stricter separation (IAM, CI/CD, different subscriptions), explicit backend **keys per env** are clearer and safer.

**Q: Can I script all of this?**
**A:** Yes—wrap Steps 1–4 in a shell script. Prefer the **pull → push** method for non‑interactive runs.

---

## Example One‑Liners

**Seed dev from old backup:**

```bash
terraform init -reconfigure -backend-config=backend/bootstrap-dev.tfbackend \
&& terraform state push -force bootstrap-full-backup.tfstate \
&& terraform state list
```

**Trim dev to only dev + shared:**

```bash
terraform state list \
  | grep -Ev '^\s*$|^data\.|(\["dev"\])|^azurerm_resource_group\.tfstate$|^azurerm_storage_account\.tfstate$|^azurerm_storage_container\.tfstate' \
  | xargs -n1 terraform state rm
```

**Re‑seed if you made a mistake:**

```bash
terraform state push -force bootstrap-full-backup.tfstate
```

---

## Done ✅

You now have separate Azure Blob state files per environment, migrated from a single source, with **zero** resource recreation. Keep your backend keys isolated and use `-reconfigure` whenever you switch envs.
