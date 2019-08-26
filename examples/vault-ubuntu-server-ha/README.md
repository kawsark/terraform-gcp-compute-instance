## vault-server-ha
This is an example showing how to use `terraform-gcp-compute-instance` module to provision a Vault and Consul cluster.
**Important:** This code does not implement all of the [Vault production hardening recommendations](https://learn.hashicorp.com/vault/operations/production-hardening) and therefore should not be used in production.

- By default, this code provisions a 3 node Consul cluster and 2 node Vault cluster. 
  - Qty. of nodes can easily be adjusted by setting `vault_server_count` and `consul_server_count`.
- The `consul_url` and `vault_url` variables can be adjusted to Enterprise binary URLs to provision enterprise clusters.
- We are using the [github.com/hashicorp-modules/tls-self-signed-cert](github.com/hashicorp-modules/tls-self-signed-cert) module to implement TLS for both Vault and Consul. The generated `.pem` files are saved to current directory and should be handled with care.
- This code assumes an existing network in GCP and does not provision firewall rules. We highly recommend only allowing ingress access from a Bastion or your IP. E.g:
```
gcloud compute firewall-rules update allow-all-workstation --source-ranges="$(curl -s http://whatismyip.akamai.com)/32"
gcloud compute firewall-rules update allow-all-bastion --source-ranges="<bastion-ip-addr>/32"
```

- Startup scripts are in the [scripts](scripts/) directory. Vault will be initialized and the root token will be placed at `/opt/vault/root_token` for one of the Vault nodes (whichever proceeds to initialize first).

### TODO: 
- Implement Consul ACL tokens
- Provision 3 non-voting consul nodes using Availability Zones and take advantage of Consul Enterprise auto-pilot feature. This can be achieved by duplicating the consul-cluster module and adjusting userdata.
- Upgrade this code to terraform 0.12. Currently we are using the []() module to generate self-signed TLS which needs to be updated first.

### Steps:
1. Set required variables
```
# Note: please remove all new line characters from Google service account .json file
export GOOGLE_CREDENTIALS="path/to/credentials/file"
export TF_VAR_gcp_project="gcp-project-name"
export TF_VAR_owner="your-name"
export TF_VAR_key_ring="name-of-existing-keyring-for-autounseal"
export TF_VAR_crypto_key="name-of-key-in-keyring-for-autounseal"
```
2. Set any optional variables
- Customize Vault or Consul versions by setting `vault_url` or `consul_url` Terraform variables.
- If using Enterprise binaries, licenses can be auto-applied by setting `vault_license` and `consul_license` variables.
- Review [variables.tf](variables.tf) file to adjust any other variables as needed.

3. Run terraform commands:
```
terraform init
terraform get -update=true
terraform plan
terraform apply
```
- SSH into the instance
Note: the `/opt/vault/vault.txt` file will contain root token. It will be in the Active node during startup.
```
gcloud compute --project "<project_name>" ssh --zone "us-east1-b" "vault-0"
consul catalog services -tags
vault status
# Get root token
cat /opt/vault/vault.txt
export VAULT_TOKEN="root-token"
vault status
``` 
- Cleanup:
Note: you may get an error message during destroy that the disks do not exist. This is because the disks are set to auto delete by default when the instance is deleted. 
```
terraform destroy
unset TF_VAR_gcp_credentials
unset TF_VAR_gcp_project
rm *.pem
```

