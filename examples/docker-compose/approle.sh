#!/bin/bash

cd vault-guides/operations/onboarding/docker-compose/scripts

export app_name=$1
[[ -z $1 ]] && app_name=nginx

echo "Exporting Role ID and Secret ID for app: $app_name"

export VAULT_ADDR=http://localhost:8200
# This exports VAULT_ADDR and VAULT_TOKEN based on initialization output in vault.txt
export VAULT_TOKEN=$(cat vault.txt | jq -r '.root_token')

# Wait until approle auth is mounted
export approle=$(vault auth list | grep approle)
while [[ -z ${approle} ]]
do
    echo "AppRole mount not found, waiting 5 seconds before checking again"
    sleep 5
    export approle=$(vault auth list | grep approle)
done

echo "Approle Auth mount detected, waiting 10 seconds and proceeding with role and secret ID creation"
sleep 10

# Export role and secret IDs for apps
cd ../vault-agent
vault read -format=json auth/approle/role/$app_name/role-id \
  | jq -r .data.role_id \
  | tee $app_name-role_id

vault write -format=json -f auth/approle/role/$app_name/secret-id \
  | jq -r .data.secret_id \
  | tee $app_name-secret_id

# Restart vault agent
docker restart vault-agent

# Login
vault write -format=json auth/approle/login \
  role_id=$(cat ./$app_name-role_id) \
  secret_id=$(cat ./$app_name-secret_id) > login.json
TOKEN=$(cat login.json | jq -r .auth.client_token)

echo "VAULT_TOKEN for app ${app_name} is: $TOKEN"
VAULT_TOKEN=${TOKEN} vault token lookup
VAULT_TOKEN=${TOKEN} vault kv get kv/${app_name}/static
VAULT_TOKEN=${TOKEN} vault read postgres/creds/${app_name}
