locals {
  zone = var.zone != null ? var.zone : data.google_compute_zones.available.names[0]
  // The default port that Atlantis runs on is 4141.
  atlantis_port = lookup(var.env_vars, "ATLANTIS_PORT", 4141)
  // Atlantis its home directory is "/home/atlantis".
  atlantis_data_dir = lookup(var.env_vars, "ATLANTIS_DATA_DIR", "/home/atlantis")
  port_name         = "atlantis"
}

data "google_compute_zones" "available" {
  status = "UP"
  region = var.region
}

data "google_compute_image" "cos" {
  family  = "cos-stable"
  project = "cos-cloud"
}

resource "google_compute_instance_template" "atlantis" {
  # checkov:skip=CKV_GCP_32:Ensure 'Block Project-wide SSH keys' is enabled for VM instances
  name_prefix = "${var.name}-"
  description = "This template is used to create VMs that run Atlantis in a containerized environment using Docker"
  region      = var.region

  tags = ["atlantis"]

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", { disk_name = "atlantis-disk-0" })

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

  // Using the below scheduling configuration,
  // the managed instance group will recreate the Spot VM if Compute Engine stops them
  scheduling {
    automatic_restart           = var.use_spot_machine ? false : true
    preemptible                 = var.use_spot_machine ? true : false
    provisioning_model          = var.use_spot_machine ? "SPOT" : "STANDARD"
    on_host_maintenance         = var.use_spot_machine ? "TERMINATE" : "MIGRATE"
    instance_termination_action = var.use_spot_machine ? "STOP" : null
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

  // Persistent disk for Atlantis
  disk {
    device_name  = "atlantis-disk-0"
    disk_type    = "pd-ssd"
    mode         = "READ_WRITE"
    disk_size_gb = var.persistent_disk_size_gb
    auto_delete  = false

    dynamic "disk_encryption_key" {
      for_each = var.disk_kms_key_self_link != null ? [1] : []
      content {
        kms_key_self_link = var.disk_kms_key_self_link
      }
    }
  }

  network_interface {
    subnetwork = var.subnetwork
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_vtpm                 = true
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

module "atlantis" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = var.image
    securityContext = {
      privileged : true
    }
    tty : true
    env = [for key, value in var.env_vars : {
      name  = key
      value = value
    }]

    # Declare volumes to be mounted.
    # This is similar to how docker volumes are declared.
    volumeMounts = [
      {
        mountPath = local.atlantis_data_dir
        name      = "atlantis-disk-0"
        readOnly  = false
      },
    ]
  }

  volumes = [
    {
      name = "atlantis-disk-0"

      gcePersistentDisk = {
        pdName = "atlantis-disk-0"
        fsType = "ext4"
      }
    },
  ]

  restart_policy = "Always"
}

resource "google_compute_health_check" "atlantis" {
  name                = var.name
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 4
  unhealthy_threshold = 5

  tcp_health_check {
    port_name          = local.port_name
    port_specification = "USE_NAMED_PORT"
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
    name = local.port_name
    port = local.atlantis_port
  }

  stateful_disk {
    device_name = "atlantis-disk-0"
    delete_rule = "NEVER"
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.atlantis.id
    initial_delay_sec = 60
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = 0
    max_unavailable_fixed          = 5
    replacement_method             = "RECREATE"
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
  name                  = var.name
  protocol              = "HTTP"
  port_name             = local.port_name
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
  name            = var.name
  default_service = google_compute_backend_service.atlantis.id
}

resource "google_compute_target_https_proxy" "atlantis" {
  name    = var.name
  url_map = google_compute_url_map.atlantis.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.atlantis.id,
  ]
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = var.name
  target                = google_compute_target_https_proxy.atlantis.id
  port_range            = "443"
  ip_address            = google_compute_global_address.atlantis.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
