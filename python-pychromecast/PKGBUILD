# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
# Contributor: Michael Riegert <michael at eowyn net>
# Contributor: Felix Golatofski <contact@xdfr.de>
# Contributor: Sibren Vasse <arch@sibrenvasse.nl>
# Contributor: Daniel M. Capella <polyzen@archlinux.info>
# Contributor: Morten Linderud <morten@linderud.pw>

pkgname=python-pychromecast
_name=${pkgname#python-}
pkgver=14.0.5
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
sha256sums=('e642d6285556ea153fbc63928bad2bf4be8176eb6678edbaa96a9c3626dd88a9')

prepare() {
  cd "$_name-$pkgver"

  # relax requirements
  sed -i 's/~=/>=/g' pyproject.toml
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
