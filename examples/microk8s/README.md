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
- Run SSH Tunnel to allow `kubectl` commands to run locally
```
# Save private key
rm -f ./private_key.pem
terraform output private_key > ./private_key.pem && chmod 400 ./private_key.pem

# Export ip address and connect via SSH Tunnel (Important: use the -L flag to port format 16443)
ip=$(terraform output -json external_ip | jq -r '.[0]')
ssh -i ./private_key.pem -L 16443:127.0.0.1:16443 ubuntu@${ip}
```

- Setup Kubectl locally in another terminal window
```
# SCP the kubeconfig file (microk8s.kubectl config view --raw)
scp -i ./private_key.pem ubuntu@${ip}:/home/ubuntu/microk8s.yaml ./microk8s.yaml
export KUBECONFIG=./microk8s.yaml
kubectl get nodes
```

- Cleanup:
```
terraform destroy
unset GOOGLE_CREDENTIALS
unset TF_VAR_gcp_project
```

