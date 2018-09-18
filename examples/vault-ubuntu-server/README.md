# vault-ubuntu-server
Example showing how to use terraform-gcp-compute-instance module to provision a single Ubuntu Vault server
- An example startup-script is added here for Vault with Consul storage backend.
- The startup script will auto initialize vault and place the unseal key and root token at `/tmp/unseal_key` and `/tmp/root_token` respectively

### Steps:
- Set environment variables:
```
export TF_VAR_gcp_credentials="path/to/credentials/file"
export TF_VAR_gcp_project=="gcp-project-name"
```
- (Optional) Customize Vault or Consul versions by setting `vault_version` or `consul_version` Terraform variables.
- Run terraform commands:
```
terraform init
terraform get -update=true
terraform plan
terraform apply
```
- (Optional) Copy root token, allow port 8200 and set VAULT_ADDR. Note: need gcloud CLI.
```
gcloud compute scp ubuntu@vault-ubuntu-server:/tmp/root_token /tmp/gcp_vault_root_token
terraform output -module=gcp-ubuntu-server -json | jq -r .external_ip.value > /tmp/gcp_vault_ip
gcloud compute firewall-rules create vault-api-addr --allow tcp:8200
gcloud compute firewall-rules create consul-ui-addr --allow tcp:8500
export VAULT_ADDR="http://$(cat /tmp/gcp_vault_ip):8200"
export CONSUL_HTTP_ADDR="http://$(cat /tmp/gcp_vault_ip):8500"
export VAULT_TOKEN="$(cat /tmp/gcp_vault_root_token)"
consul catalog services
vault status
``` 
- Cleanup:
```
terraform destroy
unset TF_VAR_gcp_credentials
unset TF_VAR_gcp_project
```

