# Example instantiation for terraform-gcp-compute-instance as a module
# Using the startup-script Apache HTTPD server and Mysql are installed as systemd services

variable "gcp_project" {
  description = "Name of GCP project"
}

data "template_file" "startup_script" {
  template = file("${path.module}/microk8s.sh.tpl")
  vars = {
    public_key = tls_private_key.pem.public_key_openssh
  }
}

resource "tls_private_key" "pem" {
  algorithm   = "RSA"
  rsa_bits = "2048"
}

module "microk8s-server" {
  #  source = "github.com/kawsark/terraform-gcp-compute-instance"
  source = "../../"
  labels = {
    environment = "dev"
    app         = "microk8s"
    ttl         = "24"
    owner       = "kawsar-at-hashicorp"
  }
  gcp_project    = var.gcp_project
  gcp_region     = "us-east1"
  instance_name  = "microk8s-server"
  startup_script = data.template_file.startup_script.rendered
  image          = "ubuntu-os-cloud/ubuntu-1804-lts"
  os_pd_ssd_size = "20"
}

output "external_ip" {
  value = module.microk8s-server.external_ip
}

output "id" {
  value = module.microk8s-server.id
}

output "name" {
  value = module.microk8s-server.name
}

output "private_key" {
  value = tls_private_key.pem.private_key_pem
  description = "The private key for logging onto the server"
  sensitive   = true
}

