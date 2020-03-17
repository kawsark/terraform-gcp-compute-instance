provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

data "google_compute_zones" "available" {
  region  = var.gcp_region
  project = var.gcp_project
}

resource "google_compute_instance" "demo" {
  name         = format("%s-%s-%d", var.instance_name, random_string.random-identifier.result, count.index)
  count        = var.num_of_servers
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available.names[count.index]
  labels       = var.labels
  allow_stopping_for_update = true

  boot_disk {
    source = google_compute_disk.os-disk[count.index].name
    auto_delete = false
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

   metadata_startup_script = var.startup_script
}

resource "random_string" "random-identifier" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  number  = true
}

resource "google_compute_disk" "os-disk" {
  count  = var.num_of_servers
  name   = format("os-disk-%s-%d", random_string.random-identifier.result, count.index)
  type   = "pd-ssd"
  image  = var.image
  labels = var.labels
  size   = var.os_pd_ssd_size
  zone   = data.google_compute_zones.available.names[count.index]
}

