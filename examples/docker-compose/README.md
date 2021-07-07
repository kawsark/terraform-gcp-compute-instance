## Docker-compose server
Creates a Ubuntu 18 server then clones the vault-guides repo. It then creates the Docker compose stack from `vault-guides/operations/onboarding/docker-compose/`.

### Steps:
- Set Environment variables
```
export GOOGLE_CREDENTIALS="$(cat /path/to/service-account.json)"
export TF_VAR_gcp_project="<gcp-project-name>"
```

- Run terraform commands on your local machine
```
terraform init
terraform get -update=true
terraform plan
terraform apply
```

- If using the VCS driven run, please download the terraform.tfstate file locally

- (Optional) SSH into instance
```
# Save private key
rm -f ./private_key.pem
terraform output private_key > ./private_key.pem && chmod 400 ./private_key.pem

# Export ip address and connect via SSH
ip=$(terraform output -json external_ip | jq -r '.[0]')
ssh -i ./private_key.pem ubuntu@${ip}

# Get root token and unseal key
cat onboarding/docker-compose/scripts/vault.txt
```

- Cleanup:
```
terraform destroy
unset GOOGLE_CREDENTIALS
unset TF_VAR_gcp_project
```
