locals {
  project_id   = "<your-project-id>"
  network      = "<your-network>"
  subnetwork   = "<your-subnetwork>"
  region       = "<your-region>"
  zone         = "<your-zone>"
  domain       = "<example.com>"
  managed_zone = "<your-managed-zone>"

  github_repo_allow_list = "github.com/example/*"

  secret_names = {
    app_id  = "<your_secret_name_for_app_id>"
    app_key = "<your_secret_name_for_app_key>"
    webhook = "<your_secret_name_for_webhook>"
  }
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
  source     = "runatlantis/atlantis/gce"
  name       = "atlantis"
  network    = local.network
  subnetwork = local.subnetwork
  region     = local.region
  zone       = local.zone
  service_account = {
    email  = google_service_account.atlantis.email
    scopes = ["cloud-platform"]
  }

  env_vars = {
    ATLANTIS_REPO_ALLOWLIST   = local.github_repo_allow_list
    ATLANTIS_ATLANTIS_URL     = "https://${local.domain}"
    ATLANTIS_REPO_CONFIG_JSON = jsonencode(yamldecode(file("${path.module}/server-atlantis.yaml")))
    ATLANTIS_WRITE_GIT_CREDS  = "true"
  }
  domain  = local.domain
  project = local.project_id

  image   = "ghcr.io/runatlantis/atlantis:latest"
  command = ["/home/atlantis/custom-entrypoint.sh"]
  args    = ["server"]

  startup_script = templatefile("${path.module}/custom-entrypoint.sh.tftpl", {
    cloud_sdk_version          = "455.0.0"
    app_key_secret_name        = local.secret_names.app_key
    app_id_secret_name         = local.secret_names.app_id
    webhook_secret_secret_name = local.secret_names.webhook
    key_file_path              = "/home/atlantis/gh_app_key.pem"
    mount_folder               = "/mnt/disks/gce-containers-mounts/gce-persistent-disks/atlantis-disk-0"
    entrypoint_filename        = "custom-entrypoint.sh"
  })
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
