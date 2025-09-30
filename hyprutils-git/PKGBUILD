# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>

_pkgname="hyprutils"
pkgname="$_pkgname-git"
pkgver=0.7.0.r0.g05878d9
pkgrel=1
pkgdesc="Hyprland utilities library used across the ecosystem"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/hyprutils"
license=('BSD-3-Clause')

depends=(
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
