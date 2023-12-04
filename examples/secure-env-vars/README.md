# Securing sensitive environment variables

This guide explains how to secure environment variables when using the Atlantis module on Google Cloud Platform. For more information on using this module, see the [`basic example`](https://github.com/runatlantis/terraform-gce-atlantis/tree/master/examples/basic).

Additionally, this example uses a GitHub App for authentication, and a custom image entrypoint to set environment variables at container startup time.

- [Prerequisites](#prerequisites)
- [How to deploy](#how-to-deploy)
  - [Important](#important)
- [Setting sensitive environment variables](#setting-sensitive-environment-variables)
- [Setting non sensitive environment variables](#setting-non-sensitive-environment-variables)

## Prerequisites

You should already have the following resources:

- Google network, subnetwork and a Cloud NAT
- Service account, [specifics can be found here](../../README.md#service-account)
- Domain, [specifics can be found here](../../README.md#dns-record)
- The secrets for the GitHub app id, secret, and webhook secret.

If you prefer an example that includes the above resources, see [`complete example`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/complete)

## How to deploy

To deploy the Atlantis module, see [`Dockerfile`](https://github.com/runatlantis/terraform-gce-atlantis/tree/master/examples/secure-env-vars/Dockerfile) and the [`main.tf`](https://github.com/runatlantis/terraform-gce-atlantis/tree/master/examples/secure-env-vars/main.tf).

### Important

- If you bring your own Docker image (not using any Atlantis image as base image), be sure to create an Atlantis user using a uid (user ID) of 100.
- As per Docker spec, the base image's `CMD` will be overridden when you define a new `ENTRYPOINT` through the `command` variable: <https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact>

## Configuring Atlantis

Atlantis allows you to configure everything using environment variables. However, these variables may contain sensitive values, and are therefore visible in the Google Cloud console when deploying a container. To protect these values, follow the steps below.

### Setting sensitive environment variables

Use a wrapper Atlantis Docker image to set environment variables that contain sensitive values. See the following examples for more details:

- [**Cloud Build**: pull secrets from Google Secret Manager](https://github.com/runatlantis/terraform-gce-atlantis/tree/master/examples/secure-env-vars/cloudbuild.yaml)
- [**GitHub Actions**: pull secrets from Google Secret Manager](https://github.com/runatlantis/terraform-gce-atlantis/tree/master/examples/secure-env-vars/.github/workflows/docker-gcp-secrets.yaml)
- [**GitHub Actions**: use GitHub secrets](https://github.com/runatlantis/terraform-gce-atlantis/tree/master/examples/secure-env-vars/.github/workflows/docker-github-secrets.yaml)

You can export sensitive values in the [`custom-entrypoint.sh.tftpl`](custom-entrypoint.sh.tftpl) script, which will be executed as the container entrypoint.
This strategy allow us to use the base Atlantis image, and to export environment variables that do not appear in the Console (e.g. ATLANTIS_GH_WEBHOOK_SECRET).

### Setting non-sensitive environment variables

Use the `var.env_vars` variable to set non-sensitive environment variables.

```hcl
env_vars = {
  ATLANTIS_EXAMPLE = "example"
}
```

> **Important**: Do **not** specify the same environment variable in both the env_vars and the Dockerfile, as this might cause the deployment to fail.

## After it's successfully deployed

Once you're done, see [Configuring Webhooks for Atlantis](https://www.runatlantis.io/docs/configuring-webhooks.html#configuring-webhooks)
