# As your DNS records might be managed at another registrar's site, we create the DNS record outside of the module.
# This record is mandatory in order to provision the managed SSL certificate successfully.
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

module "atlantis" {
  source     = "../."
  name       = "atlantis"
  network    = var.network
  subnetwork = var.subnetwork
  region     = var.region
  zone       = var.zone
  service_account = {
    email  = var.service_account.email
    scopes = ["cloud-platform"]
  }
  # Note: environment variables are shown in the Google Cloud UI
  # See the `examples/secured-env-vars` if you want to protect sensitive information
  env_vars = {
    ATLANTIS_GH_USER           = "myuser"
    ATLANTIS_GH_TOKEN          = "token"
    ATLANTIS_GH_WEBHOOK_SECRET = "secret"
    ATLANTIS_REPO_ALLOWLIST    = "github.com/myorg/*"
    ATLANTIS_ATLANTIS_URL      = "https://atlantis.example.com"
    ATLANTIS_REPO_CONFIG_JSON  = jsonencode(yamldecode(file("${path.module}/server-atlantis.yaml")))
  }
  domain = "atlantis.example.com"
}
