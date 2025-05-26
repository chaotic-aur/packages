# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=protonplus
pkgver=0.4.31
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
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('1abbf8053f37b2cc765c18cb2d5b355e687d25b32bbb1bd0426749295328b357')

build() {
  arch-meson "ProtonPlus-$pkgver" build
  meson compile -C build
}

check() {
  meson test -C build --no-rebuild --print-errorlogs || :
}

package() {
  meson install -C build --no-rebuild --destdir "$pkgdir"

  ln -s /usr/bin/com.vysp3r.ProtonPlus "$pkgdir/usr/bin/$pkgname"
}
