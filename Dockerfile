# syntax=docker/dockerfile:1

ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-alpine:v0.4.2

FROM ghcr.io/chukysoria/docker-unrar:v1.0.7 as unrar

FROM ${BUILD_FROM} 

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_EXT_RELEASE="v1.4.0"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"
# hard set UTC in case the user does not define it
ENV TZ="Etc/UTC"

RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    ffmpeg=6.1-r1 \
    libxml2=2.11.6-r0 \
    libxslt=1.1.39-r0 \
    mediainfo=23.11-r0 \
    python3=3.11.6-r1 && \
  echo "**** install bazarr ****" && \
  mkdir -p \
    /app/bazarr/bin && \
  curl -o \
    /tmp/bazarr.zip -L \
    "https://github.com/morpheus65535/bazarr/releases/download/${BUILD_EXT_RELEASE}/bazarr.zip" && \
  unzip \
    /tmp/bazarr.zip -d \
    /app/bazarr/bin && \
  rm -Rf /app/bazarr/bin/bin && \
  echo "UpdateMethod=docker\nBranch=master\nPackageVersion=${BUILD_VERSION}\nPackageAuthor=chukyserver.io" > /app/bazarr/package_info && \
  curl -o \
    /app/bazarr/bin/postgres-requirements.txt -L \
    "https://raw.githubusercontent.com/morpheus65535/bazarr/${BUILD_EXT_RELEASE}/postgres-requirements.txt" && \
  echo "**** Install requirements ****" && \
  sed -i 's/--only-binary=Pillow//' /app/bazarr/bin/requirements.txt && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip && \
  pip install -U --no-cache-dir \
    --extra-index-url="https://gitlab.com/api/v4/projects/49075787/packages/pypi/simple" \
    -r /app/bazarr/bin/requirements.txt \
    -r /app/bazarr/bin/postgres-requirements.txt && \
  echo "**** clean up ****" && \
  rm -rf \
    $HOME/.cache \
    /tmp/*

# add local files
COPY root/ /

# add unrar
COPY --from=unrar /usr/bin/unrar-alpine /usr/bin/unrar

# ports and volumes
EXPOSE 6767

VOLUME /config
