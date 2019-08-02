provider "google" {
  region       = "${var.gcp_region}"
  project      = "${var.gcp_project}"
}

resource "google_compute_instance" "demo" {
  count        = "${var.server_count}"
  name         = "${var.instance_name}-${count.index}"
  machine_type = "${var.machine_type}"
  zone         = "${var.gcp_region}-b"
  labels       = "${var.labels}"

  boot_disk {
    source = "${element(google_compute_disk.os-disk.*.name, count.index)}"
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
 
  metadata_startup_script = "${var.startup_script}"
}

resource "random_string" "random-identifier" {
  length = 4
  special = false
  upper = false
  lower = true
  number = true
}

resource "google_compute_disk" "os-disk" {
  count  = "${var.server_count}"
  name   = "os-disk-${random_string.random-identifier.result}-${count.index}"
  type   = "pd-ssd"
  image  = "${var.image}"
  #labels = "${var.labels}"
  size   = "${var.os_pd_ssd_size}"
  zone   = "${var.gcp_region}-b"
}

