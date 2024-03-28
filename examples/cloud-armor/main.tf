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

  google_iap_brand_name = "<brand-name>"
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
  domain  = local.domain
  project = local.project_id

  default_backend_security_policy = google_compute_security_policy.atlantis.name
  iap_backend_security_policy     = google_compute_security_policy.atlantis_iap.name

  iap = {
    oauth2_client_id     = google_iap_client.atlantis.client_id
    oauth2_client_secret = google_iap_client.atlantis.secret
  }
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

resource "google_compute_security_policy" "atlantis" {
  name        = "atlantis-security-policy"
  description = "Policy blocking all traffic except from Github Webhooks"
  project     = local.project_id

  rule {
    # Allow from GitHub Webhooks
    # https://api.github.com/meta
    action      = "allow"
    priority    = "2"
    description = "Rule: Allow github hooks"
    match {
      expr {
        expression = "(inIpRange(origin.ip, '140.82.112.0/20') || inIpRange(origin.ip, '185.199.108.0/22') || inIpRange(origin.ip, '143.55.64.0/20') || inIpRange(origin.ip, '192.30.252.0/22'))"
      }
    }
  }

  rule {
    # Deny all by default
    action      = "deny(403)"
    priority    = "2147483647"
    description = "Default rule: deny all"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  rule {
    # Log4j vulnerability
    action      = "deny(403)"
    priority    = "1"
    description = "CVE-2021-44228 (https://nvd.nist.gov/vuln/detail/CVE-2021-44228)"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('cve-canary')"
      }
    }
  }
}

# This policy allows you to restrict access to the UI from anywhere but say
# your VPN exits, etc.
resource "google_compute_security_policy" "atlantis_iap" {
  name        = "atlantis-iap-security-policy"
  description = "Policy blocking all traffic except from example range"
  project     = local.project_id

  rule {
    # Allow from sample range, eg 192.168.0.0/16
    action      = "allow"
    priority    = "2"
    description = "Allow from sample CIDR"
    match {
      expr {
        expression = "(inIpRange(origin.ip, '192.168.0.0/16'))"
      }
    }
  }

  rule {
    # Deny all by default
    action      = "deny(403)"
    priority    = "2147483647"
    description = "Default rule: deny all"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  rule {
    # Log4j vulnerability
    action      = "deny(403)"
    priority    = "1"
    description = "CVE-2021-44228 (https://nvd.nist.gov/vuln/detail/CVE-2021-44228)"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('cve-canary')"
      }
    }
  }
}

resource "google_iap_client" "atlantis" {
  display_name = "iap-client"
  brand        = local.google_iap_brand_name
}
