# Maintainer: txtsd <aur.archlinux@ihavea.quest>
# Contributor: Carl Smedstad <carl.smedstad at protonmail dot com>
# Contributor: David Runge <dave@sleepmap.de>

pkgname=python-xvfbwrapper
_pkgname="${pkgname#python-}"
pkgver=0.2.21
pkgrel=1
pkgdesc='Manage headless displays with Xvfb (X virtual framebuffer)'
arch=(any)
url='https://github.com/cgoldberg/xvfbwrapper'
license=('MIT')
depends=(
  python
  python-psutil
  xorg-server-xvfb
)
makedepends=(
  python-build
  python-installer
  python-setuptools
  python-wheel
)
checkdepends=(python-pytest)
options=(!debug)
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/refs/tags/${pkgver}.tar.gz")
sha256sums=('88fe837e9e92c458b23a918d9ab19948a2f5cc096d989a678ce372c60f289e9a')

build() {
  cd "${_pkgname}-${pkgver}"

  python -m build --wheel --no-isolation
}

check() {
  cd "${_pkgname}-${pkgver}"

  pytest
}

package() {
  cd "${_pkgname}-${pkgver}"

  python -m installer --destdir="${pkgdir}" dist/*.whl

  install -Dm644 README.md "${pkgdir}/usr/share/doc/${pkgname}/README.md"
  install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
