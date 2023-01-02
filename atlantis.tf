locals {
  env_vars = [for key, value in var.env_vars : {
    name  = key
    value = value
  }]
}

module "atlantis" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = var.image
    securityContext = {
      privileged : true
    }
    tty : true
    env = local.env_vars
  }
  restart_policy = "Always"
}
