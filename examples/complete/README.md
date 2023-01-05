# Example usage

Read through the below before you deploy this module.

- [Prerequisites](#prerequisites)
- [How to deploy](#how-to-deploy)
  - [Notes](#notes)
- [Configuring Atlantis](#configuring-atlantis)
  - [Setting sensitive environment variables](#setting-sensitive-environment-variables)
- [Service Account](#service-account)
  - [Permissions](#permissions)
- [DNS Record](#dns-record)
  - [Example](#example)

## Prerequisites

This module expects that you already own or create the below resources yourself.

- Domain, [see below](#dns-record)

## How to deploy

See [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete/main.tf) and the [`server-atlantis.yaml`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete/server-atlantis.yaml).

### Notes

- The [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete/main.tf) contains resources that are set up with only the minimum required attributes to function properly. It is recommended to add additional attributes if you plan to use this in a production environment.

- Provisioning the Google Cloud Managed SSL certificate can take up to 25 minutes after the `terraform apply` has finished.

## Configuring Atlantis

Atlantis offers the ability to configure everything through environment variables.

The module exposes a variable: `var.env_vars` where you can pass any environment variable you want.

```hcl
env_vars = {
  ATLANTIS_EXAMPLE = "example"
}
```

For an overview of all possible environment variables, see: [Atlantis Server Configuration](https://www.runatlantis.io/docs/server-configuration.html#flags)

### Setting sensitive environment variables

See [secured environment variables](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/secure-env-vars) for an example on how to deal with sensitive values in environment variables.

## Service Account

As Google recommends custom service accounts and permissions granted via IAM Roles. We advice that you bring your own service account.

Note that you must grant the relevant permissions to your service account yourself, e.g. Storage related permissions for the Terraform state bucket and other permissions in order to create resources through Terraform.

### Permissions

The `roles/logging.logWriter` & `roles/monitoring.metricWriter` roles should be attached to the service account in order to write logs to Cloud Logging and ingest metric data into Cloud Monitoring.

See [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic/main.tf#L2-L17)

## DNS Record

As this module creates an External HTTPS Load Balancer together with a managed SSL certificate for the domain you provided, an A record has to be created for your domain to successfully provision the certificate.

### Example

If you use Cloud DNS and own a managed zone for your domain, use the IP address that's part of the module output to create the A record.

See [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic/main.tf#L43-L54)
