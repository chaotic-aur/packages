# Maintainer:
# Contributor: westpain <homicide@disroot.org>
# Contributor: rikki48 <xdxdxdxdlmao@mail.ru>

## options
: ${_branch:=dev}

_pkgname="ayugram-desktop"
pkgname="$_pkgname-git"
pkgver=5.12.3.r3.gb3552d8
pkgrel=2
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

_source_ayugram() {
  source+=(
    #'apple.swift-corelibs-libdispatch'::'git+https://github.com/apple/swift-corelibs-libdispatch.git'
    'ayugram.codegen'::'git+https://github.com/AyuGram/codegen.git'
    'ayugram.lib_tl'::'git+https://github.com/AyuGram/lib_tl.git'
    'ayugram.lib_ui'::'git+https://github.com/AyuGram/lib_ui.git'
    'cyan4973.xxhash'::'git+https://github.com/Cyan4973/xxHash.git'
    'desktop-app.cmake_helpers'::'git+https://github.com/desktop-app/cmake_helpers.git'
    'desktop-app.lib_base'::'git+https://github.com/desktop-app/lib_base.git'
    'desktop-app.lib_crl'::'git+https://github.com/desktop-app/lib_crl.git'
    'desktop-app.lib_lottie'::'git+https://github.com/desktop-app/lib_lottie.git'
    'desktop-app.lib_qr'::'git+https://github.com/desktop-app/lib_qr.git'
    'desktop-app.lib_rpl'::'git+https://github.com/desktop-app/lib_rpl.git'
    'desktop-app.lib_spellcheck'::'git+https://github.com/desktop-app/lib_spellcheck.git'
    'desktop-app.lib_storage'::'git+https://github.com/desktop-app/lib_storage.git'
    'desktop-app.lib_webrtc'::'git+https://github.com/desktop-app/lib_webrtc.git'
    'desktop-app.lib_webview'::'git+https://github.com/desktop-app/lib_webview.git'
    'desktop-app.libprisma'::'git+https://github.com/desktop-app/libprisma.git'
    'desktop-app.rlottie'::'git+https://github.com/desktop-app/rlottie.git'
    #'ericniebler.range-v3'::'git+https://github.com/ericniebler/range-v3.git'
    'fcitx.fcitx5-qt'::'git+https://github.com/fcitx/fcitx5-qt.git'
    'flatpak.xdg-desktop-portal'::'git+https://github.com/flatpak/xdg-desktop-portal.git'
    'google.cld3'::'git+https://github.com/google/cld3.git'
    'hamonikr.nimf'::'git+https://github.com/hamonikr/nimf.git'
    'hime-ime.hime'::'git+https://github.com/hime-ime/hime.git'
    #'hunspell'::'git+https://github.com/hunspell/hunspell.git'
    #'jemalloc'::'git+https://github.com/jemalloc/jemalloc.git'
    #'kde.kcoreaddons'::'git+https://github.com/KDE/kcoreaddons.git'
    #'kde.kimageformats'::'git+https://github.com/KDE/kimageformats.git'
    #'lz4'::'git+https://github.com/lz4/lz4.git'
    'microsoft.gsl'::'git+https://github.com/Microsoft/GSL.git'
    'nayuki.qr-code-generator'::'git+https://github.com/nayuki/QR-Code-generator.git'
    'tartanllama.expected'::'git+https://github.com/TartanLlama/expected.git'
    'telegramdesktop.libtgvoip'::'git+https://github.com/telegramdesktop/libtgvoip.git'
    'telegrammessenger.tgcalls'::'git+https://github.com/TelegramMessenger/tgcalls.git'
  )
  sha256sums+=(
    #'SKIP'
    #'SKIP'
    #'SKIP'
    #'SKIP'
    #'SKIP'
    #'SKIP'
    #'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
  )

  _prepare_ayugram() (
    cd "$srcdir/$_pkgsrc"
    local _submodules=(
      #'apple.swift-corelibs-libdispatch'::'Telegram/ThirdParty/dispatch'
      'ayugram.codegen'::'Telegram/codegen'
      'ayugram.lib_tl'::'Telegram/lib_tl'
      'ayugram.lib_ui'::'Telegram/lib_ui'
      'cyan4973.xxhash'::'Telegram/ThirdParty/xxHash'
      'desktop-app.cmake_helpers'::'cmake'
      'desktop-app.lib_base'::'Telegram/lib_base'
      'desktop-app.lib_crl'::'Telegram/lib_crl'
      'desktop-app.lib_lottie'::'Telegram/lib_lottie'
      'desktop-app.lib_qr'::'Telegram/lib_qr'
      'desktop-app.lib_rpl'::'Telegram/lib_rpl'
      'desktop-app.lib_spellcheck'::'Telegram/lib_spellcheck'
      'desktop-app.lib_storage'::'Telegram/lib_storage'
      'desktop-app.lib_webrtc'::'Telegram/lib_webrtc'
      'desktop-app.lib_webview'::'Telegram/lib_webview'
      'desktop-app.libprisma'::'Telegram/ThirdParty/libprisma'
      'desktop-app.rlottie'::'Telegram/ThirdParty/rlottie'
      #'ericniebler.range-v3'::'Telegram/ThirdParty/range-v3'
      'fcitx.fcitx5-qt'::'Telegram/ThirdParty/fcitx5-qt'
      'flatpak.xdg-desktop-portal'::'Telegram/ThirdParty/xdg-desktop-portal'
      'google.cld3'::'Telegram/ThirdParty/cld3'
      'hamonikr.nimf'::'Telegram/ThirdParty/nimf'
      'hime-ime.hime'::'Telegram/ThirdParty/hime'
      #'hunspell'::'Telegram/ThirdParty/hunspell'
      #'jemalloc'::'Telegram/ThirdParty/jemalloc'
      #'kde.kcoreaddons'::'Telegram/ThirdParty/kcoreaddons'
      #'kde.kimageformats'::'Telegram/ThirdParty/kimageformats'
      #'lz4'::'Telegram/ThirdParty/lz4'
      'microsoft.gsl'::'Telegram/ThirdParty/GSL'
      'nayuki.qr-code-generator'::'Telegram/ThirdParty/QR'
      'tartanllama.expected'::'Telegram/ThirdParty/expected'
      'telegramdesktop.libtgvoip'::'Telegram/ThirdParty/libtgvoip'
      'telegrammessenger.tgcalls'::'Telegram/ThirdParty/tgcalls'
    )
    _submodule_update
  )
}

