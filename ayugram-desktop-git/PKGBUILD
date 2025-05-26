# Maintainer:
# Contributor: westpain <homicide@disroot.org>
# Contributor: rikki48 <xdxdxdxdlmao@mail.ru>

## options
: ${_branch:=dev}

_pkgname="ayugram-desktop"
pkgname="$_pkgname-git"
pkgver=5.14.3.r0.g3c7f3e8
pkgrel=1
pkgdesc="Desktop Telegram client with good customization and Ghost mode"
url="https://github.com/AyuGram/AyuGramDesktop"
license=('GPL-3.0-or-later')
arch=('x86_64' 'aarch64')

depends=(
  ada
  ffmpeg
  hunspell
  jemalloc
  kcoreaddons
  libdispatch
  libpipewire
  libvpx
  libxcomposite
  libxdamage
  libxrandr
  libxtst
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
)
makedepends=(
  boost
  cmake
  extra-cmake-modules
  fmt
  git
  glib2-devel
  gobject-introspection
  libtg_owt
  microsoft-gsl
  mm-common
  ninja
  perl-xml-parser
  plasma-wayland-protocols
  python
  python-packaging
  range-v3
  tl-expected
  wayland-protocols
)
optdepends=(
  'webkit2gtk: embedded browser features'
  'xdg-desktop-portal: desktop integration'
)

provides=("$_pkgname")
conflicts=("$_pkgname")

_source_main() {
  _pkgsrc="$_pkgname"
  source=("$_pkgsrc"::"git+$url.git#branch=${_branch:-dev}")
  sha256sums=('SKIP')
}

_source_tdlib() {
  makedepends+=('gperf')

  _pkgsrc_tdlib="telegram-tdlib"
  source+=("$_pkgsrc_tdlib"::"git+https://github.com/tdlib/td.git")
  sha256sums+=('SKIP')
}

_source_ayugram() {
  local _sources_add=(
    #'apple.swift-corelibs-libdispatch'::'git+https://github.com/apple/swift-corelibs-libdispatch.git'::'Telegram/ThirdParty/dispatch'
    'ayugram.codegen'::'git+https://github.com/AyuGram/codegen.git'::'Telegram/codegen'
    'ayugram.lib_tl'::'git+https://github.com/AyuGram/lib_tl.git'::'Telegram/lib_tl'
    'ayugram.lib_ui'::'git+https://github.com/AyuGram/lib_ui.git'::'Telegram/lib_ui'
    'cyan4973.xxhash'::'git+https://github.com/Cyan4973/xxHash.git'::'Telegram/ThirdParty/xxHash'
    'desktop-app.cmake_helpers'::'git+https://github.com/desktop-app/cmake_helpers.git'::'cmake'
    'desktop-app.lib_base'::'git+https://github.com/desktop-app/lib_base.git'::'Telegram/lib_base'
    'desktop-app.lib_crl'::'git+https://github.com/desktop-app/lib_crl.git'::'Telegram/lib_crl'
    'desktop-app.lib_lottie'::'git+https://github.com/desktop-app/lib_lottie.git'::'Telegram/lib_lottie'
    'desktop-app.lib_qr'::'git+https://github.com/desktop-app/lib_qr.git'::'Telegram/lib_qr'
    'desktop-app.lib_rpl'::'git+https://github.com/desktop-app/lib_rpl.git'::'Telegram/lib_rpl'
    'desktop-app.lib_spellcheck'::'git+https://github.com/desktop-app/lib_spellcheck.git'::'Telegram/lib_spellcheck'
    'desktop-app.lib_storage'::'git+https://github.com/desktop-app/lib_storage.git'::'Telegram/lib_storage'
    'desktop-app.lib_webrtc'::'git+https://github.com/desktop-app/lib_webrtc.git'::'Telegram/lib_webrtc'
    'desktop-app.lib_webview'::'git+https://github.com/desktop-app/lib_webview.git'::'Telegram/lib_webview'
    'desktop-app.libprisma'::'git+https://github.com/desktop-app/libprisma.git'::'Telegram/ThirdParty/libprisma'
    'desktop-app.rlottie'::'git+https://github.com/desktop-app/rlottie.git'::'Telegram/ThirdParty/rlottie'
    #'ericniebler.range-v3'::'git+https://github.com/ericniebler/range-v3.git'::'Telegram/ThirdParty/range-v3'
    'fcitx.fcitx5-qt'::'git+https://github.com/fcitx/fcitx5-qt.git'::'Telegram/ThirdParty/fcitx5-qt'
    'flatpak.xdg-desktop-portal'::'git+https://github.com/flatpak/xdg-desktop-portal.git'::'Telegram/ThirdParty/xdg-desktop-portal'
    'google.cld3'::'git+https://github.com/google/cld3.git'::'Telegram/ThirdParty/cld3'
    'hamonikr.nimf'::'git+https://github.com/hamonikr/nimf.git'::'Telegram/ThirdParty/nimf'
    'hime-ime.hime'::'git+https://github.com/hime-ime/hime.git'::'Telegram/ThirdParty/hime'
    #'hunspell'::'git+https://github.com/hunspell/hunspell.git'::'Telegram/ThirdParty/hunspell'
    #'jemalloc'::'git+https://github.com/jemalloc/jemalloc.git'::'Telegram/ThirdParty/jemalloc'
    #'kde.kcoreaddons'::'git+https://github.com/KDE/kcoreaddons.git'::'Telegram/ThirdParty/kcoreaddons'
    #'kde.kimageformats'::'git+https://github.com/KDE/kimageformats.git'::'Telegram/ThirdParty/kimageformats'
    #'lz4'::'git+https://github.com/lz4/lz4.git'::'Telegram/ThirdParty/lz4'
    'microsoft.gsl'::'git+https://github.com/Microsoft/GSL.git'::'Telegram/ThirdParty/GSL'
    'nayuki.qr-code-generator'::'git+https://github.com/nayuki/QR-Code-generator.git'::'Telegram/ThirdParty/QR'
    'tartanllama.expected'::'git+https://github.com/TartanLlama/expected.git'::'Telegram/ThirdParty/expected'
    'telegramdesktop.libtgvoip'::'git+https://github.com/telegramdesktop/libtgvoip.git'::'Telegram/ThirdParty/libtgvoip'
    'telegrammessenger.tgcalls'::'git+https://github.com/TelegramMessenger/tgcalls.git'::'Telegram/ThirdParty/tgcalls'
  )

  local _p _idx _src _sm_prep _sm_func
  for _p in ${_sources_add[@]}; do
    _idx="${_p%%::*}"
    _sm_prep+=("${_idx}::${_p##*::}")
    _src="${_p%::*}"
    source+=("$_src")
    sha256sums+=('SKIP')
  done

  eval "_prepare_ayugram() (
    cd \"\$srcdir/\$_pkgsrc\"
    local _submodules=(${_sm_prep[@]})
    _submodule_update
  )"
}

