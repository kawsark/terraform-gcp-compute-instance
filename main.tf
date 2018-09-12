provider "google" {
  region       = "${var.gcp_region}"
  credentials  = "${var.gcp_credentials}"
  project      = "${var.gcp_project}"
}

data "template_file" "startup_script" {
  template = "${file(var.startup_script_file_path)}"
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
 
  metadata_startup_script = "${data.template_file.startup_script.rendered}"
}

resource "random_string" "random-identifier" {
  length = 4
  special = false
  upper = false
  lower = true
  number = true
}

resource "google_compute_disk" "os-disk" {
  name   = "os-disk-${random_string.random-identifier}"
  type   = "pd-ssd"
  image  = "${var.image}"
  labels = "${var.labels}"
  size   = "${var.os_pd_ssd_size}"
  zone   = "${var.gcp_region}-b"
}
