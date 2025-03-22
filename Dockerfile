# syntax=docker/dockerfile:1@sha256:4c68376a702446fc3c79af22de146a148bc3367e73c25a5803d453b6b3f722fb

ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-alpine:v0.7.11-3.21@sha256:50e0188b7ee5c3596fd200a60e3234c0f82ca286ab6e68feba6aabf075ca6ecb
FROM ghcr.io/chukysoria/docker-unrar:v1.1.5@sha256:98f21d0ac017ceb96b6be29326178548498f449419e9b06f82b5d2796786bdda AS unrar

FROM ${BUILD_FROM} 

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_EXT_RELEASE="v1.5.1"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"
# hard set UTC in case the user does not define it
ENV TZ="Etc/UTC"

RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    ffmpeg=6.1.2-r1 \
    libxml2=2.13.4-r5 \
    libxslt=1.1.42-r2 \
    mediainfo=24.11-r0 \
    python3=3.12.9-r0 && \
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
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
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

HEALTHCHECK --interval=30s --timeout=30s --start-period=2m --start-interval=5s --retries=5 CMD ["nc", "-z", "localhost", "6767"]