_source_desktop_app_cmake_helpers() {
  local _sources_add=(
    'mnauw.cppgir'::'git+https://gitlab.com/mnauw/cppgir.git'::'external/glib/cppgir'
    'yugr.implib.so'::'git+https://github.com/yugr/Implib.so.git'::'external/Implib.so'
  )

  local _p _idx _src _sm_prep _sm_func
  for _p in ${_sources_add[@]}; do
    _idx="${_p%%::*}"
    _sm_prep+=("${_idx}::${_p##*::}")
    _src="${_p%::*}"
    source+=("$_src")
    sha256sums+=('SKIP')
  done

  eval "_prepare_desktop_app_cmake_helpers() (
    cd \"\$srcdir/\$_pkgsrc\"
    cd 'cmake'
    local _submodules=(${_sm_prep[@]})
    _submodule_update
  )"
}

_source_mnauw_cppgir() {
  local _sources_add=(
    'martinmoene.expected-lite'::'git+https://github.com/martinmoene/expected-lite.git'::'expected-lite'
  )

  local _p _idx _src _sm_prep _sm_func
  for _p in ${_sources_add[@]}; do
    _idx="${_p%%::*}"
    _sm_prep+=("${_idx}::${_p##*::}")
    _src="${_p%::*}"
    source+=("$_src")
    sha256sums+=('SKIP')
  done

  eval "_prepare_mnauw_cppgir() (
    cd \"\$srcdir/\$_pkgsrc\"
    cd 'cmake'
    cd 'external/glib/cppgir'
    local _submodules=(${_sm_prep[@]})
    _submodule_update
  )"
}

_source_main
_source_tdlib
_source_ayugram

_source_desktop_app_cmake_helpers
_source_mnauw_cppgir

prepare() {
  _submodule_update() {
    local _module
    for _module in "${_submodules[@]}"; do
      git submodule init "${_module##*::}"
      git submodule set-url "${_module##*::}" "$srcdir/${_module%::*}"
      git -c protocol.file.allow=always submodule update "${_module##*::}"
    done
  }

  _run_if_exists _prepare_ayugram
  _run_if_exists _prepare_desktop_app_cmake_helpers
  _run_if_exists _prepare_mnauw_cppgir
}

pkgver() {
  cd "$_pkgsrc"
  git describe --long --tags --abbrev=7 \
    | sed -E 's/^[^0-9]*//;s/([^-]*-g)/r\1/;s/-/./g'
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
  DESTDIR="$pkgdir" cmake --install build
}

_run_if_exists() {
  if declare -F "$1" > /dev/null; then
    eval "$1"
  fi
}
