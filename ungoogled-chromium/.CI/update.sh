#!/usr/bin/env bash

UPSTREAM_REPO="https://github.com/ungoogled-software/ungoogled-chromium-archlinux.git"
TMPDIR=$(mktemp -d)

git clone "$UPSTREAM_REPO" "$TMPDIR" &>/dev/null || echo "Failed to clone upstream repository"

# Run this before comparing to avoid unnecessary diffs
shfmt -w "$TMPDIR/PKGBUILD"

if [[ $(diff -ruN ungoogled-chromium/PKGBUILD "$TMPDIR/PKGBUILD") != "" ]]; then
  rsync --exclude "aur" "$TMPDIR"/* ungoogled-chromium || echo "Failed to copy files"
fi
