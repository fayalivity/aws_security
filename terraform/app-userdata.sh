#!/bin/bash
yum install -y httpd
WEB_PATH=/var/www/html/index.html
touch $WEB_PATH
echo "Online ! Connecté sur l'instance $RANDOM" | tee -a $WEB_PATH
systemctl start httpd