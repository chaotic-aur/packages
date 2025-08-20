# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
# Contributor: Michael Riegert <michael at eowyn net>
# Contributor: Felix Golatofski <contact@xdfr.de>
# Contributor: Sibren Vasse <arch@sibrenvasse.nl>
# Contributor: Daniel M. Capella <polyzen@archlinux.info>
# Contributor: Morten Linderud <morten@linderud.pw>

pkgname=python-pychromecast
_name=${pkgname#python-}
pkgver=14.0.9
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
sha256sums=('d5494eff226119d9a0c2fd4d9fbc7f1025cedb2e699047cc9a0ba76236bed64d')

prepare() {
  cd "$_name-$pkgver"
}

build() {
  cd "$_name-$pkgver"
  python -m build --wheel --no-isolation
}

package() {
  cd "$_name-$pkgver"
  python -m installer --destdir="$pkgdir" dist/*.whl

  install -Dm644 LICENSE -t "$pkgdir/usr/share/licenses/$pkgname/"
}
