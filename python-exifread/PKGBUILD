# Contributor: nblock <nblock [/at\] archlinux DOT us>
# Contributor: Simon Chabot <simon dot chabot at etu dot utc dot fr>
# Contributor: Christopher Loen <christopherloen at gmail dot com>
# Contributor: David McInnis <davidm@eagles.ewu.edu>

pkgname=python-exifread
_name="exifread"
pkgver=3.3.1
pkgrel=1
pkgdesc="Python library to extract EXIF data from tiff and jpeg files"
arch=('any')
url="https://github.com/ianare/exif-py"
license=('BSD')
depends=('python')
makedepends=('python-build' 'python-installer' 'python-setuptools')
source=("https://files.pythonhosted.org/packages/source/${_name::1}/$_name/$_name-$pkgver.tar.gz")
sha1sums=('4223ba050940b449b4be5b71e99723f7b87cef2b')
sha256sums=('320d8596c1f674a1da2c10cf30408bb9675262c4c0181bebbd3570679d2f1340')

build() {
  cd "$_name-$pkgver"
  python -m build --wheel --no-isolation
}

package() {
  cd "$_name-$pkgver"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  python -m installer --destdir="$pkgdir" dist/*.whl
}

# vim:set ts=2 sw=2 et:
