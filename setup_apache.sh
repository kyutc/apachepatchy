mkdir ~/build -p
cd ~/build

echo "65b965d6890ea90d9706595e4b7b9365b5060bec8ea723449480b4769974133b  httpd-2.4.49.tar.bz2" | \
    sha256sum -c || \
    wget https://archive.apache.org/dist/httpd/httpd-2.4.49.tar.bz2
tar -jxvf httpd-2.4.49.tar.bz2
# sha512: 418e277232cf30a81d02b8554e31aaae6433bbea842bdb81e47a609469395cc4891183fb6ee02bd669edb2392c2007869b19da29f5998b8fd5c7d3142db310dd
cd httpd-2.4.49
mkdir ~/apache2 -p
./configure --prefix=/home/abronsius/apache2
make
make install

# Make changes to apache config to enable mod_cgi and allow the web server to
# serve files
patch ~/apache2/conf/httpd.conf httpd.conf.patch
