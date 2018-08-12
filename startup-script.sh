#!/bin/bash
cd /tmp
sudo apt-get update -y
sudo apt-get install wget git curl jq -y
git clone https://github.com/hashicorp/guides-configuration.git
echo "This user-data was input by Terrafom by $(whoami) @ $(date)" > /tmp/startup-script.txt
