# Using IAP to gate access to Atlantis

This guide explains how to use IAP to gate access to your Atlantis deployment. For more information on this module, see [`basic example`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic). For more on IAP specifically, see the [`Google docs on IAP`](https://cloud.google.com/iap/docs/concepts-overview).

Note that only internal org IAP clients can be created via Terraform. External clients must be manually created via the GCP console. This is due to a current restriction in the Google API.

- [Prerequisites](#prerequisites)
- [How to deploy](#how-to-deploy)
  - [Important](#important)

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
