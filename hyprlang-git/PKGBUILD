# Maintainer: zjeffer
# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>

_pkgname="hyprlang"
pkgname="$_pkgname-git"
pkgver=0.6.0.r10.g72df386
pkgrel=1
pkgdesc="The official implementation library for the hypr config language"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/hyprlang"
license=('LGPL-3.0-or-later')

depends=(
  gcc-libs
  glibc
  hyprutils-git
)
makedepends=(
  cmake
  git
  ninja
  pixman
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
