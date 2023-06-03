#!/usr/bin/env sh

# docker entrypoint script
server() {
  echo ${APP}
  sed -i "s|\[app\]|${APP}|g" /etc/xdg/openbox/menu.xml
  # bootstrap
  chown app:app /app /dev/stdout && exec gosu app supervisord
}

if [ "$1" = 'server' ]; then
  server
else
  exec "$@"
fi
