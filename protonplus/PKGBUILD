# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=protonplus
pkgver=0.5.16
pkgrel=2
pkgdesc="A simple Wine and Proton-based compatiblity tools manager for GNOME"
arch=('x86_64')
url="https://github.com/Vysp3r/ProtonPlus"
license=('GPL-3.0-or-later')
depends=(
  'gtk4'
  'json-glib'
  'libadwaita'
  'libarchive'
  'libgee'
  'libsoup3'
)
makedepends=(
  'meson'
  'vala'
)
checkdepends=('appstream-glib')
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('2ed82b873b154033b4790a496887bf7098dfea1dfa3253827aad1879de82db4a')

prepare() {
  cd "ProtonPlus-$pkgver"

  # Fix Lutris install directory
  # https://github.com/Vysp3r/ProtonPlus/issues/820
  # https://github.com/Vysp3r/ProtonPlus/pull/822
  sed -i 's|runners/proton|runners/wine|g' data/runners.json
}

build() {
  arch-meson "ProtonPlus-$pkgver" build
  meson compile -C build
}

check() {
  meson test -C build --no-rebuild --print-errorlogs
}

package() {
  meson install -C build --no-rebuild --destdir "$pkgdir"
}
