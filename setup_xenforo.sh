#!/bin/bash

mkdir -p ~/files
cd ~/files

echo "8244b52e722b232dd836c0d50a3b9750839681cd45aeaab28b640cf8269eda95  xenforo_2.2.7-Patch-1.tar.bz2" | \
    sha256sum -c || \
    wget --ca-certificate="$MWD"/cpsc4270.utc.foul.dev.crt \
        https://copyrighted-content:do-not-distribute@cpsc4270.utc.foul.dev/xenforo_2.2.7-Patch-1.tar.bz2
tar -jxvf xenforo_2.2.7-Patch-1.tar.bz2 -C /var/www/alfred.cpsc4270.local

# Create the XenForo database, user, and set permissions
mariadb -uroot -pknoblauch < "$MWD"/init_database.sql

# Bypass browser requirement to install automatically
python3 setup_xenforo.py
