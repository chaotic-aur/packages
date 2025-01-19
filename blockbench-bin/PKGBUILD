# Maintainer: txtsd <aur.archlinux@ihavea.quest>
# Maintainer: Atakku <atakkudev@gmail.com>

pkgname=blockbench-bin
_pkgname="${pkgname%-bin}"
_pkgname_orig=Blockbench
pkgver=4.12.1
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
  giblib
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
sha256sums=('15cae9e0c1e53283ec95de4d4d20bcd7b58395958781ea4036d798976d90135f')

package() {
  bsdtar -xf data.tar.xz -C "${pkgdir}/"

  mv "${pkgdir}/opt/${_pkgname_orig}" "${pkgdir}/opt/${_pkgname}"
  gzip -d "${pkgdir}/usr/share/doc/${_pkgname}/changelog.gz"

  sed -i "s:/opt/${_pkgname_orig}:/opt/${_pkgname}:" "${pkgdir}/usr/share/applications/${_pkgname}.desktop"

  mkdir -p "${pkgdir}/usr/bin"
  ln -s "/opt/${_pkgname}/${_pkgname}" "${pkgdir}/usr/bin/${_pkgname}"
}
