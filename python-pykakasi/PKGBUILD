# Maintainer: Pekka Ristola <pekkarr [at] protonmail [dot] com>

pkgname=python-pykakasi
pkgver=2.3.0
pkgrel=2
pkgdesc='Lightweight converter from Japanese Kana-kanji sentences into Kana-Roman'
arch=(any)
url='https://codeberg.org/miurahr/pykakasi'
license=('GPL-3.0-or-later')
depends=(
  python
  python-deprecated
  python-jaconv
)
makedepends=(
  git
  python-build
  python-installer
  python-setuptools
  python-setuptools-scm
  python-sphinx
  python-wheel
)
source=("git+${url}.git#tag=v${pkgver}")
sha256sums=('d976864bda183f919e9dd70accd2d053d31101450550e54d51ca4f3d786fa696')

build() {
  cd pykakasi

  python -m build --wheel --no-isolation

  make -C docs text
}

package() {
  cd pykakasi

  python -m installer --destdir="${pkgdir}" dist/*.whl

  install -Dm644 -t "${pkgdir}/usr/share/doc/${pkgname}" docs/_build/text/*

  # rename script in /usr/bin to pykakasi in order to avoid conflicts with the kakasi package
  mv "${pkgdir}"/usr/bin/{,py}kakasi
}
