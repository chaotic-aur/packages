# Maintainer: Andrew O'Neill <andrew at haunted dot sh>

pkgname=musikcube
pkgver=3.0.5
pkgrel=1
pkgdesc='A terminal-based cross-platform music player, audio engine, metadata indexer, and server'
arch=('x86_64')
url="https://github.com/clangen/${pkgname}"
license=('BSD-3-Clause')
depends=('faad2' 'libogg' 'libvorbis' 'flac' 'libmicrohttpd' 'lame' 'ncurses' 'libpipewire' 'pulse-native-provider' 'libpulse' 'libev' 'alsa-lib' 'curl' 'ffmpeg' 'taglib' 'libgme')
makedepends=('asio' 'cmake' 'nlohmann-json' 'patchelf' 'websocketpp')
optdepends=('libopenmpt: OpenMPT support')
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/${pkgver}.tar.gz")
sha256sums=('708292a583bb5072a8dbb14e408c2a1f61de9b8c9786d4e53b3e69bef5dad8c5')

build() {
  local cmake_options=(
    -B build
    -S "${pkgname}-${pkgver}"
    -W no-dev
    -D CMAKE_BUILD_TYPE=Release
    -D CMAKE_INSTALL_PREFIX=/usr
  )

  cmake "${cmake_options[@]}"
  cmake --build build
}

package() {
  DESTDIR="${pkgdir}" cmake --install build
  install -Dm644 "${pkgname}-${pkgver}"/LICENSE.txt "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
