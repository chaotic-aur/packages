# Maintainer: alba4k <blaskoazzolaaaron@gmail.com>

_pkgname="hypridle"
_pkgsrc=$_pkgname
pkgname="$_pkgname-git"
pkgver=0.1.6.r1.g66d1815
pkgrel=1
pkgdesc="Hyprland's idle daemon"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/$_pkgname"
license=('BSD-3-Clause')
depends=(
  hyprlang-git
  hyprutils-git
  'sdbus-cpp>=2.0.0'
  systemd
  wayland
)
makedepends=(
  cmake
  git
  hyprland-protocols-git
  hyprwayland-scanner-git
  ninja
  wayland-protocols
)
source=("$_pkgsrc::git+$url.git")
conflicts=("$_pkgname")
provides=("$_pkgname=${pkgver%%.r*}")
sha256sums=('SKIP')

: '
prepare() {
	# Pick pull request form GitHub replacing NUM with the pr number
	# e.g. git pull origin pull/111/head --no-edit --rebase

	git pull origin pull/NUM/head --no-edit --rebase
}
'

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
