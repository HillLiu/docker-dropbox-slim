#!/bin/sh

###
# Environment ${INSTALL_VERSION} pass from Dockerfile
###

apt install -qq -y --no-install-recommends supervisor sudo iproute2 procps python3-gpg

#/* put your install code here */#

rm -rf /data \
  && mkdir /data \
  && ln -s /usr/local/.dropbox-dist /data/.dropbox-dist \
  && chmod 0755 /usr/local/bin/dropbox \
  && chmod 0777 -R /data || exit 2 

# Prevent automatic updates
# install -dm0 /data/.dropbox-dist || exit 1 

# Clean
apt-get clean autoclean
apt-get autoremove --yes
apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
rm -rf /var/lib/{apt,dpkg,cache,log}/

exit 0
