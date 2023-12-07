variable "name" {
  type        = string
  description = "Custom name that's used during resource creation"
}

variable "network" {
  type        = string
  description = "Name of the network"
}

variable "subnetwork" {
  type        = string
  description = "Name of the subnetwork to attach a network interface to"
}

variable "region" {
  type        = string
  description = "The region that resources should be created in"
}

variable "zone" {
  type        = string
  description = "The zone that instances should be created in"
}

variable "machine_image" {
  type        = string
  description = "The machine image to create VMs with, if not specified, latest cos_cloud/cos_stable is used"
  default     = null
}

variable "machine_type" {
  type        = string
  description = "The machine type to run Atlantis on"
  default     = "n2-standard-2"
}

variable "persistent_disk_size_gb" {
  type        = number
  description = "The size of the persistent disk that Atlantis uses to store its data on"
  default     = 50
}

variable "spot_machine_enabled" {
  type        = bool
  description = "A Spot VM is discounted Compute Engine capacity that may be preemptively stopped or deleted by Compute Engine if the capacity is needed"
  default     = false
}

variable "startup_script" {
  type        = string
  description = "A startup script that runs during the boot cycle when you first launch an instance"
  default     = null
}

variable "disk_kms_key_self_link" {
  type        = string
  description = "The self link of the encryption key that is stored in Google Cloud KMS"
  default     = null
}

variable "image" {
  type        = string
  description = "Docker image. This is most often a reference to a container located in a container registry"
  default     = "ghcr.io/runatlantis/atlantis:latest"
}

variable "env_vars" {
  type        = map(any)
  description = "Key-value pairs representing environment variables and their respective values"
}

variable "service_account" {
  type = object({
    email  = string,
    scopes = list(string)
  })
  description = "Service account to attach to the instance running Atlantis"
  default = {
    email  = ""
    scopes = ["cloud-platform"]
  }
}

variable "shielded_instance_config" {
  type = object({
    enable_integrity_monitoring = optional(bool)
    enable_vtpm                 = optional(bool)
    enable_secure_boot          = optional(bool)
  })
  description = "Shielded VM provides verifiable integrity to prevent against malware and rootkits"
  default = {
    enable_integrity_monitoring = true
    enable_vtpm                 = true
    enable_secure_boot          = true
  }
}

variable "domain" {
  type        = string
  description = "Domain to associate Atlantis with and to request a managed SSL certificate for. Without `https://`"
}

variable "block_project_ssh_keys_enabled" {
  type        = bool
  description = "Blocks the use of project-wide publich SSH keys"
  default     = false
}

variable "enable_oslogin" {
  type        = bool
  description = "Enables OS Login service on the VM"
  default     = false
}

variable "iap" {
  type = object({
    oauth2_client_id     = string
    oauth2_client_secret = string
  })
  description = "Settings for enabling Cloud Identity Aware Proxy to protect the Atlantis UI"
  default     = null
}

variable "ssl_policy" {
  type        = string
  description = "The SSL policy name that the certificate must follow"
  default     = null
}

variable "tags" {
  type        = list(string)
  description = "Tags to attach to the instance running Atlantis"
  default     = []
}

variable "project" {
  type        = string
  description = "The ID of the project in which the resource belongs"
  default     = null
}

variable "expose_metrics_publicly" {
  type        = bool
  description = "Exposes the /metrics endpoint publicly even if Atlantis is protected by IAP"
  default     = false
}

variable "google_logging_enabled" {
  type        = bool
  description = "Enable Google Cloud Logging"
  default     = true
}

variable "google_logging_use_fluentbit" {
  type        = bool
  description = "Enable Google Cloud Logging using Fluent Bit"
  default     = false
}

variable "google_monitoring_enabled" {
  type        = bool
  description = "Enable Google Cloud Monitoring"
  default     = true
}

variable "labels" {
  type        = map(any)
  description = "Key-value pairs representing labels attaching to instance & instance template"
  default     = {}
}

variable "default_backend_security_policy" {
  type        = string
  description = "Name of the security policy to apply to the default backend service"
  default     = null
}

variable "iap_backend_security_policy" {
  type        = string
  description = "Name of the security policy to apply to the IAP backend service"
  default     = null
}
