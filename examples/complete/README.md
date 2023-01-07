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
- [Identity-Aware Proxy](#identity-aware-proxy)
  - [Permissions](#permissions)

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

This example uses Cloud DNS to add an A record containing the load balancer IP address. If you don't use Cloud DNS, please add the A record using the load balancer IP address on the platform where you've registered your domain.

It's a requirement to add the A record to the domain record set in order to sucessfully provision the certificate!

### Example

If you use Cloud DNS and own a managed zone for your domain, use the IP address that's part of the module output to create the A record.

See [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic/main.tf#L43-L54)

## Identity-Aware Proxy

The Atlantis UI can be secured using Google Cloud's Identity-Aware Proxy (IAP) service, which authenticates users with Google Accounts.

### Enabling IAP

Protecting Atlantis using Identity-Aware Proxy is very simple.

Before you begin:

- Configure the OAuth Consent Screen
- Create OAuth credentials

See [Enabling IAP](https://cloud.google.com/iap/docs/enabling-compute-howto#enabling_iap_console) on how to do this.

Once you have the OAuth credentials. you simply have to set the `iap` variable.

```hcl
iap = {
  oauth2_client_id    = data.google_secret_manager_secret_version.atlantis_client_id.secret_data
  auth2_client_secret = data.google_secret_manager_secret_version.atlantis_client_secret.secret_data
}
```

### What's exactly protected?

When `iap` is set, a secondary IAP protected backend is created to handle all requests except those made to the `/events` path. The `/events` path is used to set up webhooks between platforms such as GitHub, BitBucket, and Atlantis.

In short, everything is protected by IAP besides the `/events` path.

### Permissions

To grant a user access to your IAP protected Atlantis deployment, ensure that the principal (Google Account user) has the `roles/iap.httpsResourceAccessor` role attached to it.

```hcl
resource "google_iap_web_iam_member" "member" {
  project = "<your-project-id>
  role = "roles/iap.httpsResourceAccessor"
  member = "user:jane@example.com"
}
```
