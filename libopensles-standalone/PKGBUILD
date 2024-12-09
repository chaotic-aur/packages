# Maintainer: txtsd <aur.archlinux@ihavea.quest>

pkgname=libopensles-standalone
pkgver=r280.605a83f
pkgrel=1
pkgdesc="A lightly patched version of Google's libOpenSLES implementation"
_commit=605a83f47263a022427afb6e95801bd39b459b78
url='https://gitlab.com/android_translation_layer/libopensles-standalone'
arch=(x86_64 aarch64 armv7h)
license=('Apache-2.0')
depends=(
  glibc
  libsndfile
  sdl2
)
makedepends=(
  jdk8-openjdk
  meson
)
source=("${pkgname}-${_commit}.tar.gz::${url}/-/archive/${_commit}/${pkgname}-${_commit}.tar.gz")
sha256sums=('4e928fe1caf0efb5a094f249ec95d8a5e58df7718d2112db973d309d84387b7b')

prepare() {
  meson subprojects download --sourcedir="${pkgname}-${_commit}"
}

build() {
  arch-meson "${pkgname}-${_commit}" build
  meson compile -C build
}

check() {
  meson test --no-rebuild --print-errorlogs -C build
}

package() {
  meson install --no-rebuild -C build --destdir "${pkgdir}"
}
