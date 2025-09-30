# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>
# Contributor: ThatOneCalculator <kainoa at t1c dot dev>

_pkgname="xdg-desktop-portal-hyprland"
pkgname="$_pkgname-git"
pkgver=1.3.9.r5.gbe6771e
pkgrel=1
pkgdesc="xdg-desktop-portal backend for Hyprland"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/xdg-desktop-portal-hyprland"
license=('BSD-3-Clause')

depends=(
  hyprlang-git
  hyprutils-git
  libdrm
  libinih
  libpipewire
  mesa
  qt6-base
  qt6-wayland
  sdbus-cpp
  wayland
  xdg-desktop-portal
)
makedepends=(
  cmake
  git
  hyprland-protocols-git
  hyprwayland-scanner-git
  ninja
  scdoc
  wayland-protocols
)
optdepends=(
  'grim: required for the screenshot portal to function'
  'slurp: support for interactive mode for the screenshot portal; one of the built-in chooser options for the screencast portal'
  'hyprland: the Hyprland compositor'
)

provides=("$_pkgname=${pkgver%%.r*}" "xdg-desktop-portal-impl")
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
    -D CMAKE_INSTALL_LIBEXECDIR=lib
  )
  cmake "${cmake_options[@]}"
  cmake --build build
}

package() {
  DESTDIR="$pkgdir" cmake --install build
  install -Dm644 "$_pkgsrc/LICENSE" -t "$pkgdir/usr/share/licenses/$pkgname/"
}
