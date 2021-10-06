# Example instantiation for terraform-gcp-compute-instance as a module
# Using the startup-script Apache HTTPD server and Mysql are installed as systemd services

provider "google" {
  region = var.gcp_region
}

variable "source_ranges" {
  description = "IP Ranges(s) to open up for Firewall rule, replace with your IP addresses"
  default     = ["1.1.1.1/32"]
}

variable "vault_source_ranges" {
  description = "IP Ranges(s) to open up for Firewall rule on port 8200, replace with your IP addresses of TFC, CI/CD Workper etc."
  default     = ["1.1.1.1/32"]
}

variable "gcp_project" {
  description = "Name of GCP project"
}

variable "machine_type" {
  default = "n1-standard-1"
}

variable "gcp_region" {
  default = "us-east1"
}

variable "network_name" {
  default = "default"
}

data "template_file" "startup_script" {
  template = file("${path.module}/docker-compose.sh.tpl")
  vars = {
    public_key = tls_private_key.pem.public_key_openssh
  }
}

resource "tls_private_key" "pem" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

module "docker-compose-server" {
  #  source = "github.com/kawsark/terraform-gcp-compute-instance"
  source = "../../"
  labels = {
    environment = "dev"
    app         = "vault"
    ttl         = "24"
    owner       = "kawsar-at-hashicorp"
    donotdelete = "True"
  }
  gcp_project    = var.gcp_project
  gcp_region     = var.gcp_region
  instance_name  = "docker-compose-server"
  machine_type   = var.machine_type
  startup_script = data.template_file.startup_script.rendered
  image          = "ubuntu-os-cloud/ubuntu-1804-lts"
  os_pd_ssd_size = "50"
}

output "external_ip" {
  value = module.docker-compose-server.external_ip
}

output "id" {
  value = module.docker-compose-server.id
}

output "name" {
  value = module.docker-compose-server.name
}

output "private_key" {
  value       = tls_private_key.pem.private_key_pem
  description = "The private key for logging onto the server"
  sensitive   = true
}

# Firewall rule for full access from developer workstations
resource "google_compute_firewall" "dev_workstation_rules" {
  project     = var.gcp_project
  name        = "dev-firewall-rule"
  network     = var.network_name
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol = "all"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  source_ranges = var.source_ranges

}

# Firewall rule for external Vault server access from TFC, CI/CD systems etc.
resource "google_compute_firewall" "vault_rules" {
  project     = var.gcp_project
  name        = "vault-firewall-rule"
  network     = var.network_name
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol = "tcp"
    ports    = ["8200", "8201"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  source_ranges = var.vault_source_ranges

}
