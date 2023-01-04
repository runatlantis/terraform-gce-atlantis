# Securing sensitive environment variables

This example only explains how you can protect your environment variables, see the [`basic example`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/basic) for additional context on deploying this Atlantis module.

## Prerequisites

It's expected that you own the below resources already:

- Artifact or Container Registry in Google Cloud.
- CI/CD system that has a secret manager integration (GitHub, Gitlab, Jenkins, Cloud Build, etc).

## How to deploy

See [`Dockerfile`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/secured-env-vars/Dockerfile) and the [`main.tf`](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/secured-env-vars/main.tf).

## Configuring Atlantis

Atlantis offers the ability to configure everything through environment variables.

Unfortunately environment variables are shown in the Google Cloud console when deploying a container, as these might contain sensitive values we should protect them.

### Setting sensitive environment variables

We should pass only the **sensitive** environment variables through a wrapper Atlantis Docker image, see the below detailed examples.

- [**Cloud Build**: pull secrets from Google Secret Manager](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/secured-env-vars/cloudbuild.yaml)
- [**GitHub Actions**: pull secrets from Google Secret Manager](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/secured-env-vars/.github/workflows/docker-gcp-secrets.yaml)
- [**GitHub Actions**: use GitHub secrets](https://github.com/bschaatsbergen/atlantis-on-gcp-vm/tree/master/examples/secured-env-vars/.github/workflows/docker-github-secrets.yaml)

### Setting non-sensitive environment variables

The module exposes a variable: `var.env_vars` where you should only pass any **non-sensitive** environment variables.

```hcl
env_vars = {
  ATLANTIS_EXAMPLE = "example"
}
```

> **Important**: Do **not** specifiy the same environment variable in both the `env_vars` as well as the Dockerfile, this will fail the deployment.
