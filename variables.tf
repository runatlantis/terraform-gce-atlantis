variable "name" {
  type        = string
  description = "Custom name that's used during resource creation"
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
  default     = null
}

variable "machine_type" {
  type        = string
  description = "The machine type to run Atlantis on"
  default     = "n2-standard-2"
}

variable "disk_kms_key_self_link" {
  type        = string
  description = "The self link of the encryption key that is stored in Google Cloud KMS"
  default     = null
}

variable "enable_confidential_compute" {
  type        = bool
  description = "Defines whether the instance should have confidential compute enabled"
  default     = false
}

variable "image" {
  type        = string
  description = "Docker image. This is most often a reference to a container located in a container registry."
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

variable "domain" {
  type        = string
  description = "Domain to associate Atlantis with and to request a managed SSL certificate for"
}

variable "block_project_ssh_keys" {
  type        = bool
  description = "Blocks the use of project-wide publich SSH keys"
  default     = false
}
