#This is a startup-script that will install an example application on the provisioned server
#!/bin/bash
sudo apt-get install git -y
cd /tmp
git clone https://github.com/hashicorp/demo-terraform-101.git
cp -r demo-terraform-101/assets .
cd assets
sudo chmod +x ./setup-web.sh
sudo ./setup-web.sh
