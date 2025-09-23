# Maintainer: txtsd <aur.archlinux@ihavea.quest>

pkgname=libopensles-standalone-git
_pkgname="${pkgname%-git}"
pkgver=r281.bdb857a
pkgrel=2
pkgdesc="A lightly patched version of Google's libOpenSLES implementation"
url='https://gitlab.com/android_translation_layer/libopensles-standalone'
arch=(x86_64 aarch64 armv7h)
license=('Apache-2.0')
depends=(
  glibc
  libsndfile
  sdl2
)
makedepends=(
  git
  jdk8-openjdk
  meson
)
provides=("${_pkgname}")
conflicts=("${_pkgname}")
source=("git+${url}.git")
sha256sums=('SKIP')

pkgver() {
  cd ${_pkgname}
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
  meson subprojects download --sourcedir="${_pkgname}"
}

build() {
  arch-meson "${_pkgname}" build
  meson compile -C build
}

check() {
  meson test --no-rebuild --print-errorlogs -C build
}

package() {
  meson install --no-rebuild -C build --destdir "${pkgdir}"
}
