provider "google" {
  region  = "${var.gcp_region}"
  project = "${var.gcp_project}"
}

module "consul-cluster" {
  source = "./google_compute_instance"
  image  = "${var.image}"

  tags = ["consul-${var.gcp_project}-${var.consul_dc}"]

  labels = {
    environment = "dev"
    app         = "consul"
    ttl         = "24h"
    owner       = "${var.owner}"
  }

  server_count = 3

  gcp_project                 = "${var.gcp_project}"
  gcp_region                  = "${var.gcp_region}"
  instance_name               = "consul"
  use_default_service_account = 0
  service_account_email       = "${data.google_compute_default_service_account.default.email}"
  startup_script              = "${data.template_file.consul_userdata.rendered}"
  os_pd_ssd_size              = "12"
}

module "vault" {
  source = "./google_compute_instance"
  image  = "${var.image}"

  tags = ["consul-${var.gcp_project}-${var.consul_dc}"]

  labels = {
    environment = "dev"
    app         = "vault"
    ttl         = "24h"
    owner       = "${var.owner}"
    sequence    = "${module.consul-cluster.id[2]}"
  }

  server_count = "${var.vault_server_count}"

  gcp_project                 = "${var.gcp_project}"
  gcp_region                  = "${var.gcp_region}"
  instance_name               = "vault"
  use_default_service_account = 0
  service_account_email       = "${data.google_compute_default_service_account.default.email}"
  startup_script              = "${data.template_file.vault_userdata.rendered}"
  os_pd_ssd_size              = "12"
}
