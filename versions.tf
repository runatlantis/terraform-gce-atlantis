terraform {
  required_version = ">= 0.13.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=4.47.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">=2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.4.3"
    }
  }
}
