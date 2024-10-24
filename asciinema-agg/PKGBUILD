# Maintainer: Mario Finelli <mario at finel dot li>

pkgname=asciinema-agg
pkgver=1.5.0
pkgrel=1
pkgdesc="asciinema gif generator"
arch=(x86_64)
url=https://github.com/asciinema/agg
license=(Apache-2.0)
depends=(gcc-libs)
makedepends=(cargo)
options=(!lto)
source=(https://github.com/asciinema/agg/archive/v$pkgver/agg-$pkgver.tar.gz)
sha256sums=('4bfbd0cc02f416ce868f0209b659a87e333de8f0b5edad19810e152ac6e7fc55')

build() {
  cd agg-$pkgver
  cargo build --release --locked
}

check() {
  cd agg-$pkgver
  cargo test --all --release --locked
}

package() {
  cd agg-$pkgver
  install -Dm0755 target/release/agg "$pkgdir/usr/bin/agg"
  install -Dm0644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
