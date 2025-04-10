# Maintainer: alba4k <blaskoazzolaaaron@gmail.com>

_pkgname="hyprgraphics"
_pkgsrc=$_pkgname
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
  libspng
  libwebp
  pixman
)
makedepends=(
  cmake
  git
  ninja
)
source=("$_pkgsrc::git+$url.git")
conflicts=("$_pkgname")
provides=("$_pkgname=${pkgver%%.r*}" "lib$_pkgname.so")
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
