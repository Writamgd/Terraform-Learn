#!/bin/bash
# Update the package index
sudo apt-get update -y || sudo yum update -y

# Install Nginx
sudo apt-get install nginx -y || sudo yum install nginx -y

# Start and enable Nginx to start on boot
sudo systemctl start nginx
sudo systemctl enable nginx

# Add a simple HTML file to verify installation
echo "<h1>Nginx is installed and running!</h1>" | sudo tee /var/www/html/index.html