#!/usr/bin/env bash

_update_package() {
  local PACKAGE url TMPDIR

  : ${PACKAGE:=$1}
  eval "$(grep -Eo '^(url)=\S+' PKGBUILD)"
  TMPDIR=$(mktemp -d)
  git clone "$url.git" "$TMPDIR" &> /dev/null || echo "Failed to clone upstream repository"

  # Run this before comparing to avoid unnecessary diffs
  shfmt -i 2 -ln=bash -bn -ci -sr -w "$TMPDIR/$PACKAGE/PKGBUILD"

  if [[ $(diff -ruN "PKGBUILD" "$TMPDIR/$PACKAGE/PKGBUILD") != "" ]]; then
    rsync -a --delete --exclude "aur" --exclude ".CI" "$TMPDIR/$PACKAGE/" "." || echo "Failed to copy files"

    # track changes
    grep -E ':\s*"?\s*\$' PKGBUILD > default-options.txt
  fi
}
_update_package linux-cachyos-lts
unset -f _update_package
