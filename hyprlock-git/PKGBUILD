# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>

_pkgname="hyprlock"
pkgname="$_pkgname-git"
pkgver=0.9.1.r1.g347e05a
pkgrel=1
pkgdesc="Hyprland's GPU-accelerated screen locking utility"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/hyprlock"
license=('BSD-3-Clause')

depends=(
  'sdbus-cpp>=2.0.0'
  hyprgraphics-git
  hyprlang-git
  hyprutils-git
  libdrm
  libglvnd
  libxkbcommon
  mesa
  pam
  pango
  wayland
)
makedepends=(
  cmake
  git
  hyprwayland-scanner-git
  ninja
  wayland-protocols
)

provides=("$_pkgname=${pkgver%%.r*}")
conflicts=("$_pkgname")

_pkgsrc=$_pkgname
source=("$_pkgsrc::git+$url.git")
sha256sums=('SKIP')

backup=('etc/pam.d/hyprlock')

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
