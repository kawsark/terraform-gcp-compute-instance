# example-centos
Example showing how to use terraform-gcp-compute-instance module to provision a CentOS VM
An example startup-script is added here for CentOS

### Steps:
- Set variables:
```
export TF_VAR_gcp_credentials="path/to/credentials/file"
export TF_VAR_gcp_project="gcp-project-name"
```
- Run terraform commands:
```
terraform init
terraform get -update=true
terraform plan
terraform apply
```
- Cleanup:
```
terraform destroy
unset TF_VAR_gcp_credentials
unset TF_VAR_gcp_project
```
