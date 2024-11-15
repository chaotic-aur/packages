# Maintainer: txtsd <aur.archlinux@ihavea.quest>
# Contributor: Caleb Maclennan <caleb@alerque.com>
# Contributor: Tyler Swagar <distorto@member.fsf.org>

pkgname=ttf-signika
_pkgname=Signika
pkgver=2.003
_commit='7361a224d1d77274af1ea11dd06448c54c16f598'
pkgrel=1
pkgdesc='Sans-serif typeface from Google by Anna Giedryś'
arch=(any)
url="https://github.com/googlefonts/${_pkgname}"
license=('OFL-1.1')
source=("${pkgname}-${_commit}.tar.gz::${url}/archive/${_commit}.tar.gz")
sha256sums=('6a01f2e484675a742ce6b0485c6b8f7844634aa7a8370a285e1cf7897cbae957')

package() {
  cd "${_pkgname}-${_commit}"

  install -Dm0644 -t "${pkgdir}/usr/share/fonts/${_pkgname}" fonts/{ttf,variable,variable_negative}/*.ttf
  install -Dm0644 -t "${pkgdir}/usr/share/licenses/${pkgname}" OFL.txt CONTRIBUTORS.txt AUTHORS.txt
}
