ARG VERSION=${VERSION:-[VERSION]}

FROM python:${VERSION}-slim as builder

ARG VERSION

RUN apt-get update && \
    apt-get install -qq -y --no-install-recommends \
    wget

RUN cd /usr/local \
  && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - \
  && wget -O /usr/local/bin/dropbox "https://www.dropbox.com/download?dl=packages/dropbox.py"

FROM python:${VERSION}-slim

COPY --from=builder \
    /usr/local/.dropbox-dist \
    /usr/local/.dropbox-dist

COPY --from=builder \
    /usr/local/bin/dropbox \
    /usr/local/bin/

COPY ./supervisord.conf /etc/supervisord.conf

# package 
COPY ./install-packages.sh /usr/local/bin/install-packages
RUN apt-get update \
  && INSTALL_VERSION=$VERSION install-packages \
  && rm /usr/local/bin/install-packages;

# https://wiki.archlinux.org/title/dropbox
# ~/.dropbox - Dropbox's configuration directory
# ~/Dropbox - Dropbox's download directory (default)
VOLUME ["/data"]

ENV HOME=/data
ENV PATH="/usr/local/.dropbox-dist:${PATH}"
WORKDIR /data

ENTRYPOINT ["supervisord"]
CMD ["-c", "/etc/supervisord.conf"]
