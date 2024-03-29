#!/usr/bin/env sh
set -ex

test -n "$1" || exit 1

_VERSION="$1"
_ARCHIVE="openvpn-$_VERSION.tar.gz"

# download openvpn
wget -q -O "$_ARCHIVE" \
  "https://github.com/OpenVPN/openvpn/releases/download/v$_VERSION/$_ARCHIVE"

_PATCH="patches/openvpn-$_VERSION.patch"
test -f "$_PATCH" || exit 1

# extract archive
tar xf "$_ARCHIVE"
_SOURCE="openvpn-$_VERSION"
cd "$_SOURCE"

patch -p1 <"../$_PATCH"

env LDFLAGS='--static' sh configure \
  --disable-dco \
  --disable-pkcs11 \
  --disable-plugins

_JOBS=$(nproc)
test "$_JOBS" -gt 0
make -j"$_JOBS"
cp -ai "src/openvpn/openvpn" /src/
strip /src/openvpn

cd -
rm -fr "$_SOURCE" "$_ARCHIVE"
