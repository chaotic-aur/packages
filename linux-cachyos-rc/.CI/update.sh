#!/usr/bin/env bash

_check_options() {
  touch default-options.txt # make sure exists
  local _options_hash_old="$(sha256sum default-options.txt)"
  mv default-options.txt default-options.old.txt

  grep -E ':\s*"?\s*\$' PKGBUILD > default-options.txt
  local _options_hash_new="$(sha256sum default-options.txt)"

  if [ "${_options_hash_old:-old}" != "${_options_hash_new:-new}" ]; then
    echo
    echo ">>> >>> >>> default options changed <<< <<< <<<"
    echo
    diff -U 0 --label old/default-options.txt --label new/default-options.txt default-options.old.txt default-options.txt
    echo
    echo ">>> >>> >>> default options changed <<< <<< <<<"
    echo
  fi
  rm -f default-options.old.txt
}

_update_package() {
  local PACKAGE url TMPDIR

  : ${PACKAGE:=$1}
  eval "$(grep -Eo '^(url)=\S+' PKGBUILD)"
  TMPDIR=$(mktemp -d)
  git clone "$url.git" "$TMPDIR" &> /dev/null || echo "Failed to clone upstream repository"

  # Run this before comparing to avoid unnecessary diffs
  shfmt -w "$TMPDIR/$PACKAGE/PKGBUILD"

  if [[ $(diff -ruN "PKGBUILD" "$TMPDIR/$PACKAGE/PKGBUILD") != "" ]]; then
    rsync -a --exclude "aur" "$TMPDIR/$PACKAGE/" "." || echo "Failed to copy files"
  fi

  _check_options
}
_update_package linux-cachyos-rc
unset -f _update_package
unset -f _check_options
