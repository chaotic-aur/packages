#!/usr/bin/env bash

: ${PACKAGE:=linux-cachyos-lts}

UPSTREAM_REPO="https://github.com/CachyOS/linux-cachyos.git"
TMPDIR=$(mktemp -d)

git clone "$UPSTREAM_REPO" "$TMPDIR" &>/dev/null || echo "Failed to clone upstream repository"

# Run this before comparing to avoid unnecessary diffs
shfmt -w "$TMPDIR/$PACKAGE/PKGBUILD"

if [[ $(diff -ruN "PKGBUILD" "$TMPDIR/$PACKAGE/PKGBUILD") != "" ]]; then
  rsync -a --exclude "aur" "$TMPDIR/$PACKAGE/" "." || echo "Failed to copy files"
fi
