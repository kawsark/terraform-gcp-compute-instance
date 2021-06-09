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
sudo usermod -a -G microk8s ubuntu
echo "alias kubectl=microk8s.kubectl" | sudo tee -a /home/ubuntu/.bashrc
microk8s.status --wait-ready --timeout 300

echo "[Startup] - microk8s.status --wait-ready completed"

echo "[Startup] - updating public_ip for CA and restarting"
# Reference: https://github.com/ubuntu/microk8s/issues/421
public_ip=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
sudo cp /var/snap/microk8s/current/certs/csr.conf.template /var/snap/microk8s/current/certs/csr.conf.template.backup
cat /var/snap/microk8s/current/certs/csr.conf.template.backup | sed -e s/#MOREIPS/"IP.9 = $${public_ip}\n#MOREIPS"/g | sudo tee /var/snap/microk8s/current/certs/csr.conf.template
microk8s.stop && sleep 10 && microk8s.start
echo "[Startup] - public_ip is: $${public_ip}"
sudo microk8s.kubectl config view --raw | sed s/"127.0.0.1"/"$${public_ip}"/g > /home/ubuntu/microk8s.yaml
chown ubuntu:ubuntu /home/ubuntu/microk8s.yaml
echo "[Startup] - completed"
