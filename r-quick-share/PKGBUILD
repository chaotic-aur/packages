# Maintainer: Mark Wagie <mark dot wagie at proton dot me>
pkgname=r-quick-share
_pkgname=rquickshare
pkgver=0.10.1
pkgrel=1
pkgdesc="Rust implementation of NearbyShare/QuickShare from Android for Linux."
arch=('x86_64')
url="https://github.com/Martichou/rquickshare"
license=('GPL-3.0-or-later')
depends=('gtk3' 'libayatana-appindicator' 'webkit2gtk-4.1')
makedepends=('cargo' 'pnpm' 'protobuf')
source=("${_pkgname}-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('9d423726ed0469e539c73c269d7229b081d00d6cdfd5f780a8785f444483fa68')

prepare() {
  cd ${_pkgname}-$pkgver
  export PNPM_HOME="$srcdir/pnpm-home"
  export CARGO_HOME="$srcdir/cargo-home"
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
  cd ${_pkgname}-$pkgver
  export PNPM_HOME="$srcdir/pnpm-home"
  export CARGO_HOME="$srcdir/cargo-home"
  export RUSTUP_TOOLCHAIN=stable

  pushd app/main
  pnpm build
  popd
}

package() {
  cd ${_pkgname}-$pkgver
  _bundledir="app/main/src-tauri/target/release/bundle/deb/RQuickShare_${pkgver}_amd64"

  install -Dm755 "app/main/src-tauri/target/release/${_pkgname}" -t "$pkgdir/usr/bin/"

  for i in 32x32 128x128 128x128@2x; do
    install -Dm644 app/main/src-tauri/icons/${i}.png \
      "$pkgdir/usr/share/icons/hicolor/${i}/apps/${_pkgname}.png"
  done
  install -Dm644 app/main/src-tauri/icons/icon.png \
    "$pkgdir/usr/share/icons/hicolor/512x512/apps/${_pkgname}.png"

  install -Dm644 "${_bundledir}/data/usr/share/applications/${_pkgname}.desktop" -t \
    "$pkgdir/usr/share/applications/"
}
