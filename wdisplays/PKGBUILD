# Maintainer: Arti Zirk <arti@zirk.me>
# Maintainer: redtide <redtid3@gmail.com>
# Contributor: Stefan Tatschner <stefan@rumpelsepp.org>

pkgname=wdisplays
pkgver=1.1.3
pkgrel=1
pkgdesc="GUI display configurator for wlroots compositors"
url="https://github.com/artizirk/wdisplays"
license=(GPL3)
arch=(x86_64)
depends=(
  gtk3
  libepoxy
  wayland
  wayland-protocols
)
makedepends=(
  meson
)
source=(
  $pkgname-$pkgver.tar.gz::$url/archive/$pkgver.tar.gz
)
sha512sums=('7260deddb5871359ae9b0133cc9fa2f0b43e43664ff84cd37ad10385c4c2618a3b3303536be060097b982c7d2ab3890392ba9775e01b44281c1b3419256398a8')
b2sums=('aa724523df3827766236b0e39b19f983b2795fa8d19a9f29c39c1409867cd72a45da3dd406f3796752ea3e8d579512ac612c3e4d008dc8d27a979f7b38120bda')

build() {
  cd "$pkgname-$pkgver"
  arch-meson "$srcdir/build"
  ninja -C "$srcdir/build"
}

package() {
  cd "$pkgname-$pkgver"
  DESTDIR="$pkgdir" ninja -C "$srcdir/build" install
}
