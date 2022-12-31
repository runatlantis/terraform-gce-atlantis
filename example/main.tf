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
  source     = "bschaatsbergen/atlantis-on-gce"
  name       = "atlantis"
  subnetwork = google_compute_network.default.name
  region     = google_compute_subnetwork.default.name
  service_account = {
    email  = google_service_account.atlantis.email
    scopes = ["cloud-platform"]
  }
  env_vars = [
    {
      name  = "ATLANTIS_GH_USER"
      value = "myuser"
    },
    {
      name  = "ATLANTIS_GH_TOKEN"
      value = "token"
    },
    {
      name  = "ATLANTIS_GH_WEBHOOK_SECRET"
      value = "secret"
    },
    {
      name  = "ATLANTIS_REPO_ALLOWLIST"
      value = "github.com/myorg/*"
    },
    {
      name  = "ATLANTIS_ATLANTIS_URL"
      value = "https://atlantis.example.com"
    },
    {
      name  = "ATLANTIS_REPO_CONFIG_JSON"
      value = jsonencode(yamldecode(file("server-atlantis.yaml")))
    }
  ]
  domain     = "atlantis.example.com"
  project_id = var.project_id
}
