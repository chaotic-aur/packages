#!/usr/bin/env bash

: ${PACKAGE:=librewolf}

UPSTREAM_REPO="https://codeberg.org/librewolf/source"

_OLD_VERSION=$(LANG=C LC_ALL=C pacman -Si chaotic-aur/$PACKAGE | grep -Pom1 '^Version\s+:\s+\K\S+')

_RESPONSE=$(curl -Ssf "${UPSTREAM_REPO}/releases")
_TAG=$(
  echo "$_RESPONSE" |
    grep -Eom1 '/tag/\S+"' |
    sed -E 's&^.*/([0-9\.]+-[0-9]+)"$&\1&'
)

if [ $(vercmp "$_TAG" "$_OLD_VERSION") -gt 0 ]; then
  _RESPONSE=$(curl -Ssf "https://gitlab.com/api/v4/projects/32320088/packages/generic/librewolf-source/${_TAG}/librewolf-${_TAG}.source.tar.gz.sha256sum")

  _SUM=$(
    echo "$_RESPONSE" |
      cut -d' ' -f1
  )

  sed -E \
    -e 's&^(: \$\{_pkgrel):=.*&\1:='"${_TAG##*-}\}&" \
    -e 's&^(: \$\{_cksum):=.*&\1:='"${_SUM##*-}\}&" \
    -e 's&^(pkgver)=.*$&\1='"${_TAG%%-*}&" \
    -e 's&^(pkgrel)=.*$&\1='"${_TAG##*-}&" \
    -i "PKGBUILD"
fi
