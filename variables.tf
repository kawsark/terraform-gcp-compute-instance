# Required variables
variable "gcp_project" {
  description = "GCP project name"
}

# Optional variables
variable "os_pd_ssd_size" {
  description = "Size of OS disk in GB"
  default     = "10"
}

variable "gcp_region" {
  description = "GCP region, e.g. us-east1"
  default     = "us-east1"
}

variable "machine_type" {
  description = "GCP machine type"
  default     = "n1-standard-1"
}

variable "instance_name" {
  description = "GCP instance name"
  default     = "demo-gitlab"
}

variable "image" {
  description = "image to build instance from in the format: image-family/os. See: https://cloud.google.com/compute/docs/images#os-compute-support"
  default     = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable "startup_script" {
  description = "A startup script passed as metadata"
  default     = "touch /tmp/created_by_terraform"
}

variable "labels" {
  type = map(string)
  default = {
    owner       = "demouser"
    environment = "demo"
    app         = "demo"
    ttl         = "24"
  }
}

variable "num_of_servers" {
  description = "Adjust the qty. of servers and associated OS disks created"
  default     = 1
}
