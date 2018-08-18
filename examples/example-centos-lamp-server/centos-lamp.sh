#!/bin/bash
cd /tmp
sudo yum update -y
sudo yum install wget git curl jq -y

# Install HTTP and Maria DB
sudo yum install httpd mariadb-server mariadb -y
sudo systemctl start httpd.service
sudo systemctl start mariadb
sudo systemctl enable mariadb.service
sudo systemctl enable httpd.service

# Install PHP
sudo yum install php php-mysql php-gd php-mcrypt* -y
sudo echo '<?php phpinfo(); ?>' > /var/www/html/info.php 
sudo systemctl restart httpd.service
