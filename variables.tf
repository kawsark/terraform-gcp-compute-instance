variable "server_count" {
  default = 1
}

variable "labels" {
  type = "map"
  default = {
    environment = "demo"
    app = "demo"
    ttl = "48"
    owner= "kawsar"
  }
}

variable "os_pd_ssd_size" {
  description = "Size of OS disk in GB"
  default = "10"
}

variable "gcp_region" {
  description = "GCP region, e.g. us-east1"
  default = "us-east1"
}

variable "gcp_project" {
  description = "Name of GCP project"
}

variable "machine_type" {
  description = "GCP machine type"
  default = "n1-standard-2"
}

variable "instance_name" {
  description = "GCP instance name"
  default = "terraform-demo"
}

variable "image" {
  description = "image to build instance from in the format: image-family/os. See: https://cloud.google.com/compute/docs/images#os-compute-support"
  default = "ubuntu-os-cloud/ubuntu-1404-lts"
}

variable "startup_script" {
  description = "A startup script passed as metadata"
  default = "touch /tmp/default_startup_script"
}

