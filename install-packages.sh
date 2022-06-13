#!/bin/sh

###
# Environment ${INSTALL_VERSION} pass from Dockerfile
###

INSTALL="libglib2.0-0 libglapi-mesa libxext-dev libxdamage1 libxcb-glx0 libxcb-dri2-0 libxcb-dri3-0 libxcb-present0 libxcb-sync1 libxshmfence1 libxxf86vm1"

echo "###"
echo "# Will install"
echo "###"
echo ""
echo $INSTALL
echo ""


#/* put your install code here */#

mkdir /data \
  && chmod 0755 /usr/local/bin/dropbox \
  && usermod --shell /bin/bash nobody \
  && chmod 0777 /data

# Prevent automatic updates
install -dm0 /data/.dropbox-dist

exit 0
