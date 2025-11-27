# Maintainer: txtsd <aur.archlinux@ihavea.quest>

pkgname=halloy
pkgver=2025.11
pkgrel=1
pkgdesc='An open-source IRC client written in Rust, with the Iced GUI library'
arch=(x86_64 aarch64)
url='https://github.com/squidowl/halloy'
license=('GPL-3.0-or-later')
depends=(
  alsa-lib
  gcc-libs
  glibc
  hicolor-icon-theme
  openssl
  libxcb
)
makedepends=(cargo)
checkdepends=(cargo)
options=('!lto')
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/squidowl/${pkgname}/archive/refs/tags/${pkgver}.tar.gz")
sha256sums=('19546fb2c49ea342e39c38b6771536089b16892b8de6ae4e4a09e4f25db3cd1b')

prepare() {
  cd "${pkgname}-${pkgver}"

  export RUSTUP_TOOLCHAIN=stable
  cargo fetch --locked --target "$(rustc -vV | sed -n 's/host: //p')"
}

build() {
  cd "${pkgname}-${pkgver}"

  export RUSTUP_TOOLCHAIN=stable
  export CARGO_TARGET_DIR=target
  cargo build --frozen --release
}

check() {
  cd "${pkgname}-${pkgver}"

  export RUSTUP_TOOLCHAIN=stable
  export CARGO_TARGET_DIR=target
  cargo test --frozen --release
}

package() {
  cd "${pkgname}-${pkgver}"

  install -Dm755 "target/release/${pkgname}" "${pkgdir}/usr/bin/${pkgname}"

  install -Dm644 README.md "${pkgdir}/usr/share/doc/${pkgname}/README.md"
  install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  install -Dm644 "assets/linux/org.squidowl.${pkgname}.appdata.xml" -t "${pkgdir}/usr/share/metainfo"
  install -Dm644 "assets/linux/org.squidowl.${pkgname}.desktop" -t "${pkgdir}/usr/share/applications"

  cp -dr assets/linux/icons "${pkgdir}/usr/share"
}
