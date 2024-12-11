# Maintainer: txtsd <aur.archlinux@ihavea.quest>
# Contributor: David Runge <dvzrv@archlinux.org>

pkgname=wolfssl-jni
_pkgname="${pkgname%-jni}"
pkgver=5.7.4
pkgrel=2
pkgdesc='Lightweight, portable, C-language-based SSL/TLS library (with jni support)'
arch=(x86_64 aarch64 armv7h)
url='https://www.wolfssl.com'
license=('GPL-2.0-or-later')
depends=(
  bash
  glibc
)
makedepends=(cmake)
provides=(
  libwolfssl.so
  wolfssl
)
conflicts=(wolfssl)
source=(
  ${pkgname}-${pkgver}-stable.tar.gz::https://github.com/${_pkgname}/${_pkgname}/archive/refs/tags/v${pkgver}-stable.tar.gz
)
sha256sums=('6c70f6fab34e2f963a255c3637c0c6f7250df2d1ef7c34eebca4f8e8d7323399')
validpgpkeys=(
  A2A48E7BCB96C5BECB987314EBC80E415CA29677 # wolfSSL <secure@wolfssl.com>
)

prepare() {
  cd ${_pkgname}-${pkgver}-stable

  ./autogen.sh
}

build() {
  cd ${_pkgname}-${pkgver}-stable

  ./configure \
    --build=${CBUILD} \
    --host=${CHOST} \
    --prefix=/usr \
    --sysconfdir=/etc \
    --mandir=/usr/share/man \
    --localstatedir=/var \
    --enable-shared \
    --enable-static \
    --enable-reproducible-build \
    --disable-opensslall \
    --disable-opensslextra \
    --enable-aescbc-length-checks \
    --enable-curve25519 \
    --enable-ed25519 \
    --enable-ed25519-stream \
    --disable-oldtls \
    --enable-base64encode \
    --enable-tlsx \
    --enable-scrypt \
    --disable-examples \
    --enable-keygen \
    --enable-wolfssh \
    --enable-jni
  make
}

check() {
  cd ${_pkgname}-${pkgver}-stable

  ./wolfcrypt/test/testwolfcrypt
}

package() {
  cd ${_pkgname}-${pkgver}-stable

  DESTDIR="${pkgdir}" make install

  cp -P src/.libs/libwolfssl.so.* "${pkgdir}/usr/lib/"
  install -Dm644 {README,ChangeLog}.md -t "${pkgdir}/usr/share/doc/${_pkgname}"
}
