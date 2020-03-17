# Provision a compute instance in GCP with SSD Persistent Disk and a startup script
This Terraform configuration provisions a compute instance in Google Cloud Platform.

### Notes:
- Provider configuration variables (required):
  - GCP credentials: please set `GOOGLE_CREDENTIALS` environment variable with contents of service account json file. Note: please remove and line breaks from the file
  - GCP project: please set `gcp_project` variable with gcp project name.

- By default, this configuration provisions a compute instance from image debian-cloud/debian-8 with machine type t2.micro in the us-east1 region. These can be adjusted as below:
  - Region: Please set `gcp_region` variable. E.g: `export TF_VAR_gcp_region=us-east1`
  - Image: Please set `image` variable. E.g: `export TF_VAR_image=centos-cloud/centos-7`  
  - Machine type: Please set `machine_type` variable. E.g: `export TF_VAR_machine_type=n1-standard-1`

- Other options: please see [variables.tf](variables.tf).  

### Module usage:  
- This configuration can also be used as a module as shown under examples:  
  - [example-centos-lamp-server](examples/example-centos-lamp-server/)
  - [ubuntu-vault-server](examples/vault-ubuntu-server/)
  - [microk8s](examples/microk8s)