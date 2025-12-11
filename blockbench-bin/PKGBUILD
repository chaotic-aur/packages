# Maintainer: txtsd <aur.archlinux@ihavea.quest>
# Maintainer: Atakku <atakkudev@gmail.com>

pkgname=blockbench-bin
_pkgname="${pkgname%-bin}"
_pkgname_orig=Blockbench
pkgver=5.0.5
pkgrel=1
pkgdesc='A low-poly 3D model editor'
arch=(x86_64 armv7h)
url='https://blockbench.net'
license=('GPL-3.0-or-later')
depends=(
  alsa-lib
  at-spi2-core
  cairo
  dbus
  expat
  gcc-libs
  glib2
  glibc
  gtk3
  hicolor-icon-theme
  imlib2
  libcups
  libdrm
  libx11
  libxcb
  libxcomposite
  libxdamage
  libxext
  libxfixes
  libxkbcommon
  libxrandr
  mesa
  nspr
  nss
  pango
)
makedepends=(gzip)
provides=("${_pkgname}")
conflicts=("${_pkgname}")
options=(!debug)
source=("https://github.com/JannisX11/blockbench/releases/download/v${pkgver}/Blockbench_${pkgver}.deb")
sha256sums=('788934b7f6a76d22acb3a6d8d4309e5871ed37789ded5389755501c9ecefe808')

package() {
  bsdtar -xf data.tar.xz -C "${pkgdir}/"

  mv "${pkgdir}/opt/${_pkgname_orig}" "${pkgdir}/opt/${_pkgname}"
  gzip -d "${pkgdir}/usr/share/doc/${_pkgname}/changelog.gz"

  sed -i "s:/opt/${_pkgname_orig}:/opt/${_pkgname}:" "${pkgdir}/usr/share/applications/${_pkgname}.desktop"

  mkdir -p "${pkgdir}/usr/bin"
  ln -s "/opt/${_pkgname}/${_pkgname}" "${pkgdir}/usr/bin/${_pkgname}"
}
