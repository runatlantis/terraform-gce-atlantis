locals {
  # The default port that Atlantis runs on is 4141, we default to this.
  atlantis_port = lookup(var.env_vars, "ATLANTIS_PORT", 4141)
  # Atlantis' home directory is "/home/atlantis", we default to this.
  atlantis_data_dir             = lookup(var.env_vars, "ATLANTIS_DATA_DIR", "/home/atlantis")
  atlantis_port_name            = "atlantis"
  atlantis_network_traffic_tags = ["atlantis-${random_string.random.result}"]
  atlantis_labels = merge(
    var.labels,
    module.container.container_vm.labels,
    { "vm" = module.container.container_vm.name },
    { "app" = "atlantis" }
  )
}

resource "random_string" "random" {
  length  = 6
  special = false
  lower   = true
  upper   = false
}

data "google_compute_image" "cos" {
  family  = "cos-stable"
  project = "cos-cloud"
}

data "google_netblock_ip_ranges" "this" {
  for_each = toset([
    "health-checkers",
    "legacy-health-checkers",
  ])
  range_type = each.key
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "atlantis-chown-disk.service"
    content_type = "text/cloud-config"
    content = yamlencode({
      write_files = [
        {
          path        = "/etc/systemd/system/atlantis-chown-disk.service"
          permissions = "0644"
          owner       = "root"
          content     = <<EOF
          [Unit]
          Description=Change ownership of the mount path to the Atlantis uid
          Wants=konlet-startup.service
          After=konlet-startup.service
          [Service]
          ExecStart=/bin/chown 100 /mnt/disks/gce-containers-mounts/gce-persistent-disks/atlantis-disk-0
          Restart=on-failure
          RestartSec=30
          StandardOutput=journal+console
          [Install]
          WantedBy=multi-user.target
          EOF
        }
      ]
    })
  }

  part {
    filename     = "runcmda"
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace, recurse_list)+str()"
    content = yamlencode({
      runcmd = [
        "systemctl daemon-reload",
        "systemctl start --no-block atlantis-chown-disk.service"
      ]
    })
  }
}

