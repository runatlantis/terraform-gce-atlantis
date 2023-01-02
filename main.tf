locals {
  zone = var.zone != null ? var.zone : data.google_compute_zones.available.names[0]
  // The default port that Atlantis runs on is 4141.
  atlantis_port = lookup(var.env_vars, "ATLANTIS_PORT", 4141)
}

data "google_compute_zones" "available" {
  status = "UP"
  region = var.region
}

data "google_compute_image" "cos" {
  family  = "cos-stable"
  project = "cos-cloud"
}

resource "google_compute_disk" "atlantis" {
  name = var.name
  type = "pd-ssd"
  zone = local.zone
  size = 25
}

resource "google_compute_instance_template" "atlantis" {
  # checkov:skip=CKV_GCP_32:Ensure 'Block Project-wide SSH keys' is enabled for VM instances
  name_prefix = "${var.name}-"
  description = "This template is used to create VMs that run Atlantis in a containerized environment using Docker"
  region      = var.region

  tags = ["atlantis"]

  metadata = {
    "gce-container-declaration" = module.atlantis.metadata_value
    "google-logging-enabled"    = true
    "block-project-ssh-keys"    = var.block_project_ssh_keys
  }

  labels = {
    "container-vm" = module.atlantis.vm_container_label
  }

  instance_description = "VM running Atlantis in a containerized environment using Docker"
  machine_type         = var.machine_type
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = var.enable_confidential_compute ? "TERMINATE" : "MIGRATE"
  }

  // Ephemeral OS boot disk
  disk {
    source_image = data.google_compute_image.cos.self_link
    auto_delete  = true
    boot         = true
    disk_type    = "pd-ssd"
    disk_size_gb = 10

    dynamic "disk_encryption_key" {
      for_each = var.disk_kms_key_self_link != null ? [1] : []
      content {
        kms_key_self_link = var.disk_kms_key_self_link
      }
    }
  }

  // Persistent data disk for Atlantis
  disk {
    source      = google_compute_disk.atlantis.name
    boot        = false
    mode        = "READ_WRITE"
    device_name = "atlantis-disk-0"
    auto_delete = false
  }

  network_interface {
    subnetwork = var.subnetwork
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_vtpm                 = true
  }

  confidential_instance_config {
    enable_confidential_compute = var.enable_confidential_compute
  }

  service_account {
    email  = var.service_account.email
    scopes = var.service_account.scopes
  }

  // Instance Templates cannot be updated after creation with the Google Cloud Platform API. 
  // In order to update an Instance Template, Terraform will destroy the existing resource and create a replacement
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "atlantis" {
  name               = var.name
  check_interval_sec = 1
  timeout_sec        = 1

  tcp_health_check {
    port = local.atlantis_port
  }
}

resource "google_compute_instance_group_manager" "atlantis" {
  name               = var.name
  base_instance_name = var.name
  zone               = local.zone
  description        = "Instance group manager responsible for managing the VM running Atlantis in a containerized environment using Docker"

  version {
    instance_template = google_compute_instance_template.atlantis.id
  }

  target_size = 1

  named_port {
    name = "http"
    port = local.atlantis_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.atlantis.id
    initial_delay_sec = 60
  }
}

resource "google_compute_global_address" "atlantis" {
  name = var.name
}

resource "google_compute_managed_ssl_certificate" "atlantis" {
  name = var.name
  managed {
    domains = ["${var.domain}"]
  }
}

resource "google_compute_backend_service" "atlantis" {
  name                  = "${var.name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = "30"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.atlantis.id]

  log_config {
    enable = true
  }

  backend {
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    group           = google_compute_instance_group_manager.atlantis.instance_group
  }
}

resource "google_compute_url_map" "atlantis" {
  name = "${var.name}-map"

  default_service = google_compute_backend_service.atlantis.id

  host_rule {
    hosts        = ["${var.domain}"]
    path_matcher = var.name
  }

  path_matcher {
    name            = var.name
    default_service = google_compute_backend_service.atlantis.id
  }
}

resource "google_compute_url_map" "https_redirect" {
  name = "${var.name}-https-redirect-map"
  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

resource "google_compute_target_http_proxy" "atlantis" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.https_redirect.id
}

resource "google_compute_target_https_proxy" "atlantis" {
  name    = "${var.name}-https-proxy"
  url_map = google_compute_url_map.atlantis.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.atlantis.id,
  ]
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.name}-http-lb"
  target                = google_compute_target_http_proxy.atlantis.id
  port_range            = "80"
  ip_address            = google_compute_global_address.atlantis.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.name}-https-lb"
  target                = google_compute_target_https_proxy.atlantis.id
  port_range            = "443"
  ip_address            = google_compute_global_address.atlantis.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
