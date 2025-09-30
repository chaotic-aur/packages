# Maintainer: dawfukfr <dawfukfr@gmail.com>
# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>
# Contributor: Caleb Maclennan <caleb@alerque.com>

_pkgname="aquamarine"
pkgname="$_pkgname-git"
pkgver=0.8.0.r3.gc8282f4
pkgrel=1
pkgdesc="Aquamarine is a very light linux rendering backend library"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/$_pkgname"
license=('BSD-3-Clause')

depends=(
  gcc-libs
  glibc
  hyprutils-git
  hyprwayland-scanner-git
  libdisplay-info
  libdrm
  libglvnd
  libinput
  mesa
  opengl-driver
  pixman
  pugixml
  seatd
  systemd-libs
  wayland
  wayland-protocols
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
