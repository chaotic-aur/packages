# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>

_pkgname="hyprwayland-scanner"
pkgname="$_pkgname-git"
pkgver=0.4.4.r2.g206367a
pkgrel=1
pkgdesc="A Hyprland implementation of wayland-scanner, in and for C++"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/hyprwayland-scanner"
license=('BSD-3-Clause')

depends=(
  pugixml
)
makedepends=(
  cmake
  git
  ninja
)

provides=("$_pkgname=${pkgver%%.r*}")
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
