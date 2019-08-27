#!/bin/bash
echo "~~~~~~~ Vault startup script - begin ~~~~~~~"

# Set variables
export PATH="$${PATH}:/usr/local/bin"
export local_ip="$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)"

# Install pre-reqs
# TODO: figure out better OS detection logic
if [  -n "$(uname -a | grep -i Ubuntu)" ]; then
    echo "Proceeding as Ubuntu install"
    apt-get update -y
    apt install curl unzip -y
else
    echo "Proceeding as Redhat/CentOS install"
    yum update -y
    yum install curl unzip -y
fi  

# Download vault and consul
echo "Downloading consul and vault"
apt install curl unzip -y
cd /tmp
curl "${vault_url}" -o vault.zip
unzip vault.zip
mv vault /usr/local/bin/vault
chmod +X /usr/local/bin/vault
echo "Installed vault binary: $(vault --version)"

curl "${consul_url}" -o consul.zip
unzip consul.zip
mv consul /usr/local/bin/consul
chmod +X /usr/local/bin/consul
echo "Installed consul binary: $(consul --version)"

CONSUL_CONFIG_DIR=/etc/consul.d
CONSUL_DATA_DIR=/opt/consul
CONSUL_TLS_DIR=/opt/consul/tls

echo "Creating directories"
useradd --system --home /etc/consul.d --shell /bin/false consul
mkdir -p $${CONSUL_CONFIG_DIR}
mkdir -p $${CONSUL_DATA_DIR}
mkdir -p $${CONSUL_TLS_DIR}

echo "Writing consul systemd unit file"
cat <<-EOF > /etc/systemd/system/consul.service
[Unit]
Description=consul agent
Requires=network-online.target
After=network-online.target
[Install]
WantedBy=multi-user.target
[Service]
Restart=always
RestartSec=15s
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
EOF

# Bootstrap ACL tokens
cat <<-EOF > $${CONSUL_CONFIG_DIR}/acl.hcl
acl = {
  enabled = true,
  default_policy = "allow",
  enable_token_persistence = true
}
EOF

echo "Writing certs to TLS directories"
cat <<EOF | sudo tee "$${CONSUL_TLS_DIR}/consul-ca.crt"
${ca_crt}
EOF
cat <<EOF | sudo tee "$${CONSUL_TLS_DIR}/consul.crt"
${leaf_crt}
EOF
cat <<EOF | sudo tee "$${CONSUL_TLS_DIR}/consul.key"
${leaf_key}
EOF

VAULT_CONFIG_DIR=/etc/vault.d
VAULT_DATA_DIR=/opt/vault
VAULT_TLS_DIR=/opt/vault/tls

useradd --system --home /etc/vault.d --shell /bin/false vault
mkdir -p $${VAULT_CONFIG_DIR}
mkdir -p $${VAULT_DATA_DIR}
mkdir -p $${VAULT_TLS_DIR}
mkdir -p $${VAULT_DATA_DIR}/plugins

