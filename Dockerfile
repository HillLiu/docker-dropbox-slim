ARG VERSION=${VERSION:-[VERSION]}

FROM python:${VERSION}-slim as builder

ARG VERSION

RUN apt-get update && \
    apt-get install -qq -y --no-install-recommends \
    wget

# https://www.dropbox.com/download?plat=lnx.x86_64 
ARG DROPBOX_DL=https://www.dropbox.com/download?plat=lnx.x86_64
ARG DROPBOX_PY="https://linux.dropbox.com/packages/dropbox.py"

RUN cd /usr/local \
  && wget -O - "${DROPBOX_DL}" | tar xzf -

RUN wget -O /usr/local/bin/dropbox "${DROPBOX_PY}"

FROM --platform=linux/x86_64 python:${VERSION}-slim

COPY --from=builder \
    /usr/local/.dropbox-dist \
    /usr/local/.dropbox-dist

COPY --from=builder \
    /usr/local/bin/dropbox \
    /usr/local/bin/

# package 
COPY ./install-packages.sh /usr/local/bin/install-packages
RUN apt-get update \
  && INSTALL_VERSION=$VERSION install-packages \
  && rm /usr/local/bin/install-packages;

# Prevent automatic updates
RUN install -dm0 /data/.dropbox-dist

# https://wiki.archlinux.org/title/dropbox
# ~/.dropbox - Dropbox's configuration directory
# ~/Dropbox - Dropbox's download directory (default)
VOLUME ["/data"]

ENV HOME=/data
ENV PATH="/data/.dropbox-dist:/usr/local/.dropbox-dist:${PATH}"
WORKDIR /data

COPY ./docker/entrypoint.sh /entrypoint.sh
COPY ./docker/supervisord.conf /etc/
ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
