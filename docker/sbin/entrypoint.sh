#!/usr/bin/env sh

# docker entrypoint script
server() {
  # bootstrap
  supervisord -c /etc/supervisord.conf
}

if [ "$1" = 'server' ]; then
  server
else
  exec "$@"
fi
