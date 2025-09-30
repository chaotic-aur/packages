# Maintainer: xiota
# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>
# Contributor: ThatOneCalculator <kainoa@t1c.dev>

_pkgname="hyprpaper"
pkgname="$_pkgname-git"
pkgver=0.7.4.r4.g05337a4
pkgrel=1
pkgdesc="A blazing fast wayland wallpaper utility with IPC controls"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/hyprpaper"
license=('BSD-3-Clause')

depends=(
  hyprgraphics-git
  hyprlang-git
  hyprutils-git
  hyprwayland-scanner-git
  pango
  wayland
)
makedepends=(
  cmake
  git
  libglvnd
  ninja
  wayland-protocols
  xorgproto
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