_source_desktop_app_cmake_helpers() {
  source+=(
    'mnauw.cppgir'::'git+https://gitlab.com/mnauw/cppgir.git'
    'yugr.implib.so'::'git+https://github.com/yugr/Implib.so.git'
  )
  sha256sums+=(
    'SKIP'
    'SKIP'
  )

  _prepare_desktop_app_cmake_helpers() (
    cd "$srcdir/$_pkgsrc"
    cd "cmake"
    local _submodules=(
      'mnauw.cppgir'::'external/glib/cppgir'
      'yugr.implib.so'::'external/Implib.so'
    )
    _submodule_update
  )
}

_source_mnauw_cppgir() {
  source+=(
    'martinmoene.expected-lite'::'git+https://github.com/martinmoene/expected-lite.git'
  )
  sha256sums+=(
    'SKIP'
  )

  _prepare_mnauw_cppgir() (
    cd "$srcdir/$_pkgsrc"
    cd "cmake"
    cd "external/glib/cppgir"
    local _submodules=(
      'martinmoene.expected-lite'::'expected-lite'
    )
    _submodule_update
  )
}

_source_main
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

  _prepare_ayugram
  _prepare_desktop_app_cmake_helpers
  _prepare_mnauw_cppgir

  # for Qt 6.9
  sed -E -e 's&QGenericUnixServices&QDesktopUnixServices&' \
    -e 's&qgenericunixservices_p&qdesktopunixservices_p&' \
    -i "$_pkgsrc/Telegram/lib_base/base/platform/linux/base_linux_xdp_utilities.cpp"
}

pkgver() {
  cd "$_pkgsrc"
  git describe --long --tags --abbrev=7 \
    | sed -E 's/^[^0-9]*//;s/([^-]*-g)/r\1/;s/-/./g'
}

build() {
  local _cmake_options=(
    -B build
    -S "$_pkgsrc"
    -G Ninja
    -DCMAKE_BUILD_TYPE=None
    -DCMAKE_INSTALL_PREFIX=/usr
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
