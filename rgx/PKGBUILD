# Maintainer: Mario Finelli <mario at finel dot li>

pkgname=rgx
pkgver=0.1.0
pkgrel=1
pkgdesc="command line regexp tester"
arch=(x86_64)
url=https://github.com/mfinelli/rgx
license=(GPL-3.0-or-later)
makedepends=(cargo)
depends=(glibc libgcc)
options=(!lto)
source=($url/archive/v$pkgver/$pkgname-$pkgver.tar.gz)
sha256sums=('d0668917e76cc45c75a137d0b6fe8b6296221c4a1fd6c94ab603244597e7d600')

prepare() {
  cd $pkgname-$pkgver
  export RUSTUP_TOOLCHAIN=stable
  cargo fetch --locked --target "$(rustc --print host-tuple)"
}

build() {
  cd $pkgname-$pkgver
  export RUSTUP_TOOLCHAIN=stable
  export CARGO_TARGET_DIR=target
  make
}

check() {
  cd $pkgname-$pkgver
  export RUSTUP_TOOLCHAIN=stable
  cargo test --frozen
}

package() {
  cd $pkgname-$pkgver
  make install DESTDIR="$pkgdir" PREFIX=/usr
  install -Dm0644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
  install -Dm0644 CHANGELOG.md "$pkgdir/usr/share/doc/$pkgname/CHANGELOG.md"
}

# vim: set ts=2 sw=2 et:
