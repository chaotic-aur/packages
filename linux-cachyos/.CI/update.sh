#!/usr/bin/env bash

UPSTREAM_REPO="https://github.com/CachyOS/linux-cachyos.git"
TMPDIR=$(mktemp -d)

git clone "$UPSTREAM_REPO" "$TMPDIR" &>/dev/null || echo "Failed to clone upstream repository"

_PKG="linux-cachyos"

# Run this before comparing to avoid unnecessary diffs
shfmt -w "$TMPDIR/$_PKG/PKGBUILD"

if [[ $(diff -ruN ungoogled-chromium/PKGBUILD "$TMPDIR/PKGBUILD") != "" ]]; then
  rsync -a --exclude "aur" "$TMPDIR/$_PKG/" "$_PKG" || echo "Failed to copy files"
fi
