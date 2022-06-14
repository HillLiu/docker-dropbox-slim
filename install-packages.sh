#!/bin/sh

###
# Environment ${INSTALL_VERSION} pass from Dockerfile
###

apt install -y supervisor


#/* put your install code here */#

mkdir /data \
  && chmod 0755 /usr/local/bin/dropbox \
  && usermod --shell /bin/bash nobody \
  && chmod 0777 /data

# Prevent automatic updates
install -dm0 /data/.dropbox-dist

exit 0
