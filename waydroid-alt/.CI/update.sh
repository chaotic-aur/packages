#!/usr/bin/env bash

eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
_OLD_VERSION="$pkgver"

_RESPONSE=$(curl -Ssf "$url/releases.atom")
_TAG=$(
  echo "${_RESPONSE:?}" |
    grep -Pom1 '(?<=/releases/tag/)[0-9\.-]+(?=")'
)

if [ "${_TAG:?}" != "${_OLD_VERSION:?}" ]; then
  sed -E \
    -e 's&^(pkgver)=.*$&\1='"${_TAG}&" \
    -e 's&^(pkgrel)=.*$&\1=1&' \
    -i "PKGBUILD"
fi
