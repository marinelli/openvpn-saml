#!/usr/bin/env sh
set -ex

_VERSION="$1"
test -n "$_VERSION"

mkdir /src/bin

# install openvpn

_SOURCE="openvpn-${_VERSION}"
_ARCHIVE="${_SOURCE}.tar.gz"
_URL="https://github.com/OpenVPN/openvpn/releases/download/v${_VERSION}/${_ARCHIVE}"

if ! wget -q -O "$_ARCHIVE" "$_URL"; then
  _ARCHIVE="v${_VERSION}.tar.gz"
  _URL="https://github.com/OpenVPN/openvpn/archive/refs/tags/${_ARCHIVE}"
  wget -q -O "$_ARCHIVE" "$_URL"
  export _USE_GIT_TAG='1'
fi

_PATCH="patches/openvpn-${_VERSION}.patch"
test -f "$_PATCH"

mkdir "$_SOURCE"
tar xf "$_ARCHIVE" --strip-components=1 -C "$_SOURCE"

(
  cd "$_SOURCE"
  if [ -n "$_USE_GIT_TAG" ]; then
    autoreconf --verbose --force --install
  fi
  patch -p1 <"../${_PATCH}"
  env LDFLAGS='--static' sh configure --disable-dco --disable-pkcs11 --disable-plugins
  make -j "$(nproc)"
)

cp -a "${_SOURCE}/src/openvpn/openvpn" /src/bin/openvpn
cp -a "${_SOURCE}/COPYRIGHT.GPL" /src/bin/openvpn.LICENSE
strip /src/bin/openvpn
rm -fr "$_SOURCE" "$_ARCHIVE"

# install update-systemd-resolved

_SOURCE="update-systemd-resolved.git"
git clone https://github.com/jonathanio/update-systemd-resolved.git "${_SOURCE}"
cp -a "${_SOURCE}/update-systemd-resolved" /src/bin/update-systemd-resolved
cp -a "${_SOURCE}/LICENSE" /src/bin/update-systemd-resolved.LICENSE
rm -fr "$_SOURCE"
