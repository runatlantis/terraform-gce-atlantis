# Example usage

Read through the below before you deploy this module.

- [Prerequisites](#prerequisites)
- [How to deploy](#how-to-deploy)
  - [Important](#important)

## Prerequisites

This module expects that you already own or create the below resources yourself.

- Domain, [specifics can be found here](../../README.md#dns-record)

## How to deploy

See [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete/main.tf) and the [`server-atlantis.yaml`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete/server-atlantis.yaml).

### Important

- The [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete/main.tf) contains resources that are set up with only the minimum required attributes to function properly. It is recommended to add additional attributes if you plan to use this in a production environment.
