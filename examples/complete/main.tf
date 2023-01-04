provider "google" {
  project = "<your-project-id>"
}

# Create a service account and attach the required Cloud Logging permissions to it.
resource "google_service_account" "atlantis" {
  account_id   = "atlantis-sa"
  display_name = "Service Account for Atlantis"
}

resource "google_project_iam_member" "atlantis_log_writer" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.atlantis.email}"
  project = "<your-project-id>"
}

resource "google_project_iam_member" "atlantis_metric_writer" {
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.atlantis.email}"
  project = "<your-project-id>"
}

resource "google_compute_network" "default" {
  name                    = "example-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name          = "example-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "<your-region>"
  network       = google_compute_network.default.id
}

# Create a router, which we associate the Cloud NAT too
resource "google_compute_router" "default" {
  name    = "example-router"
  region  = google_compute_subnetwork.default.region
  network = google_compute_network.default.name

  bgp {
    asn = 64514
  }
}

# Create a NAT for outbound internet traffic
resource "google_compute_router_nat" "default" {
  name                               = "example-router-nat"
  router                             = google_compute_router.default.name
  region                             = google_compute_router.default.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

module "atlantis" {
  source     = "../../."
  name       = "atlantis"
  network    = google_compute_network.default.name
  subnetwork = google_compute_subnetwork.default.name
  region     = "<your-region>"
  zone       = "<your-zone>"
  service_account = {
    email  = google_service_account.atlantis.email
    scopes = ["cloud-platform"]
  }
  # Note: environment variables are shown in the Google Cloud UI
  # See the `examples/secured-env-vars` if you want to protect sensitive information
  env_vars = {
    ATLANTIS_GH_USER           = "<your-github-user>"
    ATLANTIS_GH_TOKEN          = "<your-github-token>"
    ATLANTIS_GH_WEBHOOK_SECRET = "<your-github-webhook-secret>"
    ATLANTIS_REPO_ALLOWLIST    = "github.com/<your-github-handle>/*"
    ATLANTIS_ATLANTIS_URL      = "https://<your-domain>"
    ATLANTIS_REPO_CONFIG_JSON  = jsonencode(yamldecode(file("${path.module}/server-atlantis.yaml")))
  }
  domain = "<your-domain>"
}

# As your DNS records might be managed at another registrar's site, we create the DNS record outside of the module.
# This record is mandatory in order to provision the managed SSL certificate successfully.
resource "google_dns_record_set" "default" {
  name         = "<your-domain>."
  type         = "A"
  ttl          = 60
  managed_zone = "<your-managed-zone>"
  rrdatas = [
    module.atlantis.ip_address
  ]
}
