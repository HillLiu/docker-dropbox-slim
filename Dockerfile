ARG VERSION=${VERSION:-3.8.0}

FROM python:${VERSION}-slim

RUN apt-get update && \
    apt-get install -qq -y --no-install-recommends \
    wget \
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
  && cd /usr/local \
  && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - \
  && wget -O /usr/local/bin/dropbox "https://www.dropbox.com/download?dl=packages/dropbox.py" \
  && chmod 0755 /usr/local/bin/dropbox

ENV HOME=/data
ENV PATH="/usr/local/.dropbox-dist:${PATH}"
WORKDIR /data


# https://wiki.archlinux.org/title/dropbox
# ~/.dropbox - Dropbox's configuration directory
# ~/Dropbox - Dropbox's download directory (default)
VOLUME ["/data/Dropbox", "/data/.dropbox"]

# Prevent automatic updates 
RUN install -dm0 /data/.dropbox-dist && install -dm0 /usr/local/.dropbox-dist

ENTRYPOINT ["dropboxd"]
