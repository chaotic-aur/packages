#!/usr/bin/env bash

_update_package() {
  local _OLD_VERSION _NEW_VERSION _RESPONSE _SUM

  eval "$(grep -Eo '^(url|pkgver|pkgrel)=\S+' PKGBUILD)"
  _OLD_VERSION="$pkgver-$pkgrel"

  _RESPONSE=$(curl -Ssf "$url/releases.atom")
  _NEW_VERSION=$(
    echo "${_RESPONSE:?}" \
      | grep -Pom1 '(?<=/releases/tag/)[0-9\.-]+(?=")'
  )

  if (($(vercmp "${_NEW_VERSION:?}" "${_OLD_VERSION:?}") > 0)); then
    _RESPONSE=$(curl -Ssf "https://gitlab.com/api/v4/projects/32320088/packages/generic/librewolf-source/${_NEW_VERSION}/librewolf-${_NEW_VERSION}.source.tar.gz.sha256sum")

    _SUM=$(
      echo "${_RESPONSE:?}" \
        | cut -d' ' -f1
    )

    sed -E \
      -e 's&^(: \$\{_pkgrel):=.*&\1:='"${_NEW_VERSION##*-}\}&" \
      -e 's&^(: \$\{_cksum):=.*&\1:='"${_SUM##*-}\}&" \
      -e 's&^(pkgver)=.*$&\1='"${_NEW_VERSION%%-*}&" \
      -e 's&^(pkgrel)=.*$&\1='"${_NEW_VERSION##*-}&" \
      -i "PKGBUILD"

    makepkg --printsrcinfo > .SRCINFO
  fi
}
_update_package
unset -f _update_package
