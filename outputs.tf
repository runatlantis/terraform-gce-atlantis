output "ip_address" {
  value       = google_compute_global_address.default.address
  description = "The IPv4 address of the load balancer"
}

output "cos_image_id" {
  value       = data.google_compute_image.cos.image_id
  description = "The unique identifier of the Container-Optimized OS image used to create the Compute Engine instance."
}

output "managed_ssl_certificate_certificate_id" {
  value       = google_compute_managed_ssl_certificate.default.certificate_id
  description = "The unique identifier of the Google Managed SSL certificate"
}

output "managed_ssl_certificate_expire_time" {
  value       = google_compute_managed_ssl_certificate.default.expire_time
  description = "Expire time of the Google Managed SSL certificate"
}
