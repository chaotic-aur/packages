# Maintainer: txtsd <aur.archlinux@ihavea.quest>

pkgname=funchook
pkgver=1.1.3
pkgrel=1
pkgdesc='Hook function calls by inserting jump instructions at runtime'
arch=(i686 x86_64)
url='https://github.com/kubo/funchook'
license=('GPL-2.0-or-later')
depends=(glibc)
makedepends=(cmake)
source=("https://github.com/kubo/funchook/releases/download/v${pkgver}/${pkgname}-${pkgver}.tar.gz")
sha256sums=('d49d682f5d2386c173b6e006967ecfee37c45fd1eef3e9d4232992ccdaca4ef5')

# TODO: Add support for capstone specifically for aarch64
# -DFUNCHOOK_DISASM='capstone'

build() {
  cd "${pkgname}-${pkgver}"

  cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX='/usr' \
    -DCMAKE_BUILD_TYPE='None' \
    -Wno-dev
  cmake --build build
}

check() {
  cd "${pkgname}-${pkgver}"

  ctest --test-dir build --output-on-failure
}

package() {
  cd "${pkgname}-${pkgver}"

  DESTDIR="${pkgdir}" cmake --install build
  install -Dm644 'LICENSE' "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
