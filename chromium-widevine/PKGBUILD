# Maintainer: envolution
# Contributor: Doug Newgard <scimmia at archlinux dot org>
# shellcheck shell=bash disable=SC2034,SC2154

pkgname=chromium-widevine
pkgdesc='A browser plugin designed for the viewing of premium video content'
pkgver=4.10.2891.0
pkgrel=1
epoch=1
arch=('x86_64')
url='https://www.widevine.com/'
license=('custom')
options=('!strip')
source=("https://dl.google.com/widevine-cdm/${pkgver}-linux-x64.zip")
sha256sums=('6267e8c669044ca6ff75fa344dda2707d1497bb7a48b982d93f7fb17f7cb4c5d')

package() {
  depends=('gcc-libs' 'glib2' 'glibc' 'nspr' 'nss')

  install -d "${pkgdir}/usr/lib/chromium/WidevineCdm/_platform_specific/linux_x64"
  install -d "${pkgdir}/usr/share/licenses/${pkgname}"

  install -Dm755 "${srcdir}/libwidevinecdm.so" \
    "${pkgdir}/usr/lib/chromium/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so"
  install -Dm644 "${srcdir}/manifest.json" \
    "${pkgdir}/usr/lib/chromium/WidevineCdm/manifest.json"
  install -Dm644 "${srcdir}/LICENSE.txt" \
    "${pkgdir}/usr/lib/chromium/WidevineCdm/LICENSE"
  install -Dm644 "${srcdir}/LICENSE.txt" \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"

  # backward compatibility
  ln -s WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so "$pkgdir/usr/lib/chromium/libwidevinecdm.so"
}
# vim:set ts=2 sw=2 et:
