# Maintainer: txtsd <aur.archlinux@ihavea.quest>

pkgname=art_standalone-git
_pkgname="${pkgname%-git}"
pkgver=r184.1f3e7592
pkgrel=1
pkgdesc='A standalone version of Dalvik with Art built in'
url='https://gitlab.com/android_translation_layer/art_standalone'
arch=(x86_64 aarch64 armv7h)
license=('Apache-2.0')
depends=(
  bash
  bionic_translation-git
  expat
  gcc-libs
  glibc
  icu
  libbsd
  libunwind
  lz4
  openssl
  wolfssl-jni
  xz
  zlib
)
makedepends=(
  bsd-compat-headers
  git
  jdk8-openjdk
  libcap
  meson
  python
  valgrind
  zip
)
provides=("${_pkgname}")
conflicts=("${_pkgname}")
source=("git+${url}.git/")
sha256sums=('SKIP')

pkgver() {
  cd "${_pkgname}"

  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

build() {
  cd "${_pkgname}"

  make PREFIX=/usr ____LIBDIR=lib
}

package() {
  depends+=(java-runtime)

  cd "${_pkgname}"

  DESTDIR="${pkgdir}" make \
    ____PREFIX="${pkgdir}/usr" \
    ____INSTALL_ETC="${pkgdir}/etc" \
    ____LIBDIR=lib \
    install
}
