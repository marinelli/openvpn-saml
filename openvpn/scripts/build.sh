#!/usr/bin/env sh
set -ex

_VERSION="$1"
test -n "$_VERSION"

mkdir /src/bin

_NPROC=$(nproc)

# install openvpn

_SOURCE="openvpn-$_VERSION"
_ARCHIVE="$_SOURCE.tar.gz"
_URL="https://github.com/OpenVPN/openvpn/releases/download/v$_VERSION/$_ARCHIVE"

if ! wget -q -O "$_ARCHIVE" "$_URL"; then
  _URL="https://build.openvpn.net/downloads/releases/$_ARCHIVE"
fi

if ! wget -q -O "$_ARCHIVE" "$_URL"; then
  _ARCHIVE="v$_VERSION.tar.gz"
  _URL="https://github.com/OpenVPN/openvpn/archive/refs/tags/$_ARCHIVE"
  wget -q -O "$_ARCHIVE" "$_URL"
  export _USE_GIT_TAG='1'
fi

_PATCH="patches/openvpn-$_VERSION.patch"
test -f "$_PATCH"

mkdir "$_SOURCE"
tar xf "$_ARCHIVE" --strip-components=1 -C "$_SOURCE"

(
  cd "$_SOURCE"
  if [ -n "$_USE_GIT_TAG" ]; then
    autoreconf --verbose --force --install
  fi
  patch -p1 <"../$_PATCH"
  env LDFLAGS='--static' sh configure --disable-pkcs11 --disable-plugins
  make -j "$_NPROC"
)

cp -a "$_SOURCE/src/openvpn/openvpn" /src/bin/openvpn
cp -a "$_SOURCE/COPYRIGHT.GPL" /src/bin/openvpn.LICENSE
strip /src/bin/openvpn
rm -fr "$_SOURCE" "$_ARCHIVE"

# install update-systemd-resolved

_SOURCE='update-systemd-resolved.git'
git clone "https://github.com/marinelli/$_SOURCE" "$_SOURCE"
cp -a "$_SOURCE/update-systemd-resolved" /src/bin/update-systemd-resolved
cp -a "$_SOURCE/LICENSE" /src/bin/update-systemd-resolved.LICENSE
rm -fr "$_SOURCE"

# install netcat-openbsd

_SOURCE='netcat-openbsd.git'
git clone -b musl "https://salsa.debian.org/marinelli/$_SOURCE" "$_SOURCE"

(
  cd "$_SOURCE"
  ./patch.sh
  make -j "$_NPROC"
)

cp -a "$_SOURCE/nc" /src/bin/nc
cp -a "$_SOURCE/debian/copyright" /src/bin/nc.LICENSE
strip /src/bin/nc
rm -fr "$_SOURCE"
