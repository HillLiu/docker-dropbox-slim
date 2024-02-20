#!/bin/sh

###
# Environment ${INSTALL_VERSION} pass from Dockerfile
###

NFS_DEPS="nfs-kernel-server nfs-common rpcbind sed"
NETWORK_DEPS="iproute2 procps"
UTIL_DEPS="supervisor sudo python3-gpg libterm-readkey-perl"
INSTALL="$NFS_DEPS $NETWORK_DEPS $UTIL_DEPS"

DEBIAN_FRONTEND=noninteractive apt install -qq -y --no-install-recommends $INSTALL 

#/* put your install code here */#

rm -rf /data \
  && mkdir /data \
  && ln -s /usr/local/.dropbox-dist /data/.dropbox-dist \
  && chmod 0755 /usr/local/sbin/dropbox \
  && chmod 0777 -R /data || exit 2 

# Prevent automatic updates
# install -dm0 /data/.dropbox-dist || exit 1 

# /* For NfS */ #
mkdir -p /var/lib/nfs/rpc_pipefs /var/lib/nfs/v4recovery
echo "rpc_pipefs    /var/lib/nfs/rpc_pipefs rpc_pipefs      defaults        0       0" >> /etc/fstab
echo "nfsd  /proc/fs/nfsd   nfsd    auto,defaults        0       0" >> /etc/fstab


# Clean (last section)
mv /var/lib/nfs /var/lib/nfs-tpl
apt-get clean autoclean
apt-get autoremove --yes
apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
rm -rf /var/lib/{apt,dpkg,cache,log}/

exit 0
