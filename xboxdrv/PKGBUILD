# Maintainer:
# Contributor: Levente Polyak <anthraxx[at]archlinux[dot]org>
# Contributor: Andrew Rabert <ar@nullsum.net>
# Contributor: Jack Mitchell <jack@embed.me.uk>
# Contributor: Kevin MacMartin <prurigro at gmail dot com>

_pkgname="xboxdrv"
pkgname="$_pkgname"
pkgver=0.8.11
pkgrel=1
pkgdesc="Userspace Xbox gamepad driver and input remapper"
url="https://github.com/xiota/xboxdrv"
license=('GPL-3.0-or-later')
arch=('x86_64')

depends=(
  'python'
  'dbus-glib'
  'dbus-python'
  'libusb'
  'libx11'

  # implicit
  #bash
  #dbus
  #glib2
  #systemd-libs
)
makedepends=(
  'git'
  'glib2-devel'
  'pkg-config'
  'scons'
)

backup=("etc/default/xboxdrv")

_pkgsrc="$_pkgname"
source=(
  "$_pkgsrc"::"git+$url.git#tag=v${pkgver}"
  "xboxdrv.default"
  "xboxdrv.service"
)
sha256sums=(
  'SKIP'
  '68a286300d28bbfc97eb694c6cc413776f0bc16e35de6d1969f13ef1e7d1cac5'
  'd631a8c3af7e2b4ef22f1494ded5d7a8029a8dd9756ef8907f909ef6aa0afc2b'
)

build() {
  cd "$_pkgsrc"
  scons \
    LINKFLAGS="$LDFLAGS" \
    CXXFLAGS="$CPPFLAGS $CXXFLAGS" \
    "$MAKEFLAGS"
}

package() {
  cd "$_pkgsrc"
  make PREFIX=/usr DESTDIR="$pkgdir" install

  install -Dm644 "$srcdir/$_pkgname.service" -t "$pkgdir/usr/lib/systemd/system/"
  install -Dm644 "$srcdir/$_pkgname.default" "$pkgdir/etc/default/$_pkgname"
  install -Dm644 README.md NEWS PROTOCOL -t "$pkgdir/usr/share/doc/$_pkgname/"
  install -Dm644 examples/* -t "$pkgdir/usr/share/doc/$_pkgname/examples/"
  install -Dm644 data/org.seul.Xboxdrv.conf -t "$pkgdir/etc/dbus-1/system.d/"
}
