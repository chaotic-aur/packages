# Maintainer: TheEdgeOfRage <archlinux@theedgeofrage.com>
# Contributor: Mark Wagie <mark dot wagie at proton dot me>
# Contributor: WorMzy Tykashi <wormzy.tykashi@gmail.com>
pkgname=python-pulsectl
_name=${pkgname#python-}
pkgver=24.11.0
pkgrel=1
epoch=1
pkgdesc="Python high-level interface and ctypes-based bindings for PulseAudio (libpulse)"
arch=('any')
url="https://github.com/mk-fg/python-pulse-control"
license=('MIT')
depends=('python' 'libpulse')
makedepends=('python-build' 'python-installer' 'python-setuptools' 'python-wheel')
conflicts=('python-pulse-control')
source=("https://files.pythonhosted.org/packages/source/${_name::1}/$_name/$_name-$pkgver.tar.gz")
sha256sums=('0ba32745d3f198d5657af19f7ee3eb007af5a86a306ec3cd45af42e767820d0d')

build() {
  cd "$_name-$pkgver"
  python -m build --wheel --no-isolation
}

package() {
  cd "$_name-$pkgver"
  python -m installer --destdir="$pkgdir" dist/*.whl

  install -Dm644 COPYING -t "$pkgdir/usr/share/licenses/$pkgname/"
}
