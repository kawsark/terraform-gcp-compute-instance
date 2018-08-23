provider "google" {
  # Google project configured via Environment variable: GOOGLE_PROJECT
  credentials = "${var.gcp_credentials}"
  region      = "${var.gcp_region}"
}

resource null_resource "test1" {

}

resource "google_compute_instance" "demo" {
  name         = "${var.instance_name}"
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
 
}

resource "google_compute_disk" "os-disk" {
  name   = "os-disk"
  type   = "pd-ssd"
  image  = "${var.image}"
  labels = "${var.labels}"
  size   = "${var.os_pd_ssd_size}"
  zone   = "${var.gcp_region}-b"
}
