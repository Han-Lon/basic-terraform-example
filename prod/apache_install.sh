#!/bin/bash
sudo yum update -y && \
sudo yum install httpd -y && \
sudo systemctl enable httpd.service && \
sudo cp /usr/share/httpd/noindex/index.html /var/www/html/index.html && \
sudo systemctl start httpd.service