#!/bin/bash
echo "~~~~~~~ Consul startup script - begin ~~~~~~~"

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

# Download consul
echo "Downloading consul"
cd /tmp
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
cat <<EOF > /etc/systemd/system/consul.service
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

cat <<-EOF > "$${CONSUL_CONFIG_DIR}/server.hcl"
datacenter = "${dc}"
data_dir = "$${CONSUL_DATA_DIR}"
bind_addr = "$${local_ip}"
bootstrap_expect = ${consul_server_count}
server = true
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

# Bootstrap ACL tokens
cat <<-EOF > $${CONSUL_CONFIG_DIR}/acl.hcl
acl = {
  enabled = true,
  default_policy = "allow",
  enable_token_persistence = true
}
EOF

chown -R consul:consul "$${CONSUL_CONFIG_DIR}"
chown -R consul:consul "$${CONSUL_DATA_DIR}"
chown -R consul:consul "$${CONSUL_TLS_DIR}"

echo "Starting consul service"
systemctl enable consul.service
systemctl daemon-reload
systemctl start consul.service

# Apply Enterprise license and enable tokens
echo "Applying enterprise license"
export CONSUL_HTTP_ADDR="https://127.0.0.1:8501"
export CONSUL_CACERT="$${CONSUL_TLS_DIR}/consul-ca.crt"
export CONSUL_HTTP_SSL_VERIFY=false

function consul_has_leader {
  try=0
  max=12
  consul_has_leader=$(consul operator raft list-peers | grep leader)
  while [ -z "$consul_has_leader" ]
  do
    touch "/tmp/consul-try-$try"
    if [[ "$try" == '12' ]]; then
      echo "Giving up on consul operator raft list-peers after 12 attempts."
      break
    fi
    ((try++))
    echo "Consul leader is not elected, sleeping 10 secs [$try/$max]"
    sleep 10
    consul_has_leader=$(consul operator raft list-peers | grep leader)
  done

  echo "Consul cluster has leader, proceeding with Initialization"
}

# Wait for consul to elect a leader
consul_has_leader

consul members
consul license put ${consul_license}
consul license get > /opt/consul/license_status
echo "Consul license status: $(consul license get)"

# Setup bash profile
cat <<PROFILE | sudo tee /etc/profile.d/consul.sh
export CONSUL_HTTP_ADDR="https://127.0.0.1:8501"
export CONSUL_CACERT="$${CONSUL_TLS_DIR}/consul-ca.crt"
PROFILE

echo "~~~~~~~ Consul startup script - end ~~~~~~~"