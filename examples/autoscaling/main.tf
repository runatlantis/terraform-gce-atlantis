locals {
  project_id   = "<your-project-id>"
  network      = "<your-network>"
  subnetwork   = "<your-subnetwork>"
  region       = "<your-region>"
  zone         = "<your-zone>"
  domain       = "<example.com>"
  managed_zone = "<your-managed-zone>"

  github_repo_allow_list = "github.com/example/*"
  github_user            = "<your-github-handle>"
  github_token           = "<your-github-user>"
  github_webhook_secret  = "<your-github-webhook-secret>"
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
  network    = local.network
  subnetwork = local.subnetwork
  region     = local.region
  zone       = local.zone
  service_account = {
    email  = google_service_account.atlantis.email
    scopes = ["cloud-platform"]
  }
  # Note: environment variables are shown in the Google Cloud UI
  # See the `examples/secure-env-vars` if you want to protect sensitive information
  env_vars = {
    ATLANTIS_GH_USER           = local.github_user
    ATLANTIS_GH_TOKEN          = local.github_token
    ATLANTIS_GH_WEBHOOK_SECRET = local.github_webhook_secret
    ATLANTIS_REPO_ALLOWLIST    = local.github_repo_allow_list
    ATLANTIS_ATLANTIS_URL      = "https://${local.domain}"
    ATLANTIS_REPO_CONFIG_JSON  = jsonencode(yamldecode(file("${path.module}/server-atlantis.yaml")))
  }

  autoscaling = {
    schedules = [
      # Monday through Friday, between 7h30 and 19h30
      {
        name         = "business-hours"
        description  = "Deploy during business hours"
        schedule     = "30 07 * * 1-5"
        time_zone    = "Europe/London"
        duration_sec = 12 * 60 * 60
      },
      # Monday through Friday, all day
      # {
      #   name                  = "mon-fri"
      #   description           = "Deploy during weekdays"
      #   schedule              = "00 00 * * 1-5"
      #   time_zone             = "Europe/London"
      #   duration_sec          = 24 * 60 * 60
      # },
    ]
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
