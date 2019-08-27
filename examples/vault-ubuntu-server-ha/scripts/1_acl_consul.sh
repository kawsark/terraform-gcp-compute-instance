#!/bin/bash
# Please adjust CONSUL_HTTP_TOKEN and run this from remaining Consul nodes
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
policy_id=$(consul acl policy read -name consul-servers | grep -i ID | awk '{print $2}')
token=$(consul acl token create -description $(hostname) -policy-name consul-servers | grep SecretID | awk '{print $2}')

echo "Updating systemd unit file and restarting Consul"
echo "Environment=CONSUL_HTTP_TOKEN=${token}" | sudo tee -a /etc/systemd/system/consul.service
sudo systemctl daemon-reload
sudo systemctl restart consul
sudo systemctl status consul
echo "Done"