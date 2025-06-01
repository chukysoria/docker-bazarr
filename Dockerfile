# syntax=docker/dockerfile:1@sha256:9857836c9ee4268391bb5b09f9f157f3c91bb15821bb77969642813b0d00518d

ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-alpine:v0.8.2-3.22@sha256:73c5f12335adbe9127931176a85e6c745d32ac9367bca6638a9bbd48febb27e2
FROM ghcr.io/chukysoria/docker-unrar:v1.1.7@sha256:7bcb08a561c9c3e5bf46296ec3f550b369cbd4236c597e88b7d66103dd7ce1fc AS unrar

FROM ${BUILD_FROM}

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_EXT_RELEASE="v1.5.2"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"
# hard set UTC in case the user does not define it
ENV TZ="Etc/UTC"

RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    ffmpeg=6.1.2-r1 \
    libxml2=2.13.4-r6 \
    libxslt=1.1.42-r2 \
    mediainfo=24.11-r0 \
    python3=3.12.10-r1 && \
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
