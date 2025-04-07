#!/usr/bin/env bash

eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
_OLD_VERSION="$pkgver-$pkgrel"

_RESPONSE=$(curl -Ssf "https://gitlab.com/librewolf-community/browser/source/-/releases.atom")
_TAG=$(
  echo "${_RESPONSE:?}" |
    grep -Pom1 '(?<=/releases/)[0-9\.-]+(?=")'
)

if [ "${_TAG:?}" != "${_OLD_VERSION:?}" ]; then
  _RESPONSE=$(curl -Ssf "https://gitlab.com/api/v4/projects/32320088/packages/generic/librewolf-source/${_TAG}/librewolf-${_TAG}.source.tar.gz.sha256sum")

  _SUM=$(
    echo "${_RESPONSE:?}" |
      cut -d' ' -f1
  )

  sed -E \
    -e 's&^(: \$\{_pkgrel):=.*&\1:='"${_TAG##*-}\}&" \
    -e 's&^(: \$\{_cksum):=.*&\1:='"${_SUM##*-}\}&" \
    -e 's&^(pkgver)=.*$&\1='"${_TAG%%-*}&" \
    -e 's&^(pkgrel)=.*$&\1='"${_TAG##*-}&" \
    -i "PKGBUILD"
fi
