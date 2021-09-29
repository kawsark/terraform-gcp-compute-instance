#!/bin/bash

if [[ ${ARM_SUBSCRIPTION_ID} == "" ]]; then
  echo "ARM_SUBSCRIPTION_ID environment variable not set, Azure Secrets Engine setup will be skipped"
  echo "Hit Ctrl-C to exit (waiting 10 seconds)"
  sleep 10
fi

[[ ${url} == "" ]] && echo "Please set the state file download URL: export url=<statefule>" && exit 0

echo "Updating firewall rule to access from current IP"
gcloud compute firewall-rules update allow-all-homeip --source-ranges="$(curl -s http://whatismyip.akamai.com)/32"

echo "Downloading state file"
wget -O terraform.tfstate "${url}"
rm -f ./private_key.pem && terraform output private_key > ./private_key.pem && chmod 400 ./private_key.pem
pem=./private_key.pem

ip=$(terraform output -json external_ip | jq -r '.[0]')                                                   

echo "Putting Approle script on server"
scp -i ${pem} ./approle.sh ubuntu@${ip}:/home/ubuntu/approle.sh

echo "Getting vault.txt file from server"
scp -i ${pem} ubuntu@${ip}:/home/ubuntu/vault-guides/operations/onboarding/docker-compose/scripts/vault.txt ./vault.txt

echo "Executing Approle script on server"
ssh -i ${pem} ubuntu@${ip} "chmod +x /home/ubuntu/approle.sh; /home/ubuntu/approle.sh"






