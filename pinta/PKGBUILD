# Maintainer: Rafael Baboni Dominiquini <rafaeldominiquini at gmail dot com>

pkgname=pinta
pkgver=3.1.1
pkgrel=2
pkgdesc="Drawing/editing program modeled after Paint.NET. It's goal is to provide a simplified alternative to GIMP for casual users"
arch=(any)
url="https://pinta-project.com"
license=(MIT)
depends=(dotnet-runtime dotnet-host libadwaita hicolor-icon-theme webp-pixbuf-loader)
makedepends=(pkgconf autoconf-archive intltool dotnet-sdk dotnet-runtime dotnet-host dotnet-targeting-pack gtk4 perl)
provides=($pkgname)
conflicts=($pkgname-git)
source=("Pinta-${pkgver}.tar.gz::https://github.com/PintaProject/Pinta/archive/refs/tags/${pkgver}.tar.gz")
sha256sums=('284feb187646d24e2d0449308352bc3588c159dc374365185432008873868371')

prepare() {
  cd "${srcdir}/Pinta-${pkgver}"

  for file in *.md *.txt; do
    basename=$(tr '[:lower:]' '[:upper:]' <<< "${file%.*}")
    newname="$basename.${file#*.}"
    [ ! "$file" == "$newname" ] && mv "$file" "$newname"
  done

  sed -i 's/net8.0/net10.0/g' Directory.Build.props

  ./autogen.sh --prefix=/usr --sysconfdir=/etc --localstatedir=/var
}

build() {
  cd "${srcdir}/Pinta-${pkgver}"

  make
}

package() {
  cd "${srcdir}/Pinta-${pkgver}"

  make DESTDIR="${pkgdir}" install

  chmod -v 755 "${pkgdir}/usr/lib/pinta/"*.dll

  install -Dm644 -t "${pkgdir}/usr/share/doc/${pkgname}/" *.md
  install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}/" LICENSE*.txt
}
