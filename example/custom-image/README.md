# Custom Atlantis Docker Image

Read through the below before you deploy this module using a custom image.

## Prerequisites

This module expects that you already own or create the below resources yourself.

- Artifact/Container Registry
- Service account [see below](#service-account)

## Using Artifact/Container Registry

When you're storing your own custom Atlantis Docker images in Artifact Registry please note that you have to add the below [`permissions`](#permissions) to your service account.

### Permissions

The `roles/artifactregistry.reader` role should be attached to the service account in order to pull images from Artifact Registry.

## Example

```hcl
module "atlantis" {
  // other attributes ..
  image = "europe-docker.pkg.dev/playground-bruno/docker/atlantis"
}
```
