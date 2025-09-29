#!/usr/bin/env bash

_update_package() (
  local _OLD_VERSION _NEW_VERSION _RESPONSE

  eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
  _OLD_VERSION="$pkgver"

  _RESPONSE=$(curl -Ssf "$url/tags.atom")
  _NEW_VERSION=$(
    echo "${_RESPONSE:?}" \
      | grep -Pom1 '(?<=/releases/tag/v)[0-9\.-]+(?=")'
  )

  if (($(vercmp "${_NEW_VERSION:?}" "${_OLD_VERSION:?}") > 0)); then
    sed -E \
      -e 's&^(\s*pkgver\s*=\s*).*$&\1'"${_NEW_VERSION}&" \
      -e 's&^(\s*pkgrel\s*=\s*).*$&\11&' \
      -i "PKGBUILD" ".SRCINFO"
  fi
)
_update_package
unset -f _update_package
