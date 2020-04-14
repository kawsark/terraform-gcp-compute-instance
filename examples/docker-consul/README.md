# microk8s server
Example showing how to setup a MicroK8S server on Ubuntu
- An example startup-script is added here for installing MicroK8S
- A SSH Tunnel needs to be created in order to run `kubectl` locally (See [GH issue](https://github.com/ubuntu/microk8s/issues/421) )

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

- Setup Kubectl locally
Note: if you get an error: `scp: /home/ubuntu/microk8s.yaml: No such file or directory`, please wait a few minutes to complete initialization.
The `microk8s.yaml` file with external IP is written as part of the startup process.
```
# SCP the kubeconfig file (microk8s.kubectl config view --raw)
ip=$(terraform output -json external_ip | jq -r '.[0]')
scp -i ./private_key.pem ubuntu@${ip}:/home/ubuntu/microk8s.yaml ./microk8s.yaml
export KUBECONFIG=./microk8s.yaml
kubectl get nodes
```

- (Optional) SSH into instance
```
# Save private key
rm -f ./private_key.pem
terraform output private_key > ./private_key.pem && chmod 400 ./private_key.pem

# Export ip address and connect via SSH
ip=$(terraform output -json external_ip | jq -r '.[0]')
ssh -i ./private_key.pem ubuntu@${ip}
```

- Cleanup:
```
terraform destroy
unset GOOGLE_CREDENTIALS
unset TF_VAR_gcp_project
```
