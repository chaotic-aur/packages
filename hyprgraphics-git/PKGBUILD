# Maintainer: alba4k <blaskoazzolaaaron@gmail.com>

_pkgname="hyprgraphics"
pkgname="$_pkgname-git"
pkgver=0.1.3.r0.g9d7f268
pkgrel=1
pkgdesc="Hyprland graphics / resource utilities"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/hyprgraphics"
license=('BSD-3-Clause')

depends=(
  cairo
  file
  hyprutils-git
  libjpeg
  libjxl
  libpng
  libwebp
  pixman
)
makedepends=(
  cmake
  git
  ninja
)

provides=("$_pkgname=${pkgver%%.r*}" "lib$_pkgname.so")
conflicts=("$_pkgname")

_pkgsrc=$_pkgname
source=("$_pkgsrc::git+$url.git")
sha256sums=('SKIP')

pkgver() {
  cd "$_pkgsrc"
  git describe --long --tags --abbrev=7 | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}

build() {
  local cmake_options=(
    -B build
    -S "$_pkgsrc"
    -G Ninja
    -W no-dev
    -D CMAKE_BUILD_TYPE=None
    -D CMAKE_INSTALL_PREFIX=/usr
  )
  cmake "${cmake_options[@]}"
  cmake --build build
}

package() {
  DESTDIR="$pkgdir" cmake --install build
  install -Dm644 "$_pkgsrc/LICENSE" -t "$pkgdir/usr/share/licenses/$pkgname/"
}
