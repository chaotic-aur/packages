# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=protonplus
pkgver=0.5.17
pkgrel=1
pkgdesc="A modern compatibility tools manager"
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
sha256sums=('0f19f254cc207c706e8f06cea07fdb47240529d6152c9d489b25bf76e7a71cda')

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
