#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>Website test. Instance IP: $(hostname -f)</h1>" > /var/www/html/index.html