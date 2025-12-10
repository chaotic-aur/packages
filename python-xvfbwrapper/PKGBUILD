# Maintainer: txtsd <aur.archlinux@ihavea.quest>
# Contributor: Carl Smedstad <carl.smedstad at protonmail dot com>
# Contributor: David Runge <dave@sleepmap.de>

pkgname=python-xvfbwrapper
_pkgname="${pkgname#python-}"
pkgver=0.2.16
pkgrel=1
pkgdesc='Manage headless displays with Xvfb (X virtual framebuffer)'
arch=(any)
url='https://github.com/cgoldberg/xvfbwrapper'
license=('MIT')
depends=(
  python
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
sha256sums=('c5dc68aea8a4f49a8f30269f4b0d23c18fc0e203f8f6be7128bc55ea31c3b508')

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
