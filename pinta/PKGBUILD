# Maintainer: Rafael Baboni Dominiquini <rafaeldominiquini at gmail dot com>

pkgname=pinta
pkgver=3.0
pkgrel=2
pkgdesc="Drawing/editing program modeled after Paint.NET. It's goal is to provide a simplified alternative to GIMP for casual users"
arch=(any)
url="https://pinta-project.com"
license=(MIT)
depends=(dotnet-runtime dotnet-host libadwaita hicolor-icon-theme webp-pixbuf-loader)
makedepends=(autoconf-archive intltool dotnet-sdk dotnet-runtime dotnet-host dotnet-targeting-pack gtk4 gcc perl)
provides=($pkgname)
conflicts=($pkgname-git)
source=("Pinta-${pkgver}.tar.gz::https://github.com/PintaProject/Pinta/archive/refs/tags/${pkgver}.tar.gz")
sha256sums=('d7c4abb3133706253e7645d9347a6ab3e8616bee023f33db852c76f0e2bf102d')

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
