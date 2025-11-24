#!/usr/bin/env bash

_update_package() {
  local _OLD_VERSION _NEW_VERSION _RESPONSE

  eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
  _OLD_VERSION="$pkgver"

  _RESPONSE=$(curl -Is "https://www.ocenaudio.com/downloads/index.php/ocenaudio_archlinux.pkg.tar.zst")
  _NEW_VERSION=$(
    grep -Pom1 '(?<=filename="ocenaudio_archlinux_)[0-9\.]+(?=\.pkg\.tar\.zst")' <<< "${_RESPONSE:?}"
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
