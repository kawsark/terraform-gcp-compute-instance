provider "google" {
  region       = "${var.gcp_region}"
  project      = "${var.gcp_project}"
}

data "google_compute_zones" "available" {
  region = "${var.gcp_region}"
  project = "${var.gcp_project}"
}

data "google_compute_default_service_account" "default" { }

output "default_account" {
  value = "${data.google_compute_default_service_account.default.email}"
}

resource "google_compute_instance" "demo" {
  count        = "${var.server_count}"
  name         = "${var.instance_name}-${count.index}"
  machine_type = "${var.machine_type}"
  zone         = "${data.google_compute_zones.available.names[count.index]}"
  labels       = "${var.labels}"
  tags	       = "${var.tags}"

  boot_disk {
    source = "${element(google_compute_disk.os-disk.*.name, count.index)}"
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  service_account = {
    email =  "${var.use_default_service_account ? "${data.google_compute_default_service_account.default.email}" : "${var.service_account_email}" }"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  allow_stopping_for_update = "true"
 
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
  labels = "${var.labels}"
  size   = "${var.os_pd_ssd_size}"
  zone   = "${data.google_compute_zones.available.names[count.index]}"
}

