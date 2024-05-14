# Maintainer: loathingkernel <loathingkernel _a_ gmail _d_ com>

pkgname=umu-launcher
pkgver=0.1.RC4.r49.80579e5
pkgrel=1
pkgdesc="This is the Unified Launcher for Windows Games on Linux, to run Proton with fixes outside of Steam"
arch=('x86_64')
url="https://github.com/Open-Wine-Components/umu-launcher"
license=('GPL-3.0-only')
depends=(
  # steam
  bash
  desktop-file-utils
  diffutils
  hicolor-icon-theme
  curl
  dbus
  freetype2
  gdk-pixbuf2
  ttf-font
  zenity
  lsb-release
  nss
  usbutils
  xorg-xrandr
  vulkan-driver
  vulkan-icd-loader
  lsof
  python
  xdg-user-dirs
  glibc
  libxcrypt
  libxcrypt-compat
  gcc-libs
)
depends_x86_64=(
  lib32-glibc
  lib32-libxcrypt
  lib32-libxcrypt-compat
  lib32-libgl
  lib32-gcc-libs
  lib32-libx11
  lib32-libxss
  lib32-alsa-plugins
  lib32-libgpg-error
  lib32-nss
  lib32-vulkan-driver
  lib32-vulkan-icd-loader
)
makedepends=(
  git
  meson
  ninja
  scdoc
)
provides=('ulwgl-launcher')
conflicts=('ulwgl-launcher')
replaces=('ulwgl-launcher')
install=
_commit=80579e5d11219c9c1955d82a3275362319accfa1
_origin="https://github.com/Open-Wine-Components/umu-launcher.git"
source=(
  "git+$_origin#commit=$_commit"
)

pkgver() {
  cd "$srcdir"/umu-launcher
  printf "%s" "$(git describe --long --tags | sed 's/\([^-]*-\)g/r\1/;s/-/./g')"
}

prepare() {
  cd "$srcdir"/umu-launcher
  git remote set-url origin "$_origin"
  git submodule update --init --filter=tree:0 --recursive
}

build() {
  cd "$srcdir/umu-launcher"
  ./configure.sh --prefix=/usr
  make
}

package() {
  cd "$srcdir/umu-launcher"
  make DESTDIR="$pkgdir" install
}

sha256sums=('0210eee4f8c63ff8f34955a8b955ff1cfa2dc79a7b2e6cf30edd823925904691')
