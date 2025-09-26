#!/usr/bin/env sh
set -ex

test -n "$1" || exit 1
test -n "$2" || exit 1

_VERSION_A="$1"
_VERSION_B="$2"

_PATCH_A="patches/openvpn-$_VERSION_A.patch"
_PATCH_B="patches/openvpn-$_VERSION_B.patch"

test -f "$_PATCH_A"

git clone https://github.com/OpenVPN/openvpn.git openvpn.git
cd openvpn.git
git switch --detach "tags/v$_VERSION_B"

patch -p1 <"../$_PATCH_A"
git diff >"../$_PATCH_B"
