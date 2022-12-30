output "ip_address" {
  value       = google_compute_global_address.atlantis.address
  description = "The IPv4 address of the load balancer"
}
