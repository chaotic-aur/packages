# Maintainer: txtsd <aur.archlinux@ihavea.quest>
# Contributor: Carl Smedstad <carl.smedstad at protonmail dot com>
# Contributor: David Runge <dave@sleepmap.de>

pkgname=python-xvfbwrapper
_pkgname="${pkgname#python-}"
pkgver=0.2.15
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
sha256sums=('54d77cba7a47554a062a70cc7fd1f983b04a91528f2414809dcaafd9f373f703')

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
