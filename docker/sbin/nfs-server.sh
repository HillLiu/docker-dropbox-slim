#!/usr/bin/env sh

trap "stop; exit 0;" SIGTERM SIGINT TERM
trap "reload" USR2

syncBackup() {
  echo
}

reload() {
  echo "Execute hot reload --->"
  syncBackup
  exportfs -ra
  echo "Hot reload result --->"
  exportfs -v
}

stop() {
  # We're here because we've seen SIGTERM, likely via a Docker stop command or similar
  # Let's shutdown cleanly
  echo "SIGTERM caught, terminating NFS process(es)..."
  /usr/sbin/exportfs -uav
  /usr/sbin/rpc.nfsd 0
  pid1=$(pidof rpc.nfsd)
  pid2=$(pidof rpc.mountd)
  # For IPv6 bug:
  pid3=$(pidof rpcbind)
  kill -TERM $pid1 $pid2 $pid3 > /dev/null 2>&1
  echo "Terminated."
}

start() {
  MYHOST=$(hostname | awk -F. '{print $1}')
  NFS_STATE_FOLDER="/app/lib/nfs/${MYHOST}/"
  if [ ! -d "/var/lib/nfs" ]; then
    if [ ! -d "$NFS_STATE_FOLDER" ]; then
      echo 'Generating new nfs state folder:'${NFS_STATE_FOLDER}
      mkdir -p ${NFS_STATE_FOLDER}
      cp -a -T /var/lib/nfs-tpl/ "$NFS_STATE_FOLDER"
    fi
    ln -s "$NFS_STATE_FOLDER" /var/lib/nfs
  fi
  chmod 0777 -R /app/lib
  syncBackup
}

daemon() {

  SHARED_DIRECTORY=${HOME}
  SHARED_OPTION=${SHARED_OPTION:-no_subtree_check,no_auth_nlm,insecure}
  ENABLE_ROOT_SYNC=${ENABLE_ROOT_SYNC}
  DEBUG=${DEBUG:-}
  ExportsFile="/etc/exports"

  if [ "x"!="x${SHARED_DIRECTORY}" ]; then
    if grep -q ${SHARED_DIRECTORY} $ExportsFile; then
      echo "${SHARED_DIRECTORY} already exists in ${ExportsFile}"
    else
      echo "Writing SHARED_DIRECTORY to /etc/exports file"
      if [ -n "${ENABLE_ROOT_SYNC}" ]; then
        NO_ROOT_SQUASH="no_root_squash,"
      else
        NO_ROOT_SQUASH=""
      fi
      echo "${SHARED_DIRECTORY} {{PERMITTED}}({{READ_ONLY}},fsid=0,{{SYNC}},${NO_ROOT_SQUASH}${SHARED_OPTION})" >> /etc/exports
    fi
  fi

  # Check if the PERMITTED variable is empty
  if [ -z "${PERMITTED}" ]; then
    echo "The PERMITTED environment variable is unset or null, defaulting to '*'."
    echo "This means any client can mount."
    /bin/sed -i "s/{{PERMITTED}}/*/g" /etc/exports
  else
    echo "The PERMITTED environment variable is set."
    echo "The permitted clients are: ${PERMITTED}."
    /bin/sed -i "s/{{PERMITTED}}/"${PERMITTED}"/g" /etc/exports
  fi

  # Check if the READ_ONLY variable is set (rather than a null string) using parameter expansion
  if [ -z ${READ_ONLY+y} ]; then
    echo "The READ_ONLY environment variable is unset or null, defaulting to 'rw'."
    echo "Clients have read/write access."
    /bin/sed -i "s/{{READ_ONLY}}/rw/g" /etc/exports
  else
    echo "The READ_ONLY environment variable is set."
    echo "Clients will have read-only access."
    /bin/sed -i "s/{{READ_ONLY}}/ro/g" /etc/exports
  fi

  # Check if the SYNC variable is set (rather than a null string) using parameter expansion
  if [ -z "${SYNC+y}" ]; then
    echo "The SYNC environment variable is unset or null, defaulting to 'async' mode".
    echo "Writes will not be immediately written to disk."
    /bin/sed -i "s/{{SYNC}}/async/g" /etc/exports
  else
    echo "The SYNC environment variable is set, using 'sync' mode".
    echo "Writes will be immediately written to disk."
    /bin/sed -i "s/{{SYNC}}/sync/g" /etc/exports
  fi

  # Partially set 'unofficial Bash Strict Mode' as described here: http://redsymbol.net/articles/unofficial-bash-strict-mode/
  # We don't set -e because the pidof command returns an exit code of 1 when the specified process is not found
  # We expect this at times and don't want the script to be terminated when it occurs
  set -uo pipefail
  IFS=$' \n\t'

  # This loop runs till until we've started up successfully
  while true; do

    # Check if NFS is running by recording it's PID (if it's not running $pid will be null):
    pid=$(pidof rpc.mountd)

    # If $pid is null, do this to start or restart NFS:
    while [ -z "$pid" ]; do
      echo "Displaying /etc/exports contents:"
      cat /etc/exports
      echo ""

      # Normally only required if v3 will be used
      # But currently enabled to overcome an NFS bug around opening an IPv6 socket
      echo "Starting rpcbind..."
      /sbin/rpcbind -w
      echo "Displaying rpcbind status..."
      /sbin/rpcinfo

      echo "Starting NFS in the background..."
      /usr/sbin/rpc.nfsd --lease-time 10 --grace-time 10 --debug 8 --no-udp -N 3
      echo 'nfsv4gracetime: '$(cat /proc/fs/nfsd/nfsv4gracetime)
      echo 'nfsv4leasetime: '$(cat /proc/fs/nfsd/nfsv4leasetime)
      echo "Exporting File System..."
      if /usr/sbin/exportfs -rv; then
        /usr/sbin/exportfs
      else
        echo "Export validation failed, exiting..."
        exit 1
      fi
      echo "Starting Mountd in the background..."
      /usr/sbin/rpc.mountd --debug all --no-udp -N 3
      # --exports-file /etc/exports

      # Check if NFS is now running by recording it's PID (if it's not running $pid will be null):
      pid=$(pidof rpc.mountd)

      # If $pid is null, startup failed; log the fact and sleep for 2s
      # We'll then automatically loop through and try again
      if [ -z "$pid" ]; then
        echo "Startup of NFS failed, sleeping for 2s, then retrying..."
        sleep 2
      fi
    done

    # Break this outer loop once we've started up successfully
    # Otherwise, we'll silently restart and Docker won't know
    echo "Startup successful."
    break

  done

  while true; do
    # Check if NFS is STILL running by recording it's PID (if it's not running $pid will be null):
    pid=$(pidof rpc.mountd)
    # If it is not, lets kill our PID1 process (this script) by breaking out of this while loop:
    # This ensures Docker observes the failure and handles it as necessary
    if [ -z "$pid" ]; then
      echo "NFS has failed, exiting, so Docker can restart the container..."
      break
    fi

    # If it is, give the CPU a rest
    sleep 1
    if [ ! -z "$DEBUG" ]; then
      exit 0
    fi
  done

  sleep 1
  exit 1
}

start
daemon
