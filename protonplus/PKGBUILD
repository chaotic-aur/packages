# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=protonplus
_app_id=com.vysp3r.ProtonPlus
pkgver=0.4.26
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
sha256sums=('a9d8036353ecd5435629f8a1a77df27c2bb97cf3d07fa4b9e9c55bdea61eddd2')

build() {
  arch-meson "ProtonPlus-$pkgver" build
  meson compile -C build
}

check() {
  meson test -C build --no-rebuild --print-errorlogs || :
}

package() {
  meson install -C build --no-rebuild --destdir "$pkgdir"

  ln -s "/usr/bin/${_app_id}" "$pkgdir/usr/bin/$pkgname"
}
