#!/bin/bash

sudo apt-get update
sudo apt-get install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx


echo "<h1> Hello naina, anshika </h1>" | tee /var/www/html/index.html
# echo "<h1>this is my terraform based infrastructure</h1>" | tee /var/www/html/index.html


sudo systemctl restart nginx