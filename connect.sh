#!/usr/bin/env bash

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

CONFIG=$(realpath "$1")

cd "${0%/*}" || exit 1

IFS=" " read -r -a REMOTE <<<"$(grep '^remote ' "$CONFIG")"
REMOTEHOST="${REMOTE[1]}"
REMOTEPORT="${REMOTE[2]}"
[ -n "$REMOTEHOST" ] || exit 1
[ -n "$REMOTEPORT" ] || exit 1

RANDOMHOST=$(cat /dev/random | tr -dc 'a-z0-9' | head -c24)
REMOTEADDR=$(dig +short +aaonly "${RANDOMHOST}.${REMOTEHOST}" | head -n1)
[ -n "$REMOTEADDR" ] || exit 1

_patch_config() {
  grep -vE '^(remote |remote-random-hostname|auth-federate|auth-user-pass|auth-retry interact)' "$1"
}

_connect() {
  local AUTH="$1"
  local UPDOWN='/etc/openvpn/update-systemd-resolved'
  local EXTRAS
  if [ -f "$UPDOWN" ]; then
    EXTRAS="--script-security 2 --up $UPDOWN --down $UPDOWN --down-pre"
  fi
  # shellcheck disable=SC2086
  ./bin/openvpn \
    --config <(_patch_config "$CONFIG") --auth-user-pass <(printf 'N/A\n%s\n' "$AUTH") \
    --verb 3 --dhcp-option DOMAIN-ROUTE . $EXTRAS \
    --remote "$REMOTEADDR" "$REMOTEPORT"
}

SSO=$(_connect 'ACS::35001' | sed -rn -e 's/^.*(AUTH_FAILED,CRV1.*)$/\1/p')

URL=$(printf '%s\n' "$SSO" | grep -Eo 'https://.+')
SID=$(printf '%s\n' "$SSO" | cut -f 3 -d :)

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
