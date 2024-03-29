#!/usr/bin/env sh
set -ex

apk update
apk upgrade

apk add \
  gcc make patch pkgconf \
  musl-dev linux-headers \
  openssl-dev openssl-libs-static \
  libnl3-dev libnl3-static \
  libcap-ng-dev libcap-ng-static \
  lzo-dev lz4-dev lz4-static

find /var/cache/apk/ -mindepth 1 -delete
