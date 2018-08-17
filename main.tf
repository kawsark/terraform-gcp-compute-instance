variable "labels" {
  type = "map"
  default = {
    environment = "demo"
    app = "demo"
    ttl = "24h"
  }
}

variable "gcp_region" {
  description = "GCP region, e.g. us-east1"
  default = "us-east1"
}

variable "machine_type" {
  description = "GCP machine type"
  default = "n1-standard-1"
}

variable "instance_name" {
  description = "GCP instance name"
  default = "demo"
}

variable "image" {
  description = "image to build instance from in the format: image-family/os. See: https://cloud.google.com/compute/docs/images#os-compute-support"
  default = "ubuntu-os-cloud/ubuntu-1404-lts"
}

variable "startup_script_file_path" {
  description = "A startup script passed as metadata"
  default = "startup-script.sh"
}

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
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }
 
  metadata_startup_script = "${data.template_file.startup_script.rendered}"
}

output "external_ip"{
  value = "${google_compute_instance.demo.network_interface.0.access_config.0.assigned_nat_ip}"
}
