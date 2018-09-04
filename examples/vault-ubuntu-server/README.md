# example-centos
Example showing how to use terraform-gcp-compute-instance module to provision a CentOS VM
An example startup-script is added here for CentOS

### Steps:
- Set environment variables:
```
export GOOGLE_CREDENTIALS="path/to/credentials/file"
export GOOGLE_PROJECT="gcp-project-name"
```

- Terraform:
```
terraform plan
terraform apply
```
