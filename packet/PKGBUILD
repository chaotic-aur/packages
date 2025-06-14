# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=packet
pkgver=0.5.2
pkgrel=1
pkgdesc="A Quick Share client for Linux"
arch=('x86_64')
url="https://github.com/nozwock/packet"
license=('GPL-3.0-or-later')
depends=('libadwaita')
makedepends=(
  'blueprint-compiler'
  'cargo'
  'git'
  'meson'
  'protobuf'
)
optdepends=(
  'nautilus-python: Nautilus integration'
  'python-dbus: needed for Nautilus extension'
)
source=("git+https://github.com/nozwock/packet.git#tag=$pkgver")
sha256sums=('cd9a3f02781ca27f82d7b2c46f6794912f72f96f3311ddf05da2e3bb92b8c6f7')

prepare() {
  cd "$pkgname"
  export RUSTUP_TOOLCHAIN=stable
  cargo fetch --target "$(rustc -vV | sed -n 's/host: //p')"
}

build() {
  export RUSTUP_TOOLCHAIN=stable
  arch-meson "$pkgname" build
  meson compile -C build
}

check() {
  meson test -C build --no-rebuild --print-errorlogs
}

package() {
  meson install -C build --no-rebuild --destdir "$pkgdir"

  # Symlink Nautilus extension to exension directory
  install -d "$pkgdir/usr/share/nautilus-python/extensions"
  ln -s "/usr/share/$pkgname/plugins/packet_nautilus.py" \
    "$pkgdir/usr/share/nautilus-python/extensions/"
}
