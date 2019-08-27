#!/bin/bash

# Run this from one of the consul-0 server post-init
consul acl bootstrap | sudo tee /opt/consul/consul.txt
export CONSUL_HTTP_TOKEN=$(cat /opt/consul/consul.txt | grep SecretID | awk '{print $2}')

# Consul server policy for Consul agents (servers)
echo "Creating ACL policy and tokens for consul servers"
cat <<-EOF > consul-servers.hcl
  node_prefix "consul-" {
  policy = "write"
}
EOF
consul acl policy create -name consul-servers -rules @consul-servers.hcl

# Vault server policy for Consul agents (clients)
echo "Creating ACL policy and tokens for vault servers"
cat <<-EOF > vault-servers.hcl
  node_prefix "vault-" {
  policy = "write"
}
  service_prefix "vault" { 
  policy = "write" 
}
EOF
consul acl policy create -name vault-servers -rules @vault-servers.hcl

# Vault services
cat <<-EOF > vault-services.hcl
{
  "key_prefix": {
    "vault": {
      "policy": "write"
    }
  },
  "node_prefix": {
    "vault-": {
      "policy": "write"
    }
  },
  "service": {
    "vault": {
      "policy": "write"
    }
  },
  "agent_prefix": {
    "": {
      "policy": "write"
    }

  },
  "session_prefix": {
    "": {
      "policy": "write"
    }
  }
}
EOF
consul acl policy create -name vault-services -rules @vault-services.hcl

# Updating this node with default policy of deny
echo "Applying ACL with default deny"
sudo rm /etc/consul.d/acl.hcl
echo 'acl = {
  enabled = true,
  default_policy = "deny",
  enable_token_persistence = true
}' | sudo tee /etc/consul.d/acl.hcl
sudo chown -R consul:consul /etc/consul.d

policy_id=$(consul acl policy read -name consul-servers | grep -i ID | awk '{print $2}')
echo "Creating token for node: $(hostname)"
token=$(consul acl token create -description $(hostname) -policy-name consul-servers | grep SecretID | awk '{print $2}')

echo "Environment=CONSUL_HTTP_TOKEN=${token}" | sudo tee -a /etc/systemd/system/consul.service

sudo systemctl daemon-reload
sudo systemctl restart consul

sleep 10
echo ">>>>> Consul Bootsrap ACL token is: ${CONSUL_HTTP_TOKEN}"
echo ">>>>> Created ACL policies:"
consul acl policy list
echo ">>>>> Run the following to complete ACL bootstrapping:"
echo ">>>>> # Run on remaining Consul servers"
echo ">>>>> export CONSUL_HTTP_TOKEN=${CONSUL_HTTP_TOKEN}"
echo ">>>>> ./1_acl_consul.sh"
echo ">>>>> # Run on Vault servers"
echo ">>>>> export CONSUL_HTTP_TOKEN=${CONSUL_HTTP_TOKEN}"
echo ">>>>> ./1_acl_vault.sh"
