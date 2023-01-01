module "atlantis" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = var.image
    securityContext = {
      privileged : true
    }
    tty : true
    env = var.env_vars
  }
  restart_policy = "Always"
}
