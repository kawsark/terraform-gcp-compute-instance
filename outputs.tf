output "external_ip" {
  value = google_compute_instance.demo[*].network_interface[0].access_config[0].nat_ip
}

output "id" {
  value = google_compute_instance.demo[*].instance_id
}

output "name" {
  value = google_compute_instance.demo[*].name
}