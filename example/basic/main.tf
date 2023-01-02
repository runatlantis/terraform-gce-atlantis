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
  subnetwork = google_compute_network.default.name
  region     = google_compute_subnetwork.default.name
  service_account = {
    email  = google_service_account.atlantis.email
    scopes = ["cloud-platform"]
  }
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
