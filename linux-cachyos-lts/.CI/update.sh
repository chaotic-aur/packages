#!/usr/bin/env bash

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
}
_update_package linux-cachyos-lts
unset -f _update_package
