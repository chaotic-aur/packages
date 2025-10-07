# Maintainer: Rafael Baboni Dominiquini <rafaeldominiquini at gmail dot com>

pkgname=pinta
pkgver=3.0.4
pkgrel=1
pkgdesc="Drawing/editing program modeled after Paint.NET. It's goal is to provide a simplified alternative to GIMP for casual users"
arch=(any)
url="https://pinta-project.com"
license=(MIT)
depends=(dotnet-runtime dotnet-host libadwaita hicolor-icon-theme webp-pixbuf-loader)
makedepends=(pkgconf autoconf-archive intltool dotnet-sdk dotnet-runtime dotnet-host dotnet-targeting-pack gtk4 perl)
provides=($pkgname)
conflicts=($pkgname-git)
source=("Pinta-${pkgver}.tar.gz::https://github.com/PintaProject/Pinta/archive/refs/tags/${pkgver}.tar.gz")
sha256sums=('3472ef6b7307ec3942d3cefb299649f0b01e69fc951f6f0b04fbd6c083f770c4')

prepare() {
  cd "${srcdir}/Pinta-${pkgver}"

  for file in *.md *.txt; do
    basename=$(tr '[:lower:]' '[:upper:]' <<< "${file%.*}")
    newname="$basename.${file#*.}"
    [ ! "$file" == "$newname" ] && mv "$file" "$newname"
  done

  sed -i 's/net8.0/net9.0/g' Directory.Build.props
  sed -i 's/StartupWMClass=Pinta/StartupWMClass=com.github.PintaProject.Pinta/g' xdg/pinta.desktop.in

  ./autogen.sh --prefix=/usr --sysconfdir=/etc --localstatedir=/var
}

build() {
  cd "${srcdir}/Pinta-${pkgver}"

  make
}

package() {
  cd "${srcdir}/Pinta-${pkgver}"

  make DESTDIR="${pkgdir}" install

  install -Dm644 -t "${pkgdir}/usr/share/doc/${pkgname}/" *.md
  install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}/" LICENSE*.txt
}
