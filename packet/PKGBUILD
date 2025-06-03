# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=packet
pkgver=0.3.2
pkgrel=1
pkgdesc="A Quick Share client for Linux"
arch=('x86_64')
url="https://github.com/nozwock/packet"
license=('GPL-3.0-or-later')
depends=('libadwaita')
makedepends=(
  'blueprint-compiler'
  'cargo'
  'meson'
  'protobuf'
)
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/$pkgver.tar.gz")
sha256sums=('23f1aa0a6460c78f907a935bd17e99d303fa1788a16926aaaf9f19c3f44974c5')

prepare() {
  cd "$pkgname-$pkgver"
  export RUSTUP_TOOLCHAIN=stable
  cargo fetch --target "$(rustc -vV | sed -n 's/host: //p')"
}

build() {
  export RUSTUP_TOOLCHAIN=stable
  arch-meson "$pkgname-$pkgver" build
  meson compile -C build
}

check() {
  meson test -C build --no-rebuild --print-errorlogs
}

package() {
  meson install -C build --no-rebuild --destdir "$pkgdir"
}
