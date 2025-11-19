# Testing Guide

This module does not yet ship with an automated test suite. Terratest coverage would be a natural next step, but until then use the following manual validation flow whenever you touch the Hyperdisk logic.

## 1. Initialize Terraform locally

```sh
terraform init -backend=false
```

This downloads the providers and ensures that `main.tf` parses correctly.

## 2. Verify locals with `terraform console`

The disk-selection logic lives in `locals` and can be evaluated without contacting Google Cloud. Use `terraform console` with ad-hoc variables to confirm the expected disk types:

```sh
# Hyperdisk-only machine (auto-selection should be hyperdisk-balanced)
terraform console -var 'machine_type=c4d-standard-4' <<< 'local.calculated_persistent_disk_type'

# Standard machine (should remain pd-ssd)
terraform console -var 'machine_type=n2-standard-2' <<< 'local.calculated_persistent_disk_type'

# Explicit Hyperdisk override for both boot + persistent disks
terraform console -var 'machine_type=c4d-standard-4' -var 'persistent_disk_type=hyperdisk-extreme' -var 'boot_disk_type=hyperdisk-extreme' <<< 'local.calculated_boot_disk_type'

# Loop through all Hyperdisk-only families if you need extra confidence
for t in c4d-standard-4 h4d-standard-4 x4-standard-4 m4-standard-4 a3-ultragpu-8g a3-megagpu-16g; do
  terraform console -var "machine_type=$t" <<< 'local.calculated_persistent_disk_type'
done
```

## 3. Confirm validation errors

The `persistent_disk_type` variable prevents pairing Hyperdisk-only machine types with `pd-*` disks. Run `terraform plan` with explicit overrides to make sure the validation still fires:

```sh
# Should fail: pd-ssd on a Hyperdisk machine
terraform plan -var 'machine_type=c4d-standard-4' -var 'persistent_disk_type=pd-ssd'

# Should pass: Hyperdisk override
terraform plan -var 'machine_type=c4d-standard-4' -var 'persistent_disk_type=hyperdisk-extreme'

# Should fail: ARM64 machine type
terraform plan -var 'machine_type=c4a-standard-4'
```

Running these steps after any related change ensures the Hyperdisk detection, overrides, and validation logic continue working until a formal automated suite is added.
