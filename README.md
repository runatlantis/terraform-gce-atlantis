# Atlantis on Google Compute Engine

This Terraform module deploys various resources to run Atlantis on Google Compute Engine.

- [Feature highlights](#feature-highlights)
- [Prerequisites](#prerequisites)
- [Example Usage](#example-usage)
  - [Basic](examples/basic)
  - [Complete](examples/complete)
  - [Secured Environment Variables](examples/secure-env-vars)
- [How to deploy](#how-to-deploy)
  - [Important](#important)
  - [After it's successfully deployed](#after-its-successfully-deployed)
- [Configuring Atlantis](#configuring-atlantis)
  - [Setting sensitive environment variables](#setting-sensitive-environment-variables)
- [Service Account](#service-account)
  - [Permissions](#permissions)
- [DNS Record](#dns-record)
  - [Example](#example)
- [Identity-Aware Proxy](#identity-aware-proxy)
  - [Enabling IAP](#enabling-iap)
  - [What's exactly protected?](#whats-exactly-protected)
  - [Permissions](#permissions)
- [FAQ](#faq)
- [Requirements](#requirements)

## Feature highlights

- **Container-Optimized OS** - Atlantis runs as a Docker container on a container optimized VM.

- **Managed Instance Group** - The VM instance is part of a MIG (Managed Instance Group), this ensures that Atlantis is always up and running.

- **External HTTPS Load Balancer** - A Layer 7 load balancer is created together with a managed SSL certificate for the provided domain.

- **Identity-Aware Proxy** - The Atlantis UI can be protected by Google Cloud Identity-Aware Proxy, this adds an additional layer of security by requiring users to authenticate with their Google account.

- **Custom port for Atlantis** - This module features the ability to run Atlantis on a custom port, simply set the `ATLANTIS_PORT` environment variable.

- **Separate Persistent Data Disk** - The VM instance has a separate attached persistent data disk attached to it to ensure that Atlantis data is persisted and not lost if the VM is deleted or terminated.

- **Shielded VM** - A Shielded VM is a VM that's hardened by a set of security controls that help defend against rootkits and bootkits. Using a Shielded VM helps protect enterprise workloads from threats like remote attacks, privilege escalation, and malicious insiders.

## Prerequisites

This module expects that you already own or create the below resources yourself.

- Google network, subnetwork and a Cloud NAT
- Service account
- Domain

If you prefer an example that includes the above resources, see [`complete example`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete).

## Example Usage

Here are some examples to choose from. Look at the prerequisites above to find one that is appropriate for your configuration.

- [Basic](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic)
- [Complete](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete)
- [Secure Environment Variables](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/secure-env-vars)

## How to deploy

See [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic/main.tf) and the [`server-atlantis.yaml`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic/server-atlantis.yaml).

### Important

- Provisioning the Google Cloud Managed SSL certificate can take up to 25 minutes after the `terraform apply` has finished.

- If you bring your own Docker image (*not using any Atlantis image as base image*), be sure to create an Atlantis user using a uid (user ID) of 100.

### After it's successfully deployed

Once you're done, see [Configuring Webhooks for Atlantis](https://www.runatlantis.io/docs/configuring-webhooks.html#configuring-webhooks)

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

See [`main.tf`](https://github.com/bschaatsbergen/terraform-gce-atlantis/blob/main/examples/basic/main.tf#L16-L33)

## DNS Record

This example uses Cloud DNS to add an A record containing the load balancer IP address. If you don't use Cloud DNS, please add the A record using the load balancer IP address on the platform where you've registered your domain.

It's a requirement to add the A record to the domain record set in order to sucessfully provision the certificate!

### Example

If you use Cloud DNS and own a managed zone for your domain, use the IP address that's part of the module output to create the A record.

See [`main.tf`](https://github.com/bschaatsbergen/terraform-gce-atlantis/blob/main/examples/basic/main.tf#L60-L71)

## Identity-Aware Proxy

Google Cloud's Identity-Aware Proxy (IAP) is a service that can be used to secure the Atlantis UI by authenticating users with Google Accounts

### Enabling IAP

To enable IAP, you will need to configure the OAuth Consent Screen and create OAuth credentials, as described in the [Enabling IAP](https://cloud.google.com/iap/docs/enabling-compute-howto#enabling_iap_console) guide.

Once you have the OAuth credentials, you can set the `iap` variable to use them.

```hcl
iap = {
  oauth2_client_id    = data.google_secret_manager_secret_version.atlantis_client_id.secret_data
  auth2_client_secret = data.google_secret_manager_secret_version.atlantis_client_secret.secret_data
}
```

### What's exactly protected?

With IAP enabled, all requests to Atlantis will be protected, except for those made to the `/events` path, which is used for webhooks between platforms such as GitHub and BitBucket.

### Permissions

To grant a user access to your IAP-protected Atlantis deployment, you will need to give them the `roles/iap.httpsResourceAccessor` role.

```hcl
resource "google_iap_web_iam_member" "member" {
  project = "<your-project-id>"
  role = "roles/iap.httpsResourceAccessor"
  member = "user:jane@example.com"
}
```

## FAQ

### When sending an HTTP request, I'm receiving an ERR_EMPTY_RESPONSE error

We expect you to use HTTPS because we are not routing or redirecting any HTTP requests.

### My VM experienced an outage and is taking some time to restart

It may take up to three minutes for the Managed Instance Group to safely shut down and recreate the VM before it is considered healthy again.

### Even though terraform apply worked correctly, I'm receiving an ERR_SSL_VERSION_OR_CIPHER_MISMATCH error

This error indicates that the Google Cloud Managed SSL certificate is not yet fully provisioned.
If all configurations are correct, it may take up to 25 minutes for the certificate to be provisioned.
You can check the status of the certificate in the Google Cloud Console.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >=2.2.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >=4.47.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | >=2.2.0 |
| <a name="provider_google"></a> [google](#provider\_google) | >=4.47.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >=3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_container"></a> [container](#module\_container) | terraform-google-modules/container-vm/google | 3.1.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_backend_service.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_backend_service.iap](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_firewall.lb_health_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_global_address.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_global_forwarding_rule.https](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | resource |
| [google_compute_health_check.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_health_check.default_instance_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_instance_group_manager.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager) | resource |
| [google_compute_instance_template.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template) | resource |
| [google_compute_managed_ssl_certificate.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate) | resource |
| [google_compute_route.public_internet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_target_https_proxy.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | resource |
| [google_compute_url_map.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [cloudinit_config.config](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [google_compute_image.cos](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |
| [google_netblock_ip_ranges.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_block_project_ssh_keys_enabled"></a> [block\_project\_ssh\_keys\_enabled](#input\_block\_project\_ssh\_keys\_enabled) | Blocks the use of project-wide publich SSH keys | `bool` | `false` | no |
| <a name="input_disk_kms_key_self_link"></a> [disk\_kms\_key\_self\_link](#input\_disk\_kms\_key\_self\_link) | The self link of the encryption key that is stored in Google Cloud KMS | `string` | `null` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain to associate Atlantis with and to request a managed SSL certificate for. Without `https://` | `string` | n/a | yes |
| <a name="input_enable_oslogin"></a> [enable\_oslogin](#input\_enable\_oslogin) | Enables OS Login service on the VM | `bool` | `false` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | Key-value pairs representing environment variables and their respective values | `map(any)` | n/a | yes |
| <a name="input_iap"></a> [iap](#input\_iap) | Settings for enabling Cloud Identity Aware Proxy to protect the Atlantis UI | <pre>object({<br>    oauth2_client_id     = string<br>    oauth2_client_secret = string<br>  })</pre> | `null` | no |
| <a name="input_image"></a> [image](#input\_image) | Docker image. This is most often a reference to a container located in a container registry | `string` | `"ghcr.io/runatlantis/atlantis:latest"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Key-value pairs representing labels attaching to instance & instance template | `map(any)` | `{}` | no |
| <a name="input_machine_image"></a> [machine\_image](#input\_machine\_image) | The machine image to create VMs with, if not specified, latest cos\_cloud/cos\_stable is used | `string` | `null` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The machine type to run Atlantis on | `string` | `"n2-standard-2"` | no |
| <a name="input_name"></a> [name](#input\_name) | Custom name that's used during resource creation | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Name of the network | `string` | n/a | yes |
| <a name="input_persistent_disk_size_gb"></a> [persistent\_disk\_size\_gb](#input\_persistent\_disk\_size\_gb) | The size of the persistent disk that Atlantis uses to store its data on | `number` | `50` | no |
| <a name="input_project"></a> [project](#input\_project) | The ID of the project in which the resource belongs | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The region that resources should be created in | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Service account to attach to the instance running Atlantis | <pre>object({<br>    email  = string,<br>    scopes = list(string)<br>  })</pre> | <pre>{<br>  "email": "",<br>  "scopes": [<br>    "cloud-platform"<br>  ]<br>}</pre> | no |
| <a name="input_shielded_instance_config"></a> [shielded\_instance\_config](#input\_shielded\_instance\_config) | Shielded VM provides verifiable integrity to prevent against malware and rootkits | <pre>object({<br>    enable_integrity_monitoring = optional(bool)<br>    enable_vtpm                 = optional(bool)<br>    enable_secure_boot          = optional(bool)<br>  })</pre> | <pre>{<br>  "enable_integrity_monitoring": true,<br>  "enable_secure_boot": true,<br>  "enable_vtpm": true<br>}</pre> | no |
| <a name="input_spot_machine_enabled"></a> [spot\_machine\_enabled](#input\_spot\_machine\_enabled) | A Spot VM is discounted Compute Engine capacity that may be preemptively stopped or deleted by Compute Engine if the capacity is needed | `bool` | `false` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | The ssl policy name that certificate must follow | `string` | `null` | no |
| <a name="input_startup_script"></a> [startup\_script](#input\_startup\_script) | A startup script that runs during the boot cycle when you first launch an instance | `string` | `null` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Name of the subnetwork to attach a network interface to | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to attach to the instance running Atlantis | `list(string)` | `[]` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | The zone that instances should be created in | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cos_image_id"></a> [cos\_image\_id](#output\_cos\_image\_id) | The unique identifier of the Container-Optimized OS image used to create the Compute Engine instance. |
| <a name="output_iap_backend_service_name"></a> [iap\_backend\_service\_name](#output\_iap\_backend\_service\_name) | Name of the optional IAP-enabled backend service |
| <a name="output_ip_address"></a> [ip\_address](#output\_ip\_address) | The IPv4 address of the load balancer |
| <a name="output_managed_ssl_certificate_certificate_id"></a> [managed\_ssl\_certificate\_certificate\_id](#output\_managed\_ssl\_certificate\_certificate\_id) | The unique identifier of the Google Managed SSL certificate |
| <a name="output_managed_ssl_certificate_expire_time"></a> [managed\_ssl\_certificate\_expire\_time](#output\_managed\_ssl\_certificate\_expire\_time) | Expire time of the Google Managed SSL certificate |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
