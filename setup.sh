apt install sudo -y
echo "abronsius    ALL=(ALL:ALL) ALL" > /etc/sudoers.d/abronsius

apt install build-essential -y
apt build-dep apache2 -y

# Note: apache2 version 2.4.49 was removed from Debian's repo because it contains a serious security flaw.
# Because of this, we must download this specific version and install it ourselves.
su - abronsius <<SU_EOF
mkdir ~/build
cd ~/build
wget https://archive.apache.org/dist/httpd/httpd-2.4.49.tar.bz2
tar -jxvf httpd-2.4.49.tar.bz2
# sha512: 418e277232cf30a81d02b8554e31aaae6433bbea842bdb81e47a609469395cc4891183fb6ee02bd669edb2392c2007869b19da29f5998b8fd5c7d3142db310dd
cd httpd-2.4.49
mkdir ~/apache2
./configure --prefix=/home/abronsius/apache2
make
make install

# Make changes to apache config to enable mod_cgi and allow the web server to serve files
patch ~/apache2/conf/httpd.conf - <<PATCH_EOF
150c150
< #LoadModule cgid_module modules/mod_cgid.so
---
> LoadModule cgid_module modules/mod_cgid.so
210c210
<     Require all denied
---
>     #Require all denied
PATCH_EOF


SU_EOF
