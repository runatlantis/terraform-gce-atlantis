# Create a service account and attach the required Cloud Logging permissions to it.
resource "google_service_account" "atlantis" {
  account_id   = "atlantis"
  display_name = "Service Account for Atlantis"
}


resource "google_project_iam_member" "atlantis" {
  for_each = set([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/artifactregistry.reader",
  ])
  role    = each.value
  member  = "serviceAccount:${google_service_account.atlantis.email}"
  project = "<your-project-id>"
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
  project = var.project_id
}

module "atlantis" {
  source     = "../../."
  name       = "atlantis"
  image      = "<your-image>" # Your wrapper Atlantis Docker image
  network    = "<your-network>"
  subnetwork = "<your-subnetwork>"
  region     = "<your-region>"
  zone       = "<your-zone>"
  service_account = {
    email  = "<your-service-account-email>"
    scopes = ["cloud-platform"]
  }
  env_vars = {
    ATLANTIS_REPO_ALLOWLIST = "github.com/<your-github-handle>/*"
    ATLANTIS_ATLANTIS_URL   = "https://<your-domain>"
    # the sensitive value will contain an URL in the form of
    # gcp:///<secret-name>. See https://github.com/binxio/gcp-get-secret
    ATLANTIS_GH_USER = "gcp:///atlantis-gh-user"
    ATLANTIS_GH_TOKEN = "gcp:///atlantis-gh-token"
    ATLANTIS_GH_WEBHOOK_SECRET = "gcp:///atlantis-gh-webhook-secret"
  }
  domain = "<your-domain>"
}
