# Example instantiation for terraform-gcp-compute-instance as a module
# Using the startup-script Apache HTTPD server and Mysql are installed as systemd services

variable "gcp_credentials" {
  description = "Contents of GCP service account .json file"
}

variable "gcp_project" {
  description = "Name of GCP project"
}

module "gcp-centos-server" {
  source = "github.com/kawsark/terraform-gcp-compute-instance"
  labels  = {
    environment = "example"
    app = "example"
    ttl = "24h"
  } 
  gcp_credentials="${var.gcp_credentials}"
  gcp_project="${var.gcp_project}"
  gcp_region="us-east1"
  instance_name="centos-server-example"
  startup_script_file_path="centos-lamp.sh"
  image="centos-cloud/centos-7"
  os_pd_ssd_size = "12"
}
