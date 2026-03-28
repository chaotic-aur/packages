#!/usr/bin/env bash

_update_package() {
  local _OLD_VERSION _NEW_VERSION _RESPONSE _HASH_L10N_OLD _HASH_L10N_NEW

  eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
  _OLD_VERSION="$pkgver"

  _RESPONSE=$(
    curl -Ssf --max-redirs 3 --no-progress-meter "$url/releases.atom" 2> /dev/null
  )
  _NEW_VERSION=$(
    grep -Po '(/releases/tag/[^0-9]*)\K[0-9\.-]+(?=")' <<< "${_RESPONSE:?}" \
      | head -1
  )

  _HASH_L10N_OLD=$(grep -Pom1 '\/BrowserWorks\/l10n\/archive\/\K[0-9a-f]{40}' ".SRCINFO")

  _RESPONSE=$(
    curl -Ssf --max-redirs 3 --no-progress-meter "$url/tree/${_NEW_VERSION:?}/waterfox/browser" 2> /dev/null
  )
  _HASH_L10N_NEW=$(
    grep -Po '\/BrowserWorks\/l10n\/tree\/\K[0-9a-f]{40}' <<< "${_RESPONSE:?}" \
      | head -1
  )

  if (($(vercmp "${_NEW_VERSION:?}" "${_OLD_VERSION:?}") > 0)); then
    sed -E \
      -e 's&^(\s*pkgver\s*=\s*).*$&\1'"${_NEW_VERSION}&" \
      -e 's&^(\s*pkgrel\s*=\s*).*$&\11&' \
      -i "PKGBUILD" ".SRCINFO"

    sed -E \
      -e '/source = /s&'"${_OLD_VERSION}&${_NEW_VERSION}&g" \
      -e '/source = /s&'"${_HASH_L10N_OLD}&${_HASH_L10N_NEW}&g" \
      -i ".SRCINFO"
  fi
}
_update_package
unset -f _update_package
