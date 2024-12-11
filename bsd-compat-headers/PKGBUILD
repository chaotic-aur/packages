# Maintainer: txtsd <aur.archlinux@ihavea.quest>
# Contributor: Patrycja Rosa <alpine@ptrcnull.me>
# See: https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/main/bsd-compat-headers/APKBUILD

pkgname=bsd-compat-headers
pkgver=0.7.2
pkgrel=2
pkgdesc='BSD compatibility headers (tree)'
url='https://gitlab.alpinelinux.org/alpine/aports'
arch=(any)
license=('BSD-2-Clause AND BSD-3-Clause')
source=(tree.h)
sha256sums=('e0ea17940260f9c1fdd2d35f74eec141d21f09844eaea91131993cb950901a16')

package() {
  install -Dm644 tree.h -t "$pkgdir"/usr/include/sys
}
