id abronsius || \
    useradd -m abronsius -s /bin/bash && \
    echo "Password for abronsius: " && \
    passwd abronsius

apt install sudo -y
echo "abronsius    ALL=(ALL:ALL) ALL" > /etc/sudoers.d/abronsius

# Install the necessary tools to build apache2 from source
apt install build-essential -y
apt build-dep apache2 -y

# Note: apache2 version 2.4.49 was removed from Debian's repo because it
# contains a serious security flaw. Because of this, we must download this
# specific version and install it ourselves.
su abronsius -c ./setup_apache.sh
