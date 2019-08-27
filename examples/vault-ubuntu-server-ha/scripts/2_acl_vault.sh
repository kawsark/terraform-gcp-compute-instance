# Please adjust CONSUL_HTTP_TOKEN and run this from all Vault nodes
# export CONSUL_HTTP_TOKEN="<consul-bootstrap-token>"

# Test for token variable
if [ -z "$CONSUL_HTTP_TOKEN" ]
then
      echo ">>>> Please set CONSUL_HTTP_TOKEN environment variable to bootstrap token value before running this script."
      echo ">>>> export CONSUL_HTTP_TOKEN=<bootstrap-token>"
      exit 1
fi

# Updating this node with default policy of deny
echo "Applying ACL with default deny"
sudo rm /etc/consul.d/acl.hcl
echo 'acl = {
  enabled = true,
  default_policy = "deny",
  enable_token_persistence = true
}' | sudo tee /etc/consul.d/acl.hcl
sudo chown -R consul:consul /etc/consul.d

echo "Creating token for node: $(hostname)"
policy_id=$(consul acl policy read -name vault-servers | grep -i ID | awk '{print $2}')
token1=$(consul acl token create -description $(hostname) -policy-name vault-servers | grep SecretID | awk '{print $2}')

echo "Creating token for node: $(hostname)-services"
policy_id=$(consul acl policy read -name vault-services | grep -i ID | awk '{print $2}')
token2=$(consul acl token create -description $(hostname)-services -policy-name vault-services | grep SecretID | awk '{print $2}')

echo "Updating systemd unit files"
echo "Environment=CONSUL_HTTP_TOKEN=${token1}" | sudo tee -a /etc/systemd/system/consul.service
echo "Environment=CONSUL_HTTP_TOKEN=${token2}" | sudo tee -a /etc/systemd/system/vault.service

echo "Restarting services"
sudo systemctl daemon-reload
sudo systemctl stop vault
sleep 5
sudo systemctl restart consul
sleep 5
sudo systemctl start vault
sleep 5
sudo systemctl status consul
sudo systemctl status vault
echo "Done"