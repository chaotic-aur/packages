# Maintainer: Rafael Baboni Dominiquini <rafaeldominiquini at gmail dot com>

pkgname=pinta
pkgver=2.1.2
pkgrel=2
pkgdesc="Drawing/editing program modeled after Paint.NET. It's goal is to provide a simplified alternative to GIMP for casual users"
arch=(any)
url="https://pinta-project.com"
license=(MIT)
depends=(dotnet-runtime libadwaita hicolor-icon-theme webp-pixbuf-loader)
makedepends=(autoconf-archive intltool dotnet-sdk)
provides=($pkgname)
conflicts=($pkgname-git)
source=("Pinta-${pkgver}.tar.gz::https://github.com/PintaProject/Pinta/archive/refs/tags/${pkgver}.tar.gz")
sha256sums=('51939b5ecf1cfd546189da4a4c54146616052710434e718136cf1fa3dee9d680')

prepare() {
  cd "${srcdir}/Pinta-${pkgver}"

  sed -i '/^PINTA_BUILD_OPTS/ s/$/ -maxcpucount:1/' Makefile.am

  sed -i 's/net8.0/net9.0/g' Directory.Build.props configure.ac

  ./autogen.sh --prefix=/usr --sysconfdir=/etc --localstatedir=/var
}

build() {
  cd "${srcdir}/Pinta-${pkgver}"

  make
}

package() {
  cd "${srcdir}/Pinta-${pkgver}"

  make DESTDIR="${pkgdir}" install

  install -Dm644 -t "${pkgdir}/usr/share/doc/${pkgname}/" readme.md
  install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}/" license-*.txt
}
