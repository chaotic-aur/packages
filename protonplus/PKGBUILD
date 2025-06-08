# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=protonplus
pkgver=0.5.0
pkgrel=1
pkgdesc="A simple Wine and Proton-based compatiblity tools manager for GNOME"
arch=('x86_64')
url="https://github.com/Vysp3r/ProtonPlus"
license=('GPL-3.0-or-later')
depends=(
  'libadwaita'
  'libarchive'
  'libgee'
)
makedepends=(
  'meson'
  'vala'
)
checkdepends=('appstream-glib')
source=("$pkgname-$pkgver-1.tar.gz::$url/archive/refs/tags/v$pkgver-1.tar.gz")
sha256sums=('57473238128cda8ab198f706b8162889d245b827829876cd0b18f5f34ad8fa2a')

build() {
  arch-meson "ProtonPlus-$pkgver-1" build
  meson compile -C build
}

check() {
  meson test -C build --no-rebuild --print-errorlogs
}

package() {
  meson install -C build --no-rebuild --destdir "$pkgdir"
}
