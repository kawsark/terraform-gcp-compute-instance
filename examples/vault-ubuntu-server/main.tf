# Example instantiation for terraform-gcp-compute-instance as a module
# Using the startup-script Apache HTTPD server and Mysql are installed as systemd services

variable "gcp_credentials" {
  description = "Contents of GCP service account .json file"
}

variable "gcp_project" {
  description = "Name of GCP project"
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
  startup_script_file_path="vault-consul.sh"
  image="ubuntu-os-cloud/ubuntu-1604-lts"
  os_pd_ssd_size = "12"
}
