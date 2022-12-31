# Example usage

Read through the below before you deploy this module.

## Prerequisites

This module expects that you already own or create the below resources yourself.

- Domain
- Google network and subnetwork
- Service account

## How to deploy

See [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/example/main.tf) and the [`server-atlantis.yaml`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/example/server-atlantis.yaml).


## Configuring Atlantis

Atlantis offers the ability to configure everything through environment variables.

This module exposes a variable: `var.env_vars` where you can pass any environment variable you need.

```hcl
env_vars = [
    {
      name  = "ATLANTIS_EXAMPLE"
      value = "example"
    }
  ]
```

For an overview of all possible environment variables, see: [Atlantis Server Configuration](https://www.runatlantis.io/docs/server-configuration.html#flags)

## Service Account

As Google recommends custom service accounts and permissions granted via IAM Roles. We decided that you must bring your own service account.

Note that you must grant the relevant permissions to your service account yourself, e.g. Storage related permissions for the Terraform state bucket and other permissions in order to create resources through Terraform.

### Important

The `roles/logging.logWriter` role should be attached to the service account in order to write logs to Cloud Logging.

### Example

```hcl
resource "google_service_account" "atlantis" {
  account_id   = "atlantis-sa"
  display_name = "Service Account for Atlantis"
  project      = var.project_id
}

resource "google_project_iam_member" "atlantis_log_writer" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.atlantis.email}"
  project = var.project_id
}
```

## DNS Record

As this module creates an External HTTPS Load Balancer together with a managed SSL certificate for the domain you provided, an A record has to be created for your domain to successfully provision the certificate.

### Example

If you use Cloud DNS and own a managed zone for your domain, use the IP address that's part of the module output to create the A record.

```hcl
resource "google_dns_record_set" "default" {
  name         = "atlantis.example.com."
  type         = "A"
  ttl          = 60
  managed_zone = "example-com"
  rrdatas = [
    module.atlantis.ip_address
  ]
  project = var.project_id
}
```
