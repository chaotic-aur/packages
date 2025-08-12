#!/usr/bin/env bash

_update_package() {
  local _OLD_VERSION _NEW_VERSION _RESPONSE

  eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
  _OLD_VERSION="$pkgver"

  _RESPONSE=$(curl -Ssf "$url/releases.atom")
  _NEW_VERSION=$(
    echo "${_RESPONSE:?}" |
      grep -Pom1 '(?<=/releases/tag/v)[0-9\.-]+(?=")'
  )

  if [[ "${_NEW_VERSION:?}" ] > "${_OLD_VERSION:?}" ]]; then
    sed -E \
      -e 's&^(pkgver)=.*$&\1='"${_NEW_VERSION:?}&" \
      -e 's&^(pkgrel)=.*$&\1=1&' \
      -i "PKGBUILD"

    sed -E \
      -e 's&^(\s*pkgver) = .*$&\1 = '"${_NEW_VERSION:?}&" \
      -e 's&^(\s*pkgrel) = .*$&\1 = 1&' \
      -i ".SRCINFO"
  fi
}
_update_package
unset -f _update_package
