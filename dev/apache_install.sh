#!/bin/bash
sudo yum update -y && \
sudo yum install httpd2 -y && \
sudo systemctl enable httpd22.service