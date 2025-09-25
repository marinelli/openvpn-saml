#!/usr/bin/env sh
set -ex

test -n "$1"

# install openvpn

_PROJECT='OpenVPN/openvpn'
_VERSION="$1"
_SOURCE="openvpn-${_VERSION}"
_ARCHIVE="${_SOURCE}.tar.gz"
_URL="https://github.com/${_PROJECT}/releases/download/v${_VERSION}/${_ARCHIVE}"

wget -q -O "$_ARCHIVE" "$_URL"

_PATCH="patches/openvpn-${_VERSION}.patch"
test -f "$_PATCH"

mkdir "$_SOURCE"
tar xf "$_ARCHIVE" --strip-components=1 -C "$_SOURCE"

cd "$_SOURCE"

patch -p1 <"../${_PATCH}"

env LDFLAGS='--static' sh configure \
  --disable-dco \
  --disable-pkcs11 \
  --disable-plugins

make -j "$(nproc)"
cp -a "src/openvpn/openvpn" /src/
strip /src/openvpn

cd -
rm -fr "$_SOURCE" "$_ARCHIVE"

# install update-systemd-resolved

_PROJECT='jonathanio/update-systemd-resolved'
_VERSION=$(wget -qO- "https://api.github.com/repos/${_PROJECT}/releases/latest" | jq -r '.tag_name')
_SOURCE="update-systemd-resolved-${_VERSION}"
_ARCHIVE="${_SOURCE}.tar.gz"
_URL="https://github.com/${_PROJECT}/archive/refs/tags/${_VERSION}.tar.gz"

wget -q -O "$_ARCHIVE" "$_URL"

mkdir "$_SOURCE"
tar xf "$_ARCHIVE" --strip-components=1 -C "$_SOURCE"
cp -a "$_SOURCE/update-systemd-resolved" /src/

rm -fr "$_SOURCE" "$_ARCHIVE"
