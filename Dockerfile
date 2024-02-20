ARG VERSION=${VERSION:-[VERSION]}

FROM python:${VERSION}-slim as builder

ARG VERSION

RUN apt-get update \
  && apt-get install -qq -y --no-install-recommends \
    wget

# https://www.dropbox.com/download?plat=lnx.x86_64
ARG DROPBOX_DL=https://www.dropbox.com/download?plat=lnx.x86_64

RUN cd /usr/local \
  && wget -O - "${DROPBOX_DL}" | tar xzf -

# ARG DROPBOX_PY="https://linux.dropbox.com/packages/dropbox.py"
# RUN wget -O /usr/local/bin/dropbox "${DROPBOX_PY}"

FROM --platform=linux/x86_64 python:${VERSION}-slim

COPY --from=builder \
  /usr/local/.dropbox-dist \
  /usr/local/.dropbox-dist

# package
COPY ./docker/sbin /usr/local/sbin
COPY ./install-packages.sh /usr/local/bin/install-packages
RUN apt-get update \
  && INSTALL_VERSION=$VERSION install-packages \
  && rm /usr/local/bin/install-packages

# https://wiki.archlinux.org/title/dropbox
# ~/.dropbox - Dropbox's configuration directory
# ~/Dropbox - Dropbox's download directory (default)
VOLUME ["/data"]

ENV HOME=/data \
  PATH="/data/.dropbox-dist:/usr/local/.dropbox-dist:${PATH}" \
  DROPBOXUSER=${DROPBOXUSER:-#65534}
WORKDIR /data

COPY ./docker/etc /etc/
ENTRYPOINT ["entrypoint.sh"]
CMD ["server"]
