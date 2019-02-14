# Provision a compute instance in GCP with SSD Persistent Disk and a startup script. This Terraform configuration provisions a compute instance in Google Cloud Platform.
- This branch required Google provider version 2.0.0 as it creates a data-disk that is encrypted using a disk_encryption_key. The key is sourced from an existing key in Cloud kms.

### Steps:
- Provider configuration variables (required):
  - GCP credentials: please set `gcp_credentials` variable with contents of service account json file.
  - GCP project: please set `gcp_project` variable with gcp project name.

- KMS key configuration variable (required):
  - Create tfvars file: `cp terraform.auto.tfvars.example terraform.auto.tfvars`
  - Adjust `enc_key_self_link` variable in terraform.auto.tfvars

- Configure IAM role:
  - Create a role based on Cloud KMS Admin, then assign it to service account "Compute Engine Service Agent". Specifically, the `cloudkms.cryptoKeyVersions.useToEncrypt` permission will be needed. Exact steps are documented in [google_compute_disk resource](https://www.terraform.io/docs/providers/google/r/compute_disk.html#kms_key_self_link).

- By default, this configuration provisions a compute instance from image debian-cloud/debian-8 with machine type t2.micro in the us-east1 region. These can be adjusted as below:
  - Region: Please set `gcp_region` variable. E.g: `export TF_VAR_gcp_region=us-east1`
  - Image: Please set `image` variable. E.g: `export TF_VAR_image=centos-cloud/centos-7`  
  - Machine type: Please set `machine_type` variable. E.g: `export TF_VAR_machine_type=n1-standard-1`

- Other options: please see [variables.tf](variables.tf).  

### Module usage:  
- This configuration can also be used as a module as shown under examples:  
  - [example-centos-lamp-server](examples/example-centos-lamp-server/)
  - [ubuntu-vault-server](examples/vault-ubuntu-server/)
