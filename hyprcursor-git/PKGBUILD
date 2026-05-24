# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>

_pkgname="hyprcursor"
pkgname="$_pkgname-git"
pkgver=0.1.13.r4.g3943590
pkgrel=1
pkgdesc="The hyprland cursor format, library and utilities"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/hyprcursor"
license=('BSD-3-Clause')
depends=(
  cairo
  hyprlang-git
  librsvg
  libzip
  tomlplusplus
)
makedepends=(
  git
  cmake
  ninja
)

conflicts=("$_pkgname")
provides=("$_pkgname=${pkgver}" "lib$_pkgname.so")

_pkgsrc=$_pkgname
source=("$_pkgsrc::git+$url.git")
sha256sums=('SKIP')

pkgver() {
  cd "$_pkgsrc"
  local _tag=$(git tag -l --contains $(git describe --tags --abbrev=0) --sort=-v:refname | head -n1 | sed 's/^v//')
  printf "%s.r%s.g%s" "$_tag" $(git rev-list --count --cherry-pick "v${_tag}...HEAD") $(git rev-parse --short=7 HEAD)
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
