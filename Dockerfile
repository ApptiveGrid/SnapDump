FROM debian:12-slim

# runtime libraries of the Pharo VM; curl and unzip are for fetching it below
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates curl unzip libffi8 libfreetype6 libsdl2-2.0-0 libssl3 libgit2-1.5 libssh-4 && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# A pinned Pharo 13 image, so that a rebuild starts from the same one. The VM is the stable
# one of Pharo 13 from get.pharo.org, which writes the headless launcher /opt/pharo.
ARG PHARO_IMAGE=https://files.pharo.org/image/130/Pharo13.0-SNAPSHOT.build.750.sha.81f614957c.arch.64bit.zip
RUN \
  curl -fsSL -o pharo-image.zip "$PHARO_IMAGE" && \
  mkdir pharo-image && unzip -q pharo-image.zip -d pharo-image && \
  mv pharo-image/*.image SnapDump.image && \
  mv pharo-image/*.changes SnapDump.changes && \
  mv pharo-image/*.sources . && \
  rm -rf pharo-image pharo-image.zip && \
  curl -fsSL https://get.pharo.org/64/vm130 | bash

COPY build.st start.st /opt/
COPY source /opt/source

# shown by GET /api/v2/version; docker build --build-arg VERSION=... (make docker)
ARG VERSION=unknown
RUN \
  /opt/pharo /opt/SnapDump.image st --save --quit /opt/build.st && \
  /opt/pharo /opt/SnapDump.image eval --save "SDServer version: '$VERSION'"

CMD ["/opt/pharo", "/opt/SnapDump.image", "--no-default-preferences", "st", "/opt/start.st"]

EXPOSE 5555

HEALTHCHECK CMD curl --fail -H 'Connection: close' http://localhost:5555/health/sunit/SnapDumpHealth || exit 1
