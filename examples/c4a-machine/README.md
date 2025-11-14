# C4A Hyperdisk example

This example shows how to run Atlantis on a Hyperdisk-only machine type (`c4a-standard-4`). Hyperdisk is mandatory for the C4A, C4D, H4D, X4, M4, A4X, A4, A3 Ultra, and A3 Mega series, and the module now auto-detects those families to set the correct disk types.

- [Prerequisites](#prerequisites)
- [Hyperdisk auto-detection](#hyperdisk-auto-detection)
- [Explicit override scenario](#explicit-override-scenario)
- [How to deploy](#how-to-deploy)

## Prerequisites

Before deploying this example you still need the same shared infrastructure as the [basic example](../basic/README.md):

- Google network, subnetwork and Cloud NAT
- A service account with the logging/monitoring roles described in the [main README](../../README.md#service-account)
- A Cloud DNS managed zone (or another provider where you can add the A record described in [DNS Record](../../README.md#dns-record))

## Hyperdisk auto-detection

`examples/c4a-machine/main.tf` sets `machine_type = "c4a-standard-4"` and leaves the disk type inputs unset. The module automatically selects `hyperdisk-balanced` for both the boot and persistent disks whenever it sees a Hyperdisk-only series, so no additional configuration is necessary for the most common setup.

## Explicit override scenario

You can override either disk independently when you need a different Hyperdisk flavor. Set `persistent_disk_type` or `boot_disk_type` to any Hyperdisk value (for example `hyperdisk-extreme`) and validation will ensure you never choose an incompatible `pd-*` disk for these machine families:

```hcl
module "atlantis" {
  # ...
  machine_type         = "c4a-standard-4"
  persistent_disk_type = "hyperdisk-extreme"
  boot_disk_type       = "hyperdisk-balanced"
}
```

## How to deploy

Review [`main.tf`](./main.tf) and [`server-atlantis.yaml`](./server-atlantis.yaml), then run Terraform from this directory:

```sh
terraform init
terraform apply
```

After the infrastructure is up, follow the upstream instructions for [Configuring Webhooks for Atlantis](https://www.runatlantis.io/docs/configuring-webhooks.html#configuring-webhooks).
