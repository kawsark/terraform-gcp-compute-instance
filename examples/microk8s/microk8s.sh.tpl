#!/bin/bash
set +e 
echo "[Startup] - Startup script for terraform"

echo "[Startup] - Setting up SSH for user ubuntu"
sudo touch /home/ubuntu/.ssh/authorized_keys
cat <<EOF > /tmp/authorized_keys
${public_key}
EOF
sudo mv /tmp/authorized_keys /home/ubuntu/.ssh/authorized_keys

# Reference: https://ubuntu.com/tutorials/install-a-local-kubernetes-with-microk8s
# Install dependencies
echo "[Startup] - Installing dependencies"
sudo apt-get update -y
sudo apt-get install -y git unzip curl jq dnsutils

echo "[Startup] - Configure firewall"
sudo ufw allow in on cni0 && sudo ufw allow out on cni0
sudo ufw default allow routed

echo "[Startup] - Installing microk8s"
sudo snap install microk8s --classic

echo "[Startup] - Enable addons"
microk8s.enable dashboard dns storage

echo "[Startup] - Waiting for microk8s to complete with 300s timeout"
sudo microk8s.kubectl config view --raw > /home/ubuntu/microk8s.yaml
chown ubuntu:ubuntu /home/ubuntu/microk8s.yaml
sudo usermod -a -G microk8s ubuntu
echo "alias kubectl=microk8s.kubectl" | sudo tee -a /home/ubuntu/.bashrc
microk8s.status --wait-ready --timeout 300

echo "[Startup] - microk8s.status --wait-ready completed"