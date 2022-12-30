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

variable "env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Contains a list of key-value pairs representing environment variables and their respective values"
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

variable "project_id" {
  type        = string
  description = "The ID of the project in which the resource belongs"
}

variable "domain" {
  type        = string
  description = "Domain to associate Atlantis with and to request a managed SSL certificate for"
}


variable "pull_latest_prerelease" {
  type        = bool
  description = "Whether to pull the latest prerelease of Atlantis or not"
  default     = false
}
