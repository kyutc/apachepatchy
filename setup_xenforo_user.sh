#!/bin/bash

python3 setup_xenforo_user.py

# Change the Abronsius user's password to use an imported vBulletin password
mariadb -uroot -pknoblauch < "$MWD"/setup_xenforo_user.sql
