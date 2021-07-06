#!/bin/bash
set +e 
echo "[Startup] - Startup script for terraform"

echo "[Startup] - Setting up SSH for user ubuntu"
sudo touch /home/ubuntu/.ssh/authorized_keys
cat <<EOF > /tmp/authorized_keys
${public_key}
EOF
sudo mv /tmp/authorized_keys /home/ubuntu/.ssh/authorized_keys


echo "[Startup] - Installing docker"
# Install Docker
apt-get update -y
apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y
apt-get install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install docker-ce -y
groupadd docker
usermod -aG docker ubuntu
systemctl enable docker.service
systemctl start docker.service


# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
sleep 10

# Install binaries
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update
sudo apt-get install vault consul terraform make jq -y

vault --version
consul --version
terraform --version

# clone the vault-guides repo
echo "[Startup] - Clone git repo"
cd /home/ubuntu
git clone https://github.com/hashicorp/vault-guides.git
cd vault-guides/operations/onboarding
cd docker-compose/ && docker-compose up -d
sleep 10
cd scripts
./00-init.sh
ln -s /home/ubuntu/vault-guides/operations/onboarding /home/ubuntu/onboarding

sudo chown ubuntu:ubuntu -R /home/ubuntu/vault-guides
echo "[Startup] - completed"
