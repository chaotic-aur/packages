# Maintainer:
# Contributor: westpain <homicide@disroot.org>
# Contributor: rikki48 <xdxdxdxdlmao@mail.ru>

## options
: ${_use_sodeps:=false}

: ${_branch:=dev}
: ${_commit=}

_pkgname="ayugram-desktop"
pkgname="$_pkgname-git"
pkgver=5.16.4.r377.ge2d772d
pkgrel=2
pkgdesc="Desktop Telegram client with good customization and Ghost mode"
url="https://github.com/AyuGram/AyuGramDesktop"
license=('GPL-3.0-or-later')
arch=('x86_64' 'aarch64')

depends=(
  ada
  ffmpeg
  hunspell
  kcoreaddons
  libavif
  libdispatch
  libheif
  libjxl
  libvpx
  libxdamage
  minizip
  openal
  openh264
  opus
  protobuf
  qt6-base
  qt6-declarative
  qt6-svg
  qt6-wayland
  rnnoise
  xcb-util-keysyms
  xxhash

  ## for libtg_owt
  libpipewire
  libxcomposite
  libxrandr
  libxtst
)
makedepends=(
  boost
  cmake
  extra-cmake-modules
  fmt
  git
  glib2-devel
  gobject-introspection
  gperf    # for tdlib
  jemalloc # gio error when absent
  libtg_owt
  ninja
  range-v3
  tl-expected
)
optdepends=(
  'webkit2gtk: embedded browser features'
  'xdg-desktop-portal: desktop integration'
)

provides=("$_pkgname")
conflicts=("$_pkgname")

_pkgsrc="$_pkgname"
_pkgsrc_tdlib="telegram-tdlib"
_patch_commit="354be0d07b11404572577b40914f67adac3de49f"
source=(
  "$_pkgsrc"::"git+$url.git${_commit:+#commit=$_commit}${_commit:-${_branch:+#branch=$_branch}}"
  "$_pkgsrc_tdlib"::"git+https://github.com/tdlib/td.git"
  "0001-glib2.86-${_patch_commit::7}.patch"::"https://gitlab.archlinux.org/archlinux/packaging/packages/telegram-desktop/-/raw/${_patch_commit}/glib2.86.patch"
  "0002-ffmpeg-8-${_patch_commit::7}.patch"::"https://gitlab.archlinux.org/archlinux/packaging/packages/telegram-desktop/-/raw/${_patch_commit}/0001-Fix-compatibility-with-ffmpeg-8.patch"
  "0003-fix-qt-6.10-tdesktop.patch"::"https://github.com/telegramdesktop/tdesktop/commit/28d19a99.patch"
)
sha256sums=(
  'SKIP'
  'SKIP'
  '57b855e701ed29da039431b2688082e6885c368e20dd38bbedffe1633e5efeda'
  'd44a47b0dda36762090bbfcbb8e402d7308f3646d99a882b7d5fc3c18cc63540'
  'e3aabdf4942f1e22819dffe4eb481ca0d7e32cfbed9443120c2d29f3abf07971'
)

prepare() {
  cd "$_pkgsrc"
  git rm -r 'Telegram/ThirdParty/dispatch'
  git rm -r 'Telegram/ThirdParty/range-v3'
  git rm -r 'Telegram/ThirdParty/hunspell'
  git rm -r 'Telegram/ThirdParty/kcoreaddons'
  git rm -r 'Telegram/ThirdParty/lz4'
  git submodule update --init --recursive --depth=1

  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    src="${src%.zst}"
    if [[ $src == *.patch ]]; then
      printf '\nApplying patch: %s\n' "$src"
      patch -Np1 -F100 -i "${srcdir:?}/$src" || true
    fi
  done

  # Fix for Qt 6.10
  sed -e '1i find_package(Qt${QT_VERSION_MAJOR} COMPONENTS GuiPrivate WidgetsPrivate REQUIRED)' -i cmake/external/qt/CMakeLists.txt
}

pkgver() {
  cd "$_pkgsrc"
  git describe --long --tags --abbrev=7 --exclude='*[a-zA-Z][a-zA-Z]*' \
    | sed -E 's/^[^0-9]+//;s/([^-]*-g)/r\1/;s/-/./g'
}

build() {
  echo "Building tde2e..."
  local _cmake_tde2e=(
    -B "build_tde2e"
    -S "$_pkgsrc_tdlib"
    -G Ninja
    -DCMAKE_BUILD_TYPE=None
    -DCMAKE_INSTALL_PREFIX=/usr
    -DTD_E2E_ONLY=ON
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_TESTING=OFF
    -Wno-dev
  )

  cmake "${_cmake_tde2e[@]}"
  cmake --build "build_tde2e"
  DESTDIR="$srcdir/deps" cmake --install "build_tde2e"

  echo "Building ayugram..."
  local _cmake_options=(
    -B build
    -S "$_pkgsrc"
    -G Ninja
    -DCMAKE_BUILD_TYPE=None
    -DCMAKE_INSTALL_PREFIX=/usr
    -DCMAKE_PREFIX_PATH="$srcdir/deps/usr"
    -DDESKTOP_APP_DISABLE_AUTOUPDATE=ON
    -DTDESKTOP_API_TEST=ON
    -DTDESKTOP_API_ID=611335
    -DTDESKTOP_API_HASH=d524b414d21f4d37f08684c1df41ac9c
    -DDESKTOP_APP_USE_PACKAGED_FONTS=OFF
    -Wno-dev
  )

  cmake "${_cmake_options[@]}"
  cmake --build build
}

package() {
  if [[ "${_use_sodeps::1}" == "t" ]]; then
    eval "depends+=(
      'libavcodec.so'
      'libavfilter.so'
      'libavformat.so'
      'libavutil.so'
      'libcrypto.so'
      'libgio-2.0.so'
      'libglib-2.0.so'
      'libgobject-2.0.so'
      'libheif.so'
      'libjpeg.so'
      'libjxl.so'
      'libjxl_threads.so'
      'liblz4.so'
      'libopenal.so'
      'libopenh264.so'
      'libopus.so'
      'libpipewire-0.3.so'
      'libprotobuf-lite.so'
      'libssl.so'
      'libswresample.so'
      'libswscale.so'
      'libvpx.so'
      'libxkbcommon.so'
      'libxxhash.so'
      'libz.so'
    )"
  fi

  DESTDIR="$pkgdir" cmake --install build
}
