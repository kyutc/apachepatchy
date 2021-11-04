#!/bin/bash

export PATH=$PATH:/usr/sbin
export MWD=$(pwd)

chmod +x *.sh

id abronsius || \
    useradd -m abronsius -s /bin/bash && \
echo -ne "knoblauch\nknoblauch\n" | passwd abronsius

# To consider: since we're going to be compromising this user, perhaps we could
# crack this user's password from some hash (not /etc/shadow, but elsewhere) in
# order to then gain sudo and thus root access?
apt -y install sudo
echo "abronsius    ALL=(ALL:ALL) ALL" > /etc/sudoers.d/abronsius

# MariaDB is a drop-in replacement for MySQL. Any compatible database software
# will work for our purposes
apt -y install mariadb-server
# Either one of these commands should be used to set the root user's password.
mariadb-admin --user="root" password "knoblauch"
# Debian might run mariadb-secure-installation by default, I don't recall.
#mariadb-secure-installation
# If a password has already been set, use this:
# mariadb-admin --user="root" --password="original" password "knoblauch"


# Install the necessary tools to build apache2 from source
apt -y install build-essential
apt -y build-dep apache2

# Note: apache2 version 2.4.49 was removed from Debian's repo because it
# contains a serious security flaw. Because of this, we must download this
# specific version and install it ourselves.
su abronsius -c ./setup_apache.sh

# Setup nginx
apt -y install nginx

# Install php-fpm to be used with NGINX, and the required extensions for XenForo
apt -y install php-fpm php7.4-mysqli php7.4-gd php7.4-curl php7.4-dom \
    php7.4-simplexml php7.4-gmp php7.4-mbstring php7.4-zip

# Note: this file is a symlink to /etc/nginx/sites-available/default and won't
# actually be deleted.
rm /etc/nginx/sites-enabled/default

# The catchall config will return 404 on any non-configured domain
cp catchall.conf /etc/nginx/sites-available/catchall.conf
ln -s /etc/nginx/sites-available/catchall.conf /etc/nginx/sites-enabled/catchall.conf

# Configure Abronsius' public-facing HTTP access via NGINX. This does a
# proxy_pass to 127.0.0.1:8080 which is Abronsius' apache server.
cp abronsius.cpsc4270.local.conf /etc/nginx/sites-available/abronsius.cpsc4270.local.conf
ln -s /etc/nginx/sites-available/abronsius.cpsc4270.local.conf /etc/nginx/sites-enabled/abronsius.cpsc4270.local.conf
# This directory isn't actually used for anything
mkdir -p /var/www/abronsius.cpsc4270.local
chown -R www-data:www-data /var/www/abronsius.cpsc4270.local

cp alfred.cpsc4270.local.conf /etc/nginx/sites-available/alfred.cpsc4270.local.conf
ln -s /etc/nginx/sites-available/alfred.cpsc4270.local.conf /etc/nginx/sites-enabled/alfred.cpsc4270.local.conf
mkdir -p /var/www/alfred.cpsc4270.local
chown -R www-data:www-data /var/www/alfred.cpsc4270.local
systemctl reload nginx

# Download, configure, and install XenForo
apt -y install python3-pip
pip install beautifulsoup4 lxml
mkdir /var/www/files -p
chown -R www-data:www-data /var/www/files
su www-data -s /bin/bash -c ./setup_xenforo.sh
