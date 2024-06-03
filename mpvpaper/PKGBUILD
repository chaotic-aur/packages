# Contributor: Lex Black <autumn-wind@web.de>

pkgname=mpvpaper
pkgver=1.6
pkgrel=1
pkgdesc="video wallpaper program for wlroots based wayland compositors"
arch=('i686' 'x86_64')
url="https://github.com/GhostNaN/$pkgname"
license=('GPL3')
depends=('mpv' 'wlroots')
makedepends=('meson' 'ninja' 'wayland-protocols')
optdepends=('socat: control via sockets')
source=(${pkgname}-${pkgver}.tar.gz::https://github.com/GhostNaN/mpvpaper/archive/${pkgver}.tar.gz)
b2sums=('3d60e7f320375daedeed83c0776d34257d11ab70ad8b97f29a764ba02254b8e2e2ab24e74dea232bb4a0b442ec4a48237aae0d53691892d3b4703b576fd15d4b')


build() {
  arch-meson "$pkgname-$pkgver" build
  meson compile -C build
}

package() {
  meson install -C build --destdir "$pkgdir"

  install -vDm644 "$pkgname-$pkgver"/mpvpaper.man "$pkgdir"/usr/share/man/man1/${pkgname}.1
}
