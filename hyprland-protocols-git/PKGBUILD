# Maintainer: TheK0tYaRa
# Maintainer: alba4k <blaskoazzolaaaron@gmail.com>
# Inspired by: FabioLolix, éclairevoyant, ThatOneCalculator <kainoa at t1c dot dev>

_pkgname="hyprland-protocols"
_pkgsrc=$_pkgname
pkgname="$_pkgname-git"
pkgver=0.6.4.r0.g3a5c2bd
pkgrel=1
pkgdesc="Wayland protocol extensions for Hyprland"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/$_pkgname"
license=('BSD-3-Clause')
makedepends=(
  meson
  git
  ninja
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