module "container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "3.1.0"

  container = {
    image = var.image
    securityContext = {
      privileged = false
    }
    tty = true
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

resource "google_compute_instance_template" "default" {
  name_prefix             = "${var.name}-"
  description             = "This template is used to create VMs that run Atlantis in a containerized environment using Docker"
  instance_description    = "VM running Atlantis in a containerized environment using Docker"
  region                  = var.region
  machine_type            = var.machine_type
  can_ip_forward          = false
  metadata_startup_script = var.startup_script

  metadata = {
    gce-container-declaration = module.container.metadata_value
    user-data                 = data.cloudinit_config.config.rendered
    google-logging-enabled    = true
    block-project-ssh-keys    = var.block_project_ssh_keys_enabled
    enable-oslogin            = var.enable_oslogin
  }

  # Using the below scheduling configuration,
  # the managed instance group will recreate the Spot VM if Compute Engine stops them
  scheduling {
    automatic_restart           = var.spot_machine_enabled ? false : true
    preemptible                 = var.spot_machine_enabled ? true : false
    provisioning_model          = var.spot_machine_enabled ? "SPOT" : "STANDARD"
    on_host_maintenance         = var.spot_machine_enabled ? "TERMINATE" : "MIGRATE"
    instance_termination_action = var.spot_machine_enabled ? "STOP" : null
  }

  # Ephemeral OS boot disk
  disk {
    source_image = var.machine_image != null ? var.machine_image : data.google_compute_image.cos.self_link
    auto_delete  = true
    boot         = true
    disk_type    = "pd-ssd"
    disk_size_gb = 10
    labels = merge(
      local.atlantis_labels,
      {
        "disk-type" = "boot"
      },
    )

    dynamic "disk_encryption_key" {
      for_each = var.disk_kms_key_self_link != null ? [1] : []
      content {
        kms_key_self_link = var.disk_kms_key_self_link
      }
    }
  }

  #  Persistent disk for Atlantis
  disk {
    device_name  = "atlantis-disk-0"
    disk_type    = "pd-ssd"
    mode         = "READ_WRITE"
    disk_size_gb = var.persistent_disk_size_gb
    auto_delete  = false
    labels = merge(
      local.atlantis_labels,
      {
        "disk-type" = "data"
      },
    )

    dynamic "disk_encryption_key" {
      for_each = var.disk_kms_key_self_link != null ? [1] : []
      content {
        kms_key_self_link = var.disk_kms_key_self_link
      }
    }
  }

  network_interface {
    subnetwork         = var.subnetwork
    subnetwork_project = var.project
  }

  shielded_instance_config {
    enable_integrity_monitoring = var.shielded_instance_config.enable_integrity_monitoring
    enable_vtpm                 = var.shielded_instance_config.enable_vtpm
    enable_secure_boot          = var.shielded_instance_config.enable_secure_boot
  }

  service_account {
    email  = var.service_account.email
    scopes = var.service_account.scopes
  }

  tags    = concat(local.atlantis_network_traffic_tags, var.tags)
  labels  = local.atlantis_labels
  project = var.project

  # Instance Templates cannot be updated after creation with the Google Cloud Platform API.
  # In order to update an Instance Template, Terraform will destroy the existing resource and create a replacement
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "default" {
  name                = var.name
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 5

  tcp_health_check {
    port = local.atlantis_port
  }

  project = var.project
}

resource "google_compute_health_check" "default_instance_group_manager" {
  name                = "${var.name}-mig"
  healthy_threshold   = 1
  unhealthy_threshold = 10

  http_health_check {
    port         = local.atlantis_port
    request_path = "/healthz"
  }

  project = var.project
}

resource "google_compute_instance_group_manager" "default" {
  name               = var.name
  base_instance_name = var.name
  zone               = var.zone
  description        = "Instance group manager responsible for managing the VM running Atlantis in a containerized environment using Docker"

  version {
    instance_template = google_compute_instance_template.default.id
  }

  all_instances_config {
    labels = local.atlantis_labels
  }

  named_port {
    name = local.atlantis_port_name
    port = local.atlantis_port
  }

  stateful_disk {
    device_name = "atlantis-disk-0"
    delete_rule = "NEVER"
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.default_instance_group_manager.id
    initial_delay_sec = 30
  }

  target_size = 1

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "RESTART"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = 0
    max_unavailable_fixed          = 1
    replacement_method             = "RECREATE"
  }
  project  = var.project
  provider = google-beta
}

resource "google_compute_global_address" "default" {
  name    = var.name
  project = var.project
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = var.name
  managed {
    domains = [var.domain]
  }
  project = var.project
}

resource "google_compute_backend_service" "default" {
  name                            = var.name
  protocol                        = "HTTP"
  port_name                       = local.atlantis_port_name
  timeout_sec                     = 10
  connection_draining_timeout_sec = 5
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  health_checks                   = [google_compute_health_check.default.id]

  log_config {
    enable      = true
    sample_rate = 1
  }

  backend {
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    group           = google_compute_instance_group_manager.default.instance_group
  }
  project = var.project
}

resource "google_compute_backend_service" "iap" {
  count                           = var.iap != null ? 1 : 0
  name                            = "${var.name}-iap"
  protocol                        = "HTTP"
  port_name                       = local.atlantis_port_name
  timeout_sec                     = 10
  connection_draining_timeout_sec = 5
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  health_checks                   = [google_compute_health_check.default.id]

  log_config {
    enable      = true
    sample_rate = 1
  }

  iap {
    oauth2_client_id     = var.iap.oauth2_client_id
    oauth2_client_secret = var.iap.oauth2_client_secret
  }

  backend {
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    group           = google_compute_instance_group_manager.default.instance_group
  }
  project = var.project

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_url_map" "default" {
  name    = var.name
  project = var.project

  # If IAP is not used, use default backend service for unmatched requests
  default_service = var.iap == null ? google_compute_backend_service.default.id : null

  # If IAP is used, redirect unmatched requests to Atlantis domain
  dynamic "default_url_redirect" {
    for_each = var.iap != null ? [1] : []
    content {
      host_redirect          = var.domain
      https_redirect         = true
      redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
      strip_query            = false
    }
  }

  # As Atlantis uses the `/events` path to handle incoming webhook events
  # we shouldn't put it behind IAP, it should be protected using a webhook secret.
  dynamic "host_rule" {
    for_each = var.iap != null ? [1] : []
    content {
      hosts        = [var.domain]
      path_matcher = "public"
    }
  }

  dynamic "path_matcher" {
    for_each = var.iap != null ? [1] : []
    content {
      name            = "public"
      default_service = google_compute_backend_service.iap[0].id
      path_rule {
        paths   = ["/events"]
        service = google_compute_backend_service.default.id
      }

      dynamic "path_rule" {
        for_each = var.expose_metrics_publicly ? [1] : []
        content {
          paths   = ["/metrics"]
          service = google_compute_backend_service.default.id
        }
      }
    }
  }
}

resource "google_compute_target_https_proxy" "default" {
  name    = var.name
  url_map = google_compute_url_map.default.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.id,
  ]
  ssl_policy = var.ssl_policy
  project    = var.project
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = var.name
  target                = google_compute_target_https_proxy.default.id
  port_range            = "443"
  ip_address            = google_compute_global_address.default.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
  project               = var.project
}

# Route public internet traffic to the default internet gateway
resource "google_compute_route" "public_internet" {
  network          = var.network
  name             = "${var.name}-public-internet"
  description      = "Custom static route for Altantis to communicate with the public internet"
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 0
  project          = var.project
  tags             = local.atlantis_network_traffic_tags
}

# This firewall rule allows Google Cloud to issue the health checks
resource "google_compute_firewall" "lb_health_check" {
  name        = "${var.name}-lb-health-checks"
  description = "Firewall rule to allow inbound Google Load Balancer health checks to the Atlantis instance"
  priority    = 0
  direction   = "INGRESS"
  network     = var.network
  allow {
    protocol = "tcp"
  }
  # These are the source IP ranges for health checks (managed by Google Cloud)
  source_ranges = distinct(concat(
    data.google_netblock_ip_ranges.this["health-checkers"].cidr_blocks_ipv4,
    data.google_netblock_ip_ranges.this["legacy-health-checkers"].cidr_blocks_ipv4,
  ))
  project     = var.project
  target_tags = local.atlantis_network_traffic_tags
}
