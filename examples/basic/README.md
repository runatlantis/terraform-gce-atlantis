# Example usage

Read through the below before you deploy this module.

- [Prerequisites](#prerequisites)
- [How to deploy](#how-to-deploy)
  - [Important](#important)

## Prerequisites

This module expects that you already own or create the below resources yourself.

- Google network, subnetwork and a Cloud NAT
- Service account, [specifics can be found here](../../README.md#service-account)
- Domain, [specifics can be found here](../../README.md#dns-record)

If you prefer an example that includes the above resources, see [`complete example`](https://github.com/runatlantis/terraform-gce-atlantis/tree/master/examples/complete).

## How to deploy

See [`main.tf`](https://github.com/runatlantis/terraform-gce-atlantis/tree/master/examples/basic/main.tf) and the [`server-atlantis.yaml`](https://github.com/runatlantis/terraform-gce-atlantis/tree/master/examples/basic/server-atlantis.yaml).

## After it's successfully deployed

Once you're done, see [Configuring Webhooks for Atlantis](https://www.runatlantis.io/docs/configuring-webhooks.html#configuring-webhooks)
