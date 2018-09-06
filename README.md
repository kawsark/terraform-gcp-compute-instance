# Provision a compute instance in GCP with SSD Persistent Disk and a startup script
This Terraform configuration provisions a compute instance in Google Cloud Platform.

### Notes:
- By default, this configuration provisions a compute instance from image debian-cloud/debian-8 with machine type t2.micro in the us-east1-b zone of the us-east1 region. The image, machine type, zone, and region can all be set with variables.
  
- Provider configuration variables (required):
  - GCP credentials: please set `gcp_credentials` variable with contents of service account json file.
  - GCP project: please set `gcp_project` variable with gcp project name.
  
- This configuration can also be used as a module as shown under examples:  
  - [example-centos-lamp-server](examples/example-centos-lamp-server/)
  - [ubuntu-vault-server](examples/examples/vault-ubuntu-server/)
