id abronsius || \
    useradd -m abronsius -s /bin/bash && \
    echo "Password for abronsius: " && \
    passwd abronsius

# To consider: since we're going to be compromising this user, perhaps we could
# crack this user's password from some hash (not /etc/shadow, but elsewhere) in
# order to then gain sudo and thus root access?
apt install sudo -y
echo "abronsius    ALL=(ALL:ALL) ALL" > /etc/sudoers.d/abronsius

# Setup hostnames.

# MariaDB is a drop-in replacement for MySQL. Any compatible database software
# will work for our purposes
apt install mariadb-server -y

# Install the necessary tools to build apache2 from source
apt install build-essential -y
apt build-dep apache2 -y

# Note: apache2 version 2.4.49 was removed from Debian's repo because it
# contains a serious security flaw. Because of this, we must download this
# specific version and install it ourselves.
su abronsius -c ./setup_apache.sh

# Setup nginx
apt install nginx -y

# php-fpm will be used with NGINX
apt install php-fpm -y

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
mkdir /var/www/abronsius.cpsc4270.local -p
# TODO: Continue script to install and configure XenForo (or some other
# software) and php-fpm automatically.
