# Example usage

This example uses [scaling schedules](https://cloud.google.com/compute/docs/autoscaler/scaling-schedules#schedule_configuration_options) to only deploy Atlantis during business hours.

The schedules follow the syntax [described in the documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_autoscaler#nested_scaling_schedules), but in short:

- The time zone must be a time zone from the tz database: <http://en.wikipedia.org/wiki/Tz_database>
- The schedule field uses the extended cron format

> [!NOTE]
> It takes 2 to 3 minutes from the beginning of the scheduled time for the instance to be ready to serve requests. After the scheduled end time, it approximately takes 10 minutes for the instance to be destroyed.

Read through the below before you deploy this module.

- [Prerequisites](#prerequisites)
- [How to deploy](#how-to-deploy)
- [After it's successfully deployed](#after-its-successfully-deployed)

## Prerequisites

This module expects that you already own or create the below resources yourself.

- Google network, subnetwork and a Cloud NAT
- Service account, [specifics can be found here](../../README.md#service-account)
- Domain, [specifics can be found here](../../README.md#dns-record)

If you prefer an example that includes the above resources, see [`complete example`](https://github.com/runatlantis/atlantis-on-gcp-vm/tree/master/examples/complete).

## How to deploy

See [`main.tf`](https://github.com/runatlantis/atlantis-on-gcp-vm/tree/master/examples/basic/main.tf) and the [`server-atlantis.yaml`](https://github.com/runatlantis/atlantis-on-gcp-vm/tree/master/examples/basic/server-atlantis.yaml).

## After it's successfully deployed

Once you're done, see [Configuring Webhooks for Atlantis](https://www.runatlantis.io/docs/configuring-webhooks.html#configuring-webhooks)
