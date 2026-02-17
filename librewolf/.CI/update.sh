#!/usr/bin/env bash

_update_package() (
  eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
  eval "$(grep -E '^: \${_pkgrel' PKGBUILD)"
  _OLD_VERSION="$pkgver-$pkgrel"
  _OLD_SUM="$(grep -m1 'update-cksum' PKGBUILD | grep -Pom1 '[0-9a-f]{64}')"

  _RESPONSE=$(curl -Ssf "$url/releases.atom")
  _NEW_VERSION=$(
    echo "${_RESPONSE:?}" \
      | grep -Pom1 '(?<=/releases/tag/)[0-9\.-]+(?=")'
  )

  if (($(vercmp "${_NEW_VERSION:?}" "${_OLD_VERSION:?}") > 0)); then
    _RESPONSE=$(curl -Ssf "https://codeberg.org/api/packages/librewolf/generic/librewolf-source/${_NEW_VERSION}/librewolf-${_NEW_VERSION}.source.tar.gz.sha256sum")
    _SUM=$(
      echo "${_RESPONSE:?}" \
        | cut -d' ' -f1
    )

    sed -E \
      -e "s@${_OLD_SUM}@${_SUM##*-}@" \
      -e 's&^(: \$\{_pkgrel):=.*&\1:='"${_NEW_VERSION##*-}\}&" \
      -e 's&^(pkgver)=.*$&\1='"${_NEW_VERSION%%-*}&" \
      -e 's&^(pkgrel)=.*$&\1='"${_NEW_VERSION##*-}&" \
      -i "PKGBUILD"

    sed -E \
      -e "s@${_OLD_SUM}@${_SUM##*-}@" \
      -e 's@^(\s*pkgver\s*=\s*).*$@\1'"${_NEW_VERSION%%-*}@" \
      -e 's@^(\s*pkgrel\s*=\s*).*$@\1'"${_NEW_VERSION##*-}@" \
      -e '/source = /s&'"${_OLD_VERSION%-*}-${_pkgrel:-1}&${_NEW_VERSION}&g" \
      -i ".SRCINFO"
  fi
)
_update_package
unset -f _update_package
