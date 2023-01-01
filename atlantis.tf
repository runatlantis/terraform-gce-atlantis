locals {
  image_tag = var.pull_latest_prerelease ? "prerelease-latest" : "latest"
}

module "atlantis" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = "ghcr.io/runatlantis/atlantis:${local.image_tag}"
    securityContext = {
      privileged : true
    }
    tty : true
    env = var.env_vars

    # Declare volumes to be mounted.
    # This is similar to how docker volumes are declared.
    volumeMounts = [
      {
        mountPath = "/example/dir"
        name      = "atlantis-disk-0"
        readOnly  = false
      },
    ]
  }

  volumes = [
    {
      name = "atlantis-disk-0"

      gcePersistentDisk = {
        pdName = "atlantis-disk-0"
        fsType = "ext4"
      }
    },
  ]

  restart_policy = "Always"
}
