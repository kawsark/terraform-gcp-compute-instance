provider "google" {
  region       = "${var.gcp_region}"
  credentials  = "${var.gcp_credentials}"
  project      = "${var.gcp_project}"
}

resource "google_compute_instance" "demo" {
  count        = "${var.server_count}"
  name         = "${var.instance_name}-${count.index}"
  machine_type = "${var.machine_type}"
  zone         = "${var.gcp_region}-b"
  labels       = "${var.labels}"

  boot_disk {
    source = "${google_compute_disk.os-disk.name}"
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
 
  metadata_startup_script = "${var.startup_script}"
}

resource "google_compute_instance" "demo2" {
  count        = "${var.server_count}"
  name         = "${var.instance_name}-demo2"
  machine_type = "${var.machine_type}"
  zone         = "${var.gcp_region}-b"
  labels       = "${var.labels}"

  boot_disk {
    source = "${google_compute_disk.os-disk2.name}"
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
  name   = "os-disk-${random_string.random-identifier.result}"
  type   = "pd-ssd"
  image  = "${var.image}"
  labels = "${var.labels}"
  size   = "${var.os_pd_ssd_size}"
  zone   = "${var.gcp_region}-b"
}


resource "google_compute_disk" "os-disk2" {
  name   = "os-disk-${random_string.random-identifier.result}-demo2"
  type   = "pd-ssd"
  image  = "${var.image}"
  labels = "${var.labels}"
  size   = "${var.os_pd_ssd_size}"
  zone   = "${var.gcp_region}-b"
}
