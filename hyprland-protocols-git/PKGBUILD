# Maintainer: TheK0tYaRa
# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>
# Inspired by: FabioLolix, éclairevoyant, ThatOneCalculator <kainoa at t1c dot dev>

_pkgname="hyprland-protocols"
pkgname="$_pkgname-git"
pkgver=0.6.4.r0.g3a5c2bd
pkgrel=1
pkgdesc="Wayland protocol extensions for Hyprland"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/hyprland-protocols"
license=('BSD-3-Clause')

makedepends=(
  meson
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
  cd $_pkgsrc

  meson setup build \
    --prefix=/usr \
    --libexecdir=lib \
    --buildtype=plain

  meson compile -C build
}

package() {
  meson install -C "$_pkgsrc/build" --destdir "$pkgdir"
  install -Dm644 "$_pkgsrc/LICENSE" -t "$pkgdir/usr/share/licenses/$pkgname/"
}
