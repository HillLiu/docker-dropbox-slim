#!/usr/bin/env sh

# docker entrypoint script
server() {
  supervisord -c /etc/supervisord.conf
}

if [ "$1" = 'server' ]; then
  server
else
  exec "$@"
fi
