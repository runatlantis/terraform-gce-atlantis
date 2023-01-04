# As your DNS records might be managed at another registrar's site, we create the DNS record outside of the module.
# This record is mandatory in order to provision the managed SSL certificate successfully.
resource "google_dns_record_set" "default" {
  name         = "${var.domain}."
  type         = "A"
  ttl          = 60
  managed_zone = "example-com"
  rrdatas = [
    module.atlantis.ip_address
  ]
  project = var.project_id
}

module "atlantis" {
  source     = "../."
  name       = "atlantis"
  image      = var.image # Your wrapper Atlantis Docker image
  subnetwork = var.subnetwork
  region     = var.region
  service_account = {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
  # Declare the non-sensitive environment variables here
  # The sensitive environment variables are set in the Dockerfile!
  env_vars = {
    ATLANTIS_REPO_ALLOWLIST   = "github.com/myorg/*"
    ATLANTIS_ATLANTIS_URL     = "https://${var.domain}"
  }
  domain = var.domain
}
