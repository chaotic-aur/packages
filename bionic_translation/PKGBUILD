# Maintainer: txtsd <aur.archlinux@ihavea.quest>

pkgname=bionic_translation
pkgver=r69.60f1f64d
pkgrel=1
_commit=60f1f64de330e734c2476c51ac6aec67396a4781
pkgdesc='A set of libraries for loading bionic-linked .so files on musl/glibc'
url='https://gitlab.com/android_translation_layer/bionic_translation'
arch=(x86_64 aarch64 armv7h)
license=('MIT')
depends=(
  glibc
  libbsd
  libglvnd
  libunwind
)
makedepends=(
  elfutils
  mesa
  meson
)
source=("${pkgname}-${_commit}.tar.gz::${url}/-/archive/$_commit/${pkgname}-${_commit}.tar.gz")
sha256sums=('87e20bfef66544decc261d7ebd8aaff3e48c19c9d2fe86b06c22c08da4b75bbe')

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
