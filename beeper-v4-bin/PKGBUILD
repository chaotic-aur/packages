# Maintainer: Arnaud Gissinger (contact: mathix.dev)

## options
: ${_autoupdate:=true}

: ${_install_path:=opt}

: ${_pkgtype=-v4-bin}

# basic info
_pkgname='beeper'
pkgname="$_pkgname${_pkgtype:-}"
pkgver=4.2.367
pkgrel=1
pkgdesc="The ultimate messaging app"
depends=(libappindicator-gtk3 libnotify libsecret hicolor-icon-theme)
url="https://www.beeper.com/beta"
license=('LicenseRef-beeper')
arch=('x86_64')

options=('!strip' '!debug')

_source_main() {
  provides=("$_pkgname")
  conflicts=("$_pkgname")

  source=("$_filename"::"$_dl_url")
  sha256sums=('SKIP')
}

pkgver() {
  printf '%s' "${_pkgver:?}"
}

build() {
  # extract appimage
  chmod +x "$_filename"
  "$srcdir/$_filename" --appimage-extract

  # fix apprun script
  sed -Ei \
    's@^(if \[ -z \"\$APPDIR\" ] ; then)$@APPDIR="/'"$_install_path"'/beeper"\n\1@' \
    "$srcdir/squashfs-root/AppRun"
}

_package_beeper() {
  # apprun script
  install -Dm755 "$srcdir/squashfs-root/AppRun" "$pkgdir/usr/bin/beeper"

  # everything else
  install -dm755 "$pkgdir/$_install_path"
  mv "$srcdir/squashfs-root" "$pkgdir/$_install_path/beeper"

  # remove default .desktop file
  rm -f "$pkgdir/$_install_path/beeper/beepertexts.desktop"

  # replace registerLinuxConfig function
  # Find the Linux config file and replace the export statement
  sed -i 's/export{[a-zA-Z0-9_]* as registerLinuxConfig};/const noopFunc=function(){};export{noopFunc as registerLinuxConfig};/' "$pkgdir/$_install_path/beeper/resources/app/build/main/linux-"*.mjs
}

package() {
  depends+=('hicolor-icon-theme')

  # desktop file
  install -Dm644 /dev/stdin "$pkgdir/usr/share/applications/beeper.desktop" << END
[Desktop Entry]
Type=Application
Name=${_pkgname^}
GenericName=Unified Messenger
Comment=$pkgdesc
Exec=$_pkgname --no-sandbox %U
Icon=beepertexts
Terminal=false
StartupWMClass=BeeperTexts
X-AppImage-Version=$pkgver
MimeType=x-scheme-handler/beeper;x-scheme-handler/matrix;x-scheme-handler/element;
Categories=Network;InstantMessaging;
END

  # icon
  install -Dm644 \
    "$srcdir/squashfs-root/usr/share/icons/hicolor/512x512/apps/beepertexts.png" \
    -t "$pkgdir/usr/share/icons/hicolor/512x512/apps"

  # license files
  install -Dm644 "$srcdir/squashfs-root/LICENSE.electron.txt" -t "$pkgdir/usr/share/licenses/$pkgname/"
  install -Dm644 "$srcdir/squashfs-root/LICENSES.chromium.html" -t "$pkgdir/usr/share/licenses/$pkgname/"

  _package_beeper

  # fix permissions
  chmod -R u+rwX,go+rX,go-w "$pkgdir"
}

_update_version() {
  : ${_pkgver:=$pkgver}

  if [[ "${_autoupdate::1}" != 't' ]]; then
    return
  fi

  _dl_url="https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop"

  _filename=$(
    curl -v -L --no-progress-meter -r 0-1 "$_dl_url" 2>&1 > /dev/null \
      | grep "GET /builds/" \
      | sed -E 's@^.*GET /builds/([^ ]+) HTTP/2.*$@\1@'
  )

  _pkgver_new=$(
    printf '%s' "$_filename" \
      | sed -E 's@^Beeper-([0-9]+\.[0-9]+\.[0-9]+)(.*)?.AppImage$@\1@'
  )

  # update _pkgver
  if [ "$_pkgver" != "${_pkgver_new:?}" ]; then
    _pkgver="$_pkgver_new"
  fi
}

_update_version
_source_main
