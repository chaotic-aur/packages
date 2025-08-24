# Maintainer: envolution
# Contributor: Doug Newgard <scimmia at archlinux dot org>
# shellcheck shell=bash disable=SC2034,SC2154
# ci|prebuild=_chrome_ver.sh| http://github.com/envolution/aur/blob/main/maintain/build/chromium-widevine/_chrome_ver.sh

pkgname=chromium-widevine
pkgdesc='A browser plugin designed for the viewing of premium video content'
pkgver=4.10.2891.0
_chrome_ver=139.0.7258.138
pkgrel=2
epoch=1
arch=('x86_64')
url='https://www.widevine.com/'
license=('LicenseRef-custom')
options=('!strip')
source=("https://dl.google.com/linux/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${_chrome_ver}-1_amd64.deb")
sha256sums=('3edc53950860ac6abf7b593f53557ff7368df5ab69835af4ab0a7a960b7268ea')

prepare() {
  bsdtar -x --strip-components 4 -f data.tar.xz opt/google/chrome/WidevineCdm
}

pkgver() {
  awk 'match($0,/"version": "([0-9.]*)"/,a) {print a[1];}' WidevineCdm/manifest.json
}

package() {
  depends=('gcc-libs' 'glib2' 'glibc' 'nspr' 'nss')

  install -dm755 "$pkgdir/usr/lib/chromium/"
  cp -a WidevineCdm "$pkgdir/usr/lib/chromium/"
  find "$pkgdir" -name '*.so' -exec chmod +x {} \;
  install -Dm644 WidevineCdm/LICENSE -t "$pkgdir/usr/share/licenses/$pkgname/"
  # backward compatibility
  ln -s WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so "$pkgdir/usr/lib/chromium/libwidevinecdm.so"
}
