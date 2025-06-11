# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=packet
pkgver=0.5.0
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
sha256sums=('08e98fffc593eb49c956709a08393a93d6147e24fdba7bab0eaf529f229e6d1b')

prepare() {
  cd "$pkgname"
  export RUSTUP_TOOLCHAIN=stable
  cargo fetch --target "$(rustc -vV | sed -n 's/host: //p')"

  # Fix appstream release changelog
  git cherry-pick -n dc5924c6e8d1ce83674b28dde1d93b1039cee2e6
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
