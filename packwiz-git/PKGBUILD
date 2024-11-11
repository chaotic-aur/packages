# Maintainer: Sefa Eyeoglu <contact@scrumplex.net>
# Contributor: Caleb Fontenot <foley2431 at gmail dot com>
# Contributor: Lgmrszd <lgmrszd at gmail dot com>

pkgname=packwiz-git
_pkgname="${pkgname%-git}"
pkgver=r369.0626c00
pkgrel=2
pkgdesc="A command line tool for creating minecraft modpacks."
arch=(x86_64)
url='https://packwiz.infra.link'
license=('MIT')
depends=('glibc')
makedepends=('git' 'go')
provides=("${_pkgname}")
conflicts=("${_pkgname}")
source=('git+https://github.com/packwiz/packwiz.git')
sha256sums=('SKIP')

pkgver() {
  cd "${_pkgname}"

  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
  cd "${_pkgname}"

  mkdir -p "completions"

  export GOPATH="${srcdir}"
  export GOFLAGS="-modcacherw"
  go mod download
}

build() {
  cd "${_pkgname}"

  export CGO_CPPFLAGS="${CPPFLAGS}"
  export CGO_CFLAGS="${CFLAGS}"
  export CGO_CXXFLAGS="${CXXFLAGS}"
  export CGO_LDFLAGS="${LDFLAGS}"
  export GOPATH="${srcdir}"
  export GOFLAGS="\
    -buildmode=pie \
    -mod=readonly \
    -modcacherw \
    -trimpath \
  "
  local _ld_flags=" \
    -compressdwarf=false \
    -linkmode=external \
  "
  go build \
    -ldflags "${_ldflags}" \
    -o "${_pkgname}"

  ./packwiz completion bash > completions/packwiz.bash
  ./packwiz completion zsh > completions/packwiz.zsh
  ./packwiz completion fish > completions/packwiz.fish
}

package() {
  cd "${_pkgname}"

  install -Dm755 packwiz "${pkgdir}/usr/bin/packwiz"
  install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"

  install -Dm644 completions/packwiz.bash "${pkgdir}/usr/share/bash-completion/completions/packwiz"
  install -Dm644 completions/packwiz.zsh "${pkgdir}/usr/share/zsh/site-functions/_packwiz"
  install -Dm644 completions/packwiz.fish "${pkgdir}/usr/share/fish/vendor_completions.d/packwiz.fish"
}
