#!/bin/bash

# This script provides the commands to SSH into this server and interact with vault
# First export the state file URL as below:
# export url=<state file url>

if [[ -z ${url} ]]; then 
  echo "WARN: State file url not exported: export url=<state-file-url>"
  if [[ -f ./external_ip  ]] && [[ -f ./private_key.pem ]]; then
    export external_ip=$(cat external_ip)
    echo "INFO: Found previous key and server IP: ${external_ip}"
  else
    echo "WARN: Did not find previous server IP and/or private key"
    echo "ERROR: Please export state file URL"
    exit 1
  fi
else
  echo "INFO: Saving state file"
  wget -O terraform.tfstate ${url}

  # Save new private key
  echo "INFO: Writing private key file"
  rm -f ./private_key.pem
  terraform output private_key > ./private_key.pem && chmod 400 ./private_key.pem

  # Export ip address and connect via SSH
  external_ip=$(terraform output -json external_ip | jq -r '.[0]')

  echo "INFO: Server SSH command is:"
  echo "ssh -i ./private_key.pem ubuntu@${external_ip}"
fi

echo "INFO: Trying to ping server"
ping -c 5 ${external_ip}

  [[ $? != 0 ]] && echo "WARN: Could not ping server successfully"
  [[ $? == 0 ]] && echo ${external_ip} > ./external_ip

echo "INFO: SSH to the server now? [Y/n]"
read s

[[ ${s} == "Y" ]] && ssh -i ./private_key.pem ubuntu@${external_ip}
