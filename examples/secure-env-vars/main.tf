locals {
  project_id            = "<your-project-id>"
  network               = "<your-network>"
  subnetwork            = "<your-subnetwork>"
  region                = "<your-region>"
  zone                  = "<your-zone>"
  image                 = "<your-image>"
  domain                = "<example.com>"
  managed_zone          = "<your-managed-zone>"

  github_repo_allow_list = "github.com/example/*"
}

# Create a service account and attach the required Cloud Logging permissions to it.
resource "google_service_account" "atlantis" {
  account_id   = "atlantis"
  display_name = "Service Account for Atlantis"
  project      = local.project_id
}

resource "google_project_iam_member" "atlantis_log_writer" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.atlantis.email}"
  project = local.project_id
}

resource "google_project_iam_member" "atlantis_metric_writer" {
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.atlantis.email}"
  project = local.project_id
}

module "atlantis" {
  source     = "bschaatsbergen/atlantis/gce"
  name       = "atlantis"
  image      = local.image # Your wrapper Atlantis Docker image
  network    = local.network
  subnetwork = local.subnetwork
  region     = local.region
  zone       = local.zone
  service_account = {
    email  = google_service_account.atlantis.email
    scopes = ["cloud-platform"]
  }
  # Declare the non-sensitive environment variables here
  # The sensitive environment variables are set in the Dockerfile!
  env_vars = {
    ATLANTIS_REPO_ALLOWLIST = local.github_repo_allow_list
    ATLANTIS_ATLANTIS_URL   = "https://${local.domain}"
  }
  domain  = local.domain
  project = local.project_id
}

# As your DNS records might be managed at another registrar's site, we create the DNS record outside of the module.
# This record is mandatory in order to provision the managed SSL certificate successfully.
resource "google_dns_record_set" "default" {
  name         = "${local.domain}."
  type         = "A"
  ttl          = 60
  managed_zone = local.managed_zone
  rrdatas = [
    module.atlantis.ip_address
  ]
  project = local.project_id
}
