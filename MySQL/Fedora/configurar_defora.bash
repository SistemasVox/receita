#!/bin/bash

sudo timedatectl set-timezone America/Argentina/Buenos_Aires

sudo dnf install -y net-tools wget vim bmon nethogs nano git screen selinux-utils curl open-vm-tools speedtest-cli
sudo netstat -tulpn

cd /etc/default/

sudo vim grub

GRUB_TIMEOUT=0

sudo grub2-mkconfig -o /boot/grub2/grub.cfg

sudo dnf install httpd

sudo systemctl enable httpd.service

sudo systemctl start httpd.service

sudo dnf install mariadb mariadb-server

sudo systemctl enable mariadb.service

sudo systemctl start mariadb.service

sudo dnf install python3 python3-pip

pip3 install requests

sudo dnf install phpMyAdmin

sudo vim /etc/httpd/conf.d/phpMyAdmin.conf

sudo vim /etc/httpd/conf/httpd.conf

sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --reload

sudo firewall-cmd --add-port=3306/tcp --permanent
sudo firewall-cmd --reload

sudo firewall-cmd --add-port=5432/tcp --permanent
sudo firewall-cmd --reload

sudo chmod 755 /usr/share/phpMyAdmin/

sudo vim /etc/httpd/conf.d/phpMyAdmin.conf
Alias /phpMyAdmin /usr/share/phpMyAdmin
<Directory /usr/share/phpMyAdmin/>
   AddDefaultCharset UTF-8
   Require all granted
</Directory>
sudo systemctl restart httpd.service

sudo nano /etc/my.cnf
[mysqld]
bind-address = 0.0.0.0
local_infile = ON
default-time-zone='-03:00'
innodb_buffer_pool_size = 4G
innodb_log_file_size = 1G
sudo systemctl restart mariadb.service

sudo mysql -u root -p
CREATE USER 'marcelo'@'%' IDENTIFIED BY 'q1w2';
GRANT ALL ON *.* TO 'marcelo'@'%';
FLUSH PRIVILEGES;

SET GLOBAL time_zone = '-03:00';

sudo systemctl restart mariadb.service
