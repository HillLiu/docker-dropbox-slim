ARG VERSION=${VERSION:-3.8.0}

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
    /usr/local/dropbox-dist

COPY --from=builder \
    /usr/local/bin/dropbox \
    /usr/local/bin/

RUN apt-get update && \
    apt-get install -qq -y --no-install-recommends \
    libglib2.0-0 \
    libglapi-mesa \
    libxext-dev \
    libxdamage1 \
    libxcb-glx0 \
    libxcb-dri2-0 \
    libxcb-dri3-0 \
    libxcb-present0 \
    libxcb-sync1 \
    libxshmfence1 \
    libxxf86vm1

RUN mkdir /data \
  && chmod 0755 /usr/local/bin/dropbox \
  && usermod --shell /bin/bash nobody \
  && chmod 0777 /data

# Prevent automatic updates 
RUN install -dm0 /data/.dropbox-dist

# https://wiki.archlinux.org/title/dropbox
# ~/.dropbox - Dropbox's configuration directory
# ~/Dropbox - Dropbox's download directory (default)
VOLUME ["/data"]

ENV HOME=/data
ENV PATH="/usr/local/dropbox-dist:${PATH}"
WORKDIR /data

ENTRYPOINT ["dropboxd"]
