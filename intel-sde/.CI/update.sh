#!/usr/bin/env bash

_update() {
  local _pkgver _response _url _sha _v1 _v2 _regex
  _pkgver=$(grep -Pom1 '_pkgver:=\S+::\K[\d.-]+' PKGBUILD)

  _response=$(curl -ssf "https://www.intel.com/content/www/us/en/download/684897/intel-software-development-emulator.html")
  _response=$(sed 's/</\n</g;s/>/>\n/g' <<< "${_response:?}")
  _response=$(grep -E '(https:|SHA256)' <<< "${_response:?}" | grep -E -A1 -- '-lin\.tar\.xz"' | sed -E 's/.*/\L&/')
  _url=$(grep -Pom1 'https://\S+lin.tar.xz(?=")' <<< "${_response:?}")
  _sha=$(grep -Pom1 '(?<=sha256: )[a-f0-9]+' <<< "${_response:?}")

  _v1=$(grep -Pom1 '/\K[0-9]+(?=/)' <<< "${_url:?}")
  _v2=$(grep -Pom1 '/sde-external-\K[0-9\.-]+(?=-lin\.tar\.xz)' <<< "${_url:?}")

  if [ $(vercmp "${_v2:?}" "${_pkgver:?}") -gt 0 ]; then
    if curl -Issf "${_url:?}" > /dev/null; then
      _regex=$(printf '/_pkgver:=/c : ${_pkgver:=%s::%s}' "${_v1:?}" "${_v2:?}")
      sed -E -e "${_regex:?}" -e 's&^(pkgrel)=\S+&\1=1&' \
        -e "/sha256sums=\('[a-f0-9]{64}'\)/c sha256sums=('${_sha:?}')" \
        -i PKGBUILD

      _regex=$(printf '/pkgver = /s&\S+$&%s&' "${_v2%%-*}")
      sed -E -e "${_regex:?}" -e 's&\b(pkgrel) = \S+$&\1 = 1&' \
        -e "/source = https:/s&\S+\$&${_url:?}&" \
        -e "/sha256sums = [a-f0-9]{64}/s&\S+\$&${_sha:?}&" \
        -i .SRCINFO
    fi
  fi
}
_update
unset -f _update
