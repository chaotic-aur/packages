# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=python-hwdata
pkgver=2.4.2
pkgrel=1
pkgdesc="Python bindings to hwdata"
arch=('any')
url="https://github.com/xsuchy/python-hwdata"
license=('GPL-2.0-or-later')
depends=(
  'hwdata'
  'python'
)
makedepends=(
  'python-build'
  'python-installer'
  'python-setuptools'
  'python-wheel'
)
source=("https://github.com/xsuchy/python-hwdata/archive/refs/tags/$pkgname-$pkgver-1.tar.gz")
sha256sums=('f17daaf2b7d13645e43d0bcaa7ab7ecda819f3a70e347cfd6ff9130609f9d9de')

build() {
  cd "$pkgname-$pkgname-$pkgver-1"
  python -m build --wheel --no-isolation
}

package() {
  cd "$pkgname-$pkgname-$pkgver-1"
  python -m installer --destdir="$pkgdir" dist/*.whl
}
