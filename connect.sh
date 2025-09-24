#!/usr/bin/env bash

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

CONFIG=$(realpath "$1")

cd "${0%/*}" || exit 1

RANDOMHOST=$(openssl rand -hex 12)
CONFIGHOST=$(grep '^remote ' "$CONFIG" | awk '{ print $2; }')
REMOTEPORT=$(grep '^remote ' "$CONFIG" | awk '{ print $3; }')
REMOTEHOST=$(dig +short +aaonly "$RANDOMHOST.$CONFIGHOST" | head -n1)

_patch_config() {
  grep -vE '^(remote |remote-random-hostname|auth-federate|auth-user-pass|auth-retry interact)' "$1"
}

_print_auth() {
  printf 'N/A\n%s\n' "$1"
}

_connect() {
  local AUTH="$1"
  ./bin/openvpn \
    --config <(_patch_config "$CONFIG") --auth-user-pass <(_print_auth "$AUTH") \
    --verb 3 --remote "$REMOTEHOST" "$REMOTEPORT"
}

SSO=$(_connect 'ACS::35001' | sed -rn -e 's/^.*(AUTH_FAILED,CRV1.*)$/\1/p')

URL=$(echo "$SSO" | grep -Eo 'https://.+')
SID=$(echo "$SSO" | cut -f 3 -d :)

[ -n "$URL" ] || exit 1
[ -n "$SID" ] || exit 1

printf '%s\n' "$URL"

_saml_server() {
  local RESPONSE
  RESPONSE=$(
    printf 'HTTP/1.1 200 OK\r\n\r\n OK\r\n' |
      nc -I2048 -w1 -l 127.0.0.1 35001 |
      sed -rn -e 's/^.*SAMLResponse=([^&]+).*$/\1\n/p'
  )
  local ENCODED
  ENCODED="${RESPONSE//+/ }"
  printf '%b' "${ENCODED//%/\\x}"
}

SAML=$(_saml_server)

_connect "CRV1::${SID}::${SAML}"
