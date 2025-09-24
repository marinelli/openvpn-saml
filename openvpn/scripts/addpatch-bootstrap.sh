#!/usr/bin/env sh
set -ex

apk update
apk upgrade

apk add git patch

find /var/cache/apk/ -mindepth 1 -delete
