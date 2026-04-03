#!/usr/bin/env bash

_update_package() {
  local _OLD_VERSION _NEW_VERSION _NEW_PKGVER _NEW_PKGREL _RESPONSE _TAG

  eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
  _OLD_VERSION="$pkgver-$pkgrel"

  _NEW_VERSION=$(LC_ALL=C pacman -Si vlc | grep -Pom1 '^Version\s+:\s+\K\S+')
  _NEW_PKGVER="${_NEW_VERSION%%-*}"
  _NEW_PKGREL="${_NEW_VERSION##*-}"

  _RESPONSE=$(
    curl -Ssf --max-redirs 3 --no-progress-meter "$url/tags.atom" 2> /dev/null
  )
  _TAG=$(
    grep -Po '(/releases/tag/[^0-9]*)\K[0-9\.-]+(?=")' <<< "${_RESPONSE:?}" \
      | grep "$_NEW_PKGVER" | head -1
  )

  if (($(vercmp "${_NEW_VERSION:?}" "${_OLD_VERSION:?}") > 0)); then
    sed -E \
      -e 's&^(\s*pkgver\s*=\s*).*$&\1'"${_NEW_PKGVER}&" \
      -e 's&^(\s*pkgrel\s*=\s*).*$&\1'"${_NEW_PKGREL}&" \
      -e 's&^(: \$\{_tag:)=\S+\}$&\1='"${_TAG}"'\}&' \
      -e '/source = /s&'"${pkgver}(-[0-9])?&${_TAG}&g" \
      -i "PKGBUILD" ".SRCINFO"
  fi
}
_update_package
unset -f _update_package
