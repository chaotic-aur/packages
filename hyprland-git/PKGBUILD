# Maintainer: FabioLolix
# Maintainer: éclairevoyant
# Maintainer: alba4k <blaskoazzolaaaron[at]gmail.com>
# Contributor: ThatOneCalculator <kainoa at t1c dot dev>

_pkgname="hyprland"
pkgname="$_pkgname-git"
pkgver=0.50.0.r114.g0ed880f
pkgrel=1
pkgdesc="Hyprland is an independent, highly customizable, dynamic tiling Wayland compositor that doesn't sacrifice on its looks"
arch=('x86_64' 'aarch64')
url="https://github.com/hyprwm/Hyprland"
license=('BSD-3-Clause')

depends=(
  aquamarine-git
  cairo
  gcc-libs
  glib2
  glibc
  glslang
  hyprcursor-git
  hyprgraphics-git
  hyprland-qtutils-git
  hyprlang-git
  hyprutils-git
  libdisplay-info
  libdrm
  libglvnd
  libinput
  libliftoff
  libx11
  libxcb
  libxcomposite
  libxcursor
  libxfixes
  libxkbcommon
  libxrender
  mesa
  opengl-driver
  pango
  pixman
  polkit
  re2
  seatd
  systemd-libs
  tomlplusplus
  util-linux-libs
  wayland
  wayland-protocols
  xcb-proto
  xcb-util
  xcb-util-errors
  xcb-util-image
  xcb-util-keysyms
  xcb-util-renderutil
  xcb-util-wm
  xorg-xwayland
)
makedepends=(
  cmake
  git
  glaze
  hyprland-protocols-git
  hyprwayland-scanner-git
  ninja
  #patch
  #pkgconf
  python # required by udis86
  xorgproto
)
optdepends=(
  'cmake: to build and install plugins using hyprpm'
  'cpio: to build and install plugins using hyprpm'
  'glaze: to build and install plugins using hyprpm'
  'hyprqt6engine-git: the recommended way to manage qt styles'
  'meson: to build and install plugins using hyprpm'
  'uwsm: the recommended way to start Hyprland'
)

conflicts=("$_pkgname")
provides=("$_pkgname=${pkgver%%.r*}" "wayland-compositor")

_pkgsrc=$_pkgname
source=(
  "$_pkgsrc::git+$url.git"
  "udis86::git+https://github.com/canihavesomecoffee/udis86.git"
)
sha256sums=(
  'SKIP'
  'SKIP'
)

backup=("usr/share/xdg-desktop-portal/hyprland-portals.conf")

prepare() {
  cd "$_pkgsrc"
  git submodule init
  git config submodule.subprojects/udis86.url "$srcdir/udis86"
  git config submodule.subprojects/tracy.update none
  git -c protocol.file.allow=always submodule update

  if [[ -z "$(git config --get user.name)" ]]; then
    git config user.name local && git config user.email '<>' && git config commit.gpgsign false
  fi
}

pkgver() {
  cd "$_pkgsrc"
  git describe --long --tags --abbrev=7 | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}

build() {
  local cmake_options=(
    -B build
    -S "$_pkgsrc"
    -G Ninja
    -W no-dev
    -D CMAKE_BUILD_TYPE=None
    -D CMAKE_INSTALL_PREFIX=/usr
  )
  cmake "${cmake_options[@]}"
  cmake --build build
}

package() {
  DESTDIR="$pkgdir" cmake --install build
  install -Dm0644 "$_pkgsrc/LICENSE" -t "$pkgdir/usr/share/licenses/${pkgname}/"
  install -Dm0644 "$_pkgsrc/subprojects/udis86/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE-udis86"
}
