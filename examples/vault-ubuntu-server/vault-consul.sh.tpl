#!/bin/bash

#Install Consul and dependencies
echo "Installing dependencies ..."
sudo apt-get update -y
sudo apt-get install -y git unzip curl jq dnsutils
echo "Fetching Consul version ${CONSUL_VERSION} ..."
cd /tmp/
curl -s https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
echo "Installing Consul version ${CONSUL_VERSION} ..."
unzip consul.zip
sudo chmod +x consul
sudo mv consul /usr/bin/consul
sudo mkdir /etc/consul.d
sudo chmod a+w /etc/consul.d

# Install and start Consul service
sudo cat <<EOF > /etc/systemd/system/consul.service
[Unit]
Description=consul agent
Requires=network-online.target
After=network-online.target
[Service]
Restart=always
RestartSec=15s
User=ubuntu
Group=ubuntu
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
[Install]
WantedBy=multi-user.target
EOF

sudo cat <<EOF > /etc/consul.d/consul.json
{
  "datacenter": "dc1",
  "data_dir": "/tmp/consul",
  "log_level": "DEBUG",
  "node_name": "n1",
  "server": true,
  "bootstrap_expect": 1,
  "enable_script_checks": false,
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "connect": {
    "enabled": true
  },
  "ui": true
}
EOF


# Start service
systemctl enable consul.service
systemctl start consul.service

# Install Vault
curl -s https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o vault.zip
unzip vault.zip
sudo chmod +x vault
sudo mv vault /usr/local/bin/vault
sudo mkdir /etc/vault.d
sudo chmod a+w /etc/vault.d

# Install Vault service:
sudo cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description=Vault Agent
Requires=consul.service
After=consul.service

[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/bin/vault
ExecStart=/usr/local/bin/vault server -config /etc/vault.d -log-level=debug
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=ubuntu
Group=ubuntu
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

# Write Vault configuration file:
sudo cat <<EOF > /etc/vault.d/vault.hcl
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "true"
}

storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

ui = "true"
EOF

# Start service
systemctl enable vault.service
systemctl start vault.service

# Initialize and unseal:
sleep 10
export VAULT_ADDR="http://localhost:8200"
vault operator init -format=json -n 1 -t 1 > /tmp/vault.txt
cat /tmp/vault.txt | jq -r '.unseal_keys_b64[0]' > /tmp/unseal_key
cat /tmp/vault.txt | jq -r .root_token > /tmp/root_token
export VAULT_TOKEN=$(cat /tmp/root_token)
vault operator unseal $(cat /tmp/unseal_key)
chown ubuntu:ubuntu /tmp/root_token
chown ubuntu:ubuntu /tmp/unseal_key

echo 'export VAULT_ADDR="http://localhost:8200"' >> /home/ubuntu/.bashrc
echo "export VAULT_TOKEN=$(cat /tmp/root_token)" >> /home/ubuntu/.bashrc
