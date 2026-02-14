#!/bin/bash
sudo dnf install httpd -y

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

sudo echo "Instance ID: $INSTANCE_ID" > /var/www/html/index.html

sudo systemctl enable --now httpd