echo "Writing vault systemd unit file"
cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description=Vault Agent
Requires=consul.service
After=consul.service
[Install]
WantedBy=multi-user.target
[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/bin/vault
ExecStart=/usr/local/bin/vault server -config /etc/vault.d -log-level=debug
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=vault
Group=vault
LimitMEMLOCK=infinity
EOF

echo "Write certs to TLS directories"
cat <<EOF | sudo tee "$${VAULT_TLS_DIR}/vault-ca.crt"
${ca_crt}
EOF
cat <<EOF | sudo tee "$${VAULT_TLS_DIR}/vault.crt"
${leaf_crt}
EOF
cat <<EOF | sudo tee "$${VAULT_TLS_DIR}/vault.key"
${leaf_key}
EOF

export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=false
export VAULT_CACERT="$${VAULT_TLS_DIR}/vault-ca.crt"

export CONSUL_HTTP_ADDR="https://127.0.0.1:8501"
export CONSUL_HTTP_SSL_VERIFY=false
export CONSUL_CACERT="$${CONSUL_TLS_DIR}/consul-ca.crt"

function vault_consul_is_up {
  try=0
  max=12
  vault_consul_is_up=$(consul catalog services | grep vault)
  while [ -z "$vault_consul_is_up" ]
  do
    touch "/tmp/vault-try-$try"
    if [[ "$try" == '12' ]]; then
      echo "Giving up on consul catalog services after 12 attempts."
      break
    fi
    ((try++))
    echo "Vault or Consul is not up, sleeping 10 secs [$try/$max]"
    sleep 10
    vault_consul_is_up=$(consul catalog services | grep vault)
  done

  echo "Vault and Consul is up, proceeding with Initialization"
}

# Write consul client configuration
cat <<EOF > /etc/consul.d/client.hcl
datacenter = "${dc}"
data_dir = "$${CONSUL_DATA_DIR}"
bind_addr = "$${local_ip}"
server = false
ui = true
log_level = "trace"
retry_join = ${retry_join}
encrypt = "${consul_encrypt}"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true
ca_file = "$${CONSUL_TLS_DIR}/consul-ca.crt"
cert_file = "$${CONSUL_TLS_DIR}/consul.crt"
key_file = "$${CONSUL_TLS_DIR}/consul.key"
verify_incoming = false
verify_incoming_https = false
ports = {
    http = -1,
    https = 8501
}
EOF

chown -R consul:consul "$${CONSUL_CONFIG_DIR}"
chown -R consul:consul "$${CONSUL_DATA_DIR}"
chown -R consul:consul "$${CONSUL_TLS_DIR}"

echo "Starting consul client"
systemctl enable consul.service
systemctl daemon-reload
systemctl start consul.service
sleep 5
consul members

# Write vault server configuration:
cat <<EOF > /etc/vault.d/server.hcl
listener "tcp" {
  address = "0.0.0.0:8200"
  
  tls_client_ca_file = "$${VAULT_TLS_DIR}/vault-ca.crt"
  tls_cert_file      = "$${VAULT_TLS_DIR}/vault.crt"
  tls_key_file       = "$${VAULT_TLS_DIR}/vault.key"

  tls_require_and_verify_client_cert = false
  tls_disable_client_certs           = true
}

storage "consul" {
  address = "https://127.0.0.1:8501"
  path    = "vault-${dc}/"

  tls_ca_file   = "$${CONSUL_TLS_DIR}/consul-ca.crt"
  tls_cert_file = "$${CONSUL_TLS_DIR}/consul.crt"
  tls_key_file  = "$${CONSUL_TLS_DIR}/consul.key"
}

seal "gcpckms" {
  project     = "${gcp_project}"
  region      = "${gcp_region}"
  key_ring    = "${key_ring}"
  crypto_key  = "${crypto_key}"
}

log_level = "Trace"
ui = "true"
api_addr = "http://$${local_ip}:8200"
plugin_directory = "/etc/vault.d/plugins"
EOF

chown -R vault:vault "$${VAULT_CONFIG_DIR}"
chown -R vault:vault "$${VAULT_DATA_DIR}"
chown -R vault:vault "$${VAULT_TLS_DIR}"

# Start vault daemon:
setcap cap_ipc_lock=+ep /usr/local/bin/vault
systemctl enable vault.service
systemctl daemon-reload
systemctl start vault.service

# Wait for vault to register with consul
vault_consul_is_up

#Initialize and unseal Vault:
# Sleep a random # of seconds (up to 30) before initialization:
sleep $((RANDOM % 30))
vault operator init -format=json -recovery-shares=1 -recovery-threshold=1 > $${VAULT_DATA_DIR}/vault.txt
init_ok=$(cat $${VAULT_DATA_DIR}/vault.txt | grep token)
if [ -z "$init_ok" ]
then
  echo "Init unsuccessful (may already be initialized). Restarting vault to allow for license refresh."
  sleep 40
  systemctl resstart vault.service

else
  echo "Init successful"
  vault status
  cat $${VAULT_DATA_DIR}/vault.txt | python -c 'import sys,json;print json.load(sys.stdin)["root_token"]' | cut -d\' -f2 > $${VAULT_DATA_DIR}/root_token
  export VAULT_TOKEN=$(cat $${VAULT_DATA_DIR}/root_token)
  sleep 10
  echo "Writing license"
  vault write sys/license text=${vault_license}
  vault read -format=json sys/license > /opt/vault/license_status
  echo "Vault license: $(vault read -format=json sys/license)"

  # Enable audit
  #touch /var/log/vault_audit.log
  #chown vault:vault /var/log/vault_audit.log
  #chmod u+rw /var/log/vault_audit.log
  #vault audit enable file file_path=/var/log/vault_audit.log
fi

# Setup bash profile
cat <<PROFILE | sudo tee /etc/profile.d/consul.sh
export CONSUL_HTTP_ADDR="https://127.0.0.1:8501"
export CONSUL_CACERT="$${CONSUL_TLS_DIR}/consul-ca.crt"
PROFILE

cat <<PROFILE | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_SKIP_VERIFY=false
export VAULT_CACERT=$${VAULT_TLS_DIR}/vault-ca.crt
export VAULT_CLIENT_CERT=$${VAULT_TLS_DIR}/vault.crt
export VAULT_CLIENT_KEY=$${VAULT_TLS_DIR}/vault.key
PROFILE

echo "~~~~~~~ Vault startup script - end ~~~~~~~"