variable "gcp_project" {
  description = "Name of GCP project"
}

variable "gcp_region" {
  description = "region"
  default     = "us-east1"
}

variable "vault_license" {
  description = "Optionally enter a Vault Enterprise license here. Relevant when using enterprise vault_url."
  default     = "asdf"
}

variable "consul_license" {
  description = "Optionally enter a Consul Enterprise license here. Relevant when using enterprise consul_url."
  default     = "asdf"
}

variable "vault_url" {
  description = "enter a Vault download URL here"
  default     = "https://releases.hashicorp.com/vault/1.2.2/vault_1.2.2_linux_amd64.zip"
}

variable "consul_url" {
  description = "enter a Consul download URL here"
  default     = "https://releases.hashicorp.com/consul/1.5.3/consul_1.5.3_linux_amd64.zip"
}

variable "image" {
  description = "An OS image to provision: https://cloud.google.com/compute/docs/images#os-compute-support"
  default     = "ubuntu-os-cloud/ubuntu-1604-lts"
}

variable "owner" {
  default = "demouser"
}

variable "consul_dc" {
  default = "us-east1"
}

variable "consul_server_count" {
  default = 3
}

variable "vault_server_count" {
  default = 2
}

variable "environment" {
  default = "lab"
}

# TLS related variables
variable "common_name" {
  description = "A CN for CA and generated certificates"
  default     = "therealk.com"
}

variable "organization_name" {
  description = "A OU for CA and generated certificates"
  default     = "research"
}

# KMS related variables
variable "key_ring" {
  description = "Existing Cloud KMS key ring name for auto unseal"
  default     = "gcp-vault-unseal"
}

variable "crypto_key" {
  description = "Key in Cloud KMS key ring for auto unseal"
  default     = "vault-key"
}