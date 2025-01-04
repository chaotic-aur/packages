# Maintainer: Kevin MacMartin <prurigro@gmail.com>
# Contributor: bionade24
# Contributor: vivaeltopo
# Contributor: aliu
# Contributor: chrrybmb

_pkgname=upscayl
pkgname=$_pkgname-bin
pkgver=2.15.0
pkgrel=4
pkgdesc='Free and Open Source AI Image Upscaler'
url='https://github.com/upscayl/upscayl'
license=('AGPL-3.0-only')
arch=('x86_64')
depends=('libvips' 'openjpeg2' 'electron27' 'nodejs' 'vulkan-driver')
makedepends=('unzip')
provides=($_pkgname)
conflicts=($_pkgname)
options=('!strip')
noextract=("upscayl-${pkgver}-linux.zip")

source=(
  "https://github.com/upscayl/upscayl/releases/download/v${pkgver}/upscayl-${pkgver}-linux.zip"
  "$_pkgname"
  'org.upscayl.Upscayl.desktop'
)

sha512sums=(
  '2500a453c8eb9014d958a278ad8557c34085ce80dd2fce112b12e1643a1c37469ec09914c8ad06795cbf6ad23bd30ba6cb4290f0933b1cd37cc1a8724ac61553'
  'babf083cba6d621b51279bfce68cd9929f1cf2db006b6f80c651fb09f5c2751865eb8bf46a7168496b3a0a4e99edcb25bdf1bae815fe9b1a5215806fae7d468e'
  '51387f42e9b389a599c17690ce2004c51292a4732642fe0c1f6347baecdac719ef88c1fd66b24a5999b13282d3834c75d4047f34fda8ef5783c9e82ed261240e'
)

prepare() {
  cd "$srcdir"
  unzip ${_pkgname}-${pkgver}-linux.zip -x resources/128x128.png -d ${_pkgname}-${pkgver}
}

package() {
  cd "$srcdir"

  # Launcher script and xdg desktop file
  install -Dm755 "$_pkgname" "$pkgdir"/usr/bin/$_pkgname
  install -Dm644 org.upscayl.Upscayl.desktop "$pkgdir"/usr/share/applications/org.upscayl.Upscayl.desktop

  # Enter the package folder
  cd ${_pkgname}-${pkgver}/resources

  # XDG launcher
  install -dm755 "$pkgdir"/usr/share/pixmaps
  mv 512x512.png "$pkgdir"/usr/share/pixmaps/org.upscayl.Upscayl.png

  # App directory
  install -dm755 "$pkgdir"/opt/$_pkgname
  mv * "$pkgdir"/opt/${_pkgname}/
}
