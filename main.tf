provider "google" {
  # Google provider configured via Environment variables: GOOGLE_CREDENTIALS, GOOGLE_PROJECT and Terraform variable: TF_VAR_gcp_region
  region      = "${var.gcp_region}"
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

resource "google_compute_disk" "os-disk" {
  name   = "os-disk"
  type   = "pd-ssd"
  image  = "${var.image}"
  labels = "${var.labels}"
  size   = "${var.os_pd_ssd_size}"
}
