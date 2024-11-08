# Maintainer: txtsd <aur.archlinux@ihavea.quest>
# Maintainer: Pekka Ristola <pekkarr [at] protonmail [dot] com>

pkgname=python-syncedlyrics
_pkgname="${pkgname#python-}"
pkgver=1.0.1
pkgrel=1
pkgdesc='Get an LRC format (synchronized) lyrics for your music'
arch=(any)
url='https://github.com/moehmeni/syncedlyrics'
license=('MIT')
depends=(
  'python-beautifulsoup4>=4.11.1'
  'python-rapidfuzz>=2.13.2'
  'python-requests>=2.28.1'
  'python>=3.8'
)
makedepends=(
  python-build
  python-installer
  python-poetry-core
  python-wheel
)
checkdepends=(python-pytest)
source=("${_pkgname}-${pkgver}.tar.gz::${url}/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('e9e36b8bab2d79428cb85b54a939f56d0d6210444b501b6861ffdf2266626840')

build() {
  cd "${_pkgname}-${pkgver}"
  python -m build --wheel --no-isolation
}

check() {
  cd "${_pkgname}-${pkgver}"
  pytest tests.py
}

package() {
  cd "${_pkgname}-${pkgver}"
  python -m installer --destdir="${pkgdir}" dist/*.whl
  install -Dm644 LICENSE -t "${pkgdir}/usr/share/licenses/${pkgname}"
}
