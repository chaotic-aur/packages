#!/usr/bin/env bash

_update_package() {
  local _OLD_VERSION _NEW_VERSION _RESPONSE

  eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
  _OLD_VERSION="$pkgver"

  _RESPONSE=$(curl -Ssf "$url/releases.atom")
  _NEW_VERSION=$(
    grep -Pom1 '(/releases/tag/([^0-9]+)?)\K[0-9\.-]+(?=")' <<< "${_RESPONSE:?}"
  )

  if (($(vercmp "${_NEW_VERSION:?}" "${_OLD_VERSION:?}") > 0)); then
    sed -E \
      -e 's&^(\s*pkgver\s*=\s*).*$&\1'"${_NEW_VERSION}&" \
      -e 's&^(\s*pkgrel\s*=\s*).*$&\11&' \
      -i "PKGBUILD" ".SRCINFO"

    sed -E \
      -e '/source = /s&'"${_OLD_VERSION}&${_NEW_VERSION}&g" \
      -i ".SRCINFO"
  fi
}
_update_package
unset -f _update_package
