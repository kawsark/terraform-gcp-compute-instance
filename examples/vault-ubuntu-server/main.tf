# Example instantiation for terraform-gcp-compute-instance as a module
# Using the startup-script Apache HTTPD server and Mysql are installed as systemd services

variable "gcp_credentials" {
  description = "Contents of GCP service account .json file"
}

variable "gcp_project" {
  description = "Name of GCP project"
}

variable "vault_version" {
  description = "Version of Vault binary to download"
  default = "0.11.1" 
}

variable "consul_version" {
  description = "Version of Consul binary to download"
  default = "1.2.2"
}

data "template_file" "startup_script" {
  template = "${file("${path.module}/vault-consul.sh.tpl")}"
  vars{
	CONSUL_VERSION = "${var.consul_version}"
	VAULT_VERSION = "${var.vault_version}"
  }
}

module "gcp-ubuntu-server" {
  source = "github.com/kawsark/terraform-gcp-compute-instance"
  labels  = {
    environment = "dev"
    app = "vault"
    ttl = "24h"
  } 
  gcp_credentials="${var.gcp_credentials}"
  gcp_project="${var.gcp_project}"
  gcp_region="us-east1"
  instance_name="vault-ubuntu-server"
  startup_script = "${data.template_file.startup_script.rendered}"
  image="ubuntu-os-cloud/ubuntu-1604-lts"
  os_pd_ssd_size = "12"
}
