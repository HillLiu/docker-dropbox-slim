#!/bin/sh

###
# Environment ${INSTALL_VERSION} pass from Dockerfile
###

apt install -qq -y --no-install-recommends supervisor sudo


#/* put your install code here */#

mkdir /data \
  && chmod 0755 /usr/local/bin/dropbox \
  && chmod 0777 /data

# Prevent automatic updates
# install -dm0 /data/.dropbox-dist

# Clean
apt-get clean autoclean
apt-get autoremove --yes
apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
rm -rf /var/lib/{apt,dpkg,cache,log}/

exit 0
