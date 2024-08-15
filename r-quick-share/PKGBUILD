# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=r-quick-share
_pkgname=rquickshare
pkgver=0.11.1
pkgrel=1
pkgdesc="Rust implementation of NearbyShare/QuickShare from Android for Linux."
arch=('x86_64')
url="https://github.com/Martichou/rquickshare"
license=('GPL-3.0-or-later')
depends=('gtk3' 'libayatana-appindicator' 'webkit2gtk-4.1')
makedepends=('cargo' 'pnpm' 'protobuf')
source=("${_pkgname}-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('4f744450004e2f11e26349a22de15d8d44e4e0245b439953c7d9ca544f3b3f24')

prepare() {
  cd "${_pkgname}-$pkgver"
  export PNPM_HOME="$srcdir/pnpm-home"
  export RUSTUP_TOOLCHAIN=stable

  pushd app/main
  pnpm i
  popd

  pushd core_lib
  cargo fetch --target "$(rustc -vV | sed -n 's/host: //p')"
  popd

  # Don't bundle AppImage
  sed -i 's/"targets": "all"/"targets": "deb"/g' app/main/src-tauri/tauri.conf.json
}

build() {
  cd "${_pkgname}-$pkgver"
  export PNPM_HOME="$srcdir/pnpm-home"
  export RUSTUP_TOOLCHAIN=stable

  pushd app/main
  pnpm build
  popd
}

package() {
  cd "${_pkgname}-$pkgver/app/main/src-tauri"
  install -Dm755 "target/release/${_pkgname}" -t "$pkgdir/usr/bin/"

  for i in 32x32 128x128 128x128@2x; do
    install -Dm644 icons/${i}.png \
      "$pkgdir/usr/share/icons/hicolor/${i}/apps/${_pkgname}.png"
  done
  install -Dm644 icons/icon.png \
    "$pkgdir/usr/share/icons/hicolor/512x512/apps/${_pkgname}.png"

  install -Dm644 "target/release/bundle/deb//RQuickShare_${pkgver}_amd64/data/usr/share/applications/${_pkgname}.desktop" -t \
    "$pkgdir/usr/share/applications/"
}
