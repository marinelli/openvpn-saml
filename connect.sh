#!/usr/bin/env bash
set -e

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

CONFIG=$(realpath "$1")

cd "${0%/*}"

[ -f 'bin/openvpn' ]
[ -f 'bin/update-systemd-resolved' ]

IFS=" " read -r -a REMOTE <<<"$(grep '^remote ' "$CONFIG")"
REMOTEHOST="${REMOTE[1]}"
REMOTEPORT="${REMOTE[2]}"
[ -n "$REMOTEHOST" ]
[ -n "$REMOTEPORT" ]

RANDOMHOST=$(cat /dev/random | tr -dc 'a-z0-9' | head -c24)
REMOTEADDR=$(dig +short +aaonly "${RANDOMHOST}.${REMOTEHOST}" | head -n1)
[ -n "$REMOTEADDR" ]

_connect() {
  local AUTH="$1"
  local RESOLVE='bin/update-systemd-resolved'
  local FILTER='^(remote |remote-random-hostname|auth-federate|auth-user-pass|auth-retry interact)'
  ./bin/openvpn \
    --config <(grep -vE "$FILTER" "$CONFIG") --auth-user-pass <(printf 'N/A\n%s\n' "$AUTH") \
    --script-security 2 --up "$RESOLVE" --up-restart --down "$RESOLVE" --down-pre \
    --verb 2 --dhcp-option DOMAIN-ROUTE . --remote "$REMOTEADDR" "$REMOTEPORT"
}

SSO=$(_connect 'ACS::35001' | sed -rn -e 's/^.*(AUTH_FAILED,CRV1.*)$/\1/p')

URL=$(printf '%s\n' "$SSO" | grep -Eo 'https://.+')
SID=$(printf '%s\n' "$SSO" | cut -f 3 -d :)
[ -n "$URL" ]
[ -n "$SID" ]

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
