#!/usr/bin/env bash
[ -n "${PACKAGE:-}" ] || exit 1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git clone --depth 1 https://github.com/Gigas002/software-and-services.git "$tmp" &>/dev/null || exit 1
if ! diff -q PKGBUILD "$tmp/PKGBUILDs/$PACKAGE/PKGBUILD" &>/dev/null; then
  rsync -a --delete --exclude .CI "$tmp/PKGBUILDs/$PACKAGE/" ./
  makepkg --printsrcinfo > .SRCINFO 2>/dev/null || true
fi
