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

### GitLab Runner service and registration
This repo also installs the GitLab Runner binary and the gitlab-runner service using the [documentation on GitLab](https://docs.gitlab.com/runner/install/linux-manually.html). Use the commands below to check service status and register it.
- Note: you will need the Runner Registration Token from your GitLab server.
```
# Check status
sudo systemctl status gitlab-runner

# Register a Shell runner
sudo gitlab-runner register
Runtime platform                                    arch=amd64 os=linux pid=11666 revision=8925d9a0 version=14.1.0
Running in system-mode.

Enter the GitLab instance URL (for example, https://gitlab.com/):
https://gitlab.com
Enter the registration token:
<your-token>
Enter a description for the runner:
[docker-compose-server-46a3-0]:
Enter tags for the runner (comma-separated):
curl, jq, terraform, vault
Registering runner... succeeded                     runner=nXy8Ksp8
Enter an executor: docker, shell, virtualbox, docker-ssh+machine, kubernetes, custom, docker-ssh, parallels, ssh, docker+machine:
shell
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!

# Restart the service
sudo gitlab-runner restart

# Check status
sudo gitlab-runner status
```

