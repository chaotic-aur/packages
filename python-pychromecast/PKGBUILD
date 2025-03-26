# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
# Contributor: Michael Riegert <michael at eowyn net>
# Contributor: Felix Golatofski <contact@xdfr.de>
# Contributor: Sibren Vasse <arch@sibrenvasse.nl>
# Contributor: Daniel M. Capella <polyzen@archlinux.info>
# Contributor: Morten Linderud <morten@linderud.pw>

pkgname=python-pychromecast
_name=${pkgname#python-}
pkgver=14.0.7
pkgrel=1
pkgdesc="Library for Python 3 to communicate with the Google Chromecast"
arch=('any')
url="https://github.com/home-assistant-libs/pychromecast"
license=('MIT')
depends=(
  'python-casttube'
  'python-protobuf'
  'python-zeroconf'
)
makedepends=(
  'python-build'
  'python-installer'
  'python-setuptools'
  'python-wheel'
)
source=("$_name-$pkgver.tar.gz::$url/archive/refs/tags/$pkgver.tar.gz")
sha256sums=('639c6da3ca1f9df1ccfb6b582ae8cd98b68a257dbadf392b5d4074cf09908688')

build() {
  cd "$_name-$pkgver"
  python -m build --wheel --no-isolation
}

package() {
  cd "$_name-$pkgver"
  python -m installer --destdir="$pkgdir" dist/*.whl

  install -Dm644 LICENSE -t "$pkgdir/usr/share/licenses/$pkgname/"
}
