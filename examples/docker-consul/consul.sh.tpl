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
#Install Docker
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
sleep 10

echo "[Startup] - Deploying Consul"
ip=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
echo "Private IP address is: $${ip}"

docker rm -f local_consul
docker run -d --network=host \
              --name=local_consul \
              consul:"${consul_version}" \
              agent -server -datacenter="${datacenter}" -bind="$${ip}" -client="$${ip}" -bootstrap-expect=1 -ui=true

sleep 10
docker logs local_consul
echo "[Startup] - completed"
