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
  }
  restart_policy = "Always"
}
