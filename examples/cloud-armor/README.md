# Example usage

This example deploys Cloud Armor to ensure requests to the default backend are coming from GitHub Webhooks.

Since IAP is enabled, two backend services will be created:

- atlantis: the backend to receive GitHub events, protected with Cloud Armor
- atlantis-iap: the backend to serve the Atlantis UI, protected with IAP

Read through the below before you deploy this module.

- [Prerequisites](#prerequisites)
- [How to deploy](#how-to-deploy)
- [After it's successfully deployed](#after-its-successfully-deployed)

## Prerequisites

This module expects that you already own or create the below resources yourself.

- Google network, subnetwork and a Cloud NAT
- Service account, [specifics can be found here](../../README.md#service-account)
- Domain, [specifics can be found here](../../README.md#dns-record)

If you prefer an example that includes the above resources, see [`complete example`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete).

## How to deploy

See [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic/main.tf) and the [`server-atlantis.yaml`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic/server-atlantis.yaml).

## After it's successfully deployed

Once you're done, see [Configuring Webhooks for Atlantis](https://www.runatlantis.io/docs/configuring-webhooks.html#configuring-webhooks)
