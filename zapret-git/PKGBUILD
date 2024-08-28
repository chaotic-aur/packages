# Maintainer:
# Contributor: Ahmad Hasan Mubashshir <ahmubashshir@gmail.com>

: ${_pkgtype=-git}

_pkgname="zapret"
pkgbase="$_pkgname${_pkgtype:-}"
pkgver=61.r22.gf8a673b
pkgrel=2
pkgdesc="Bypass deep packet inspection"
url="https://github.com/bol-van/zapret"
license=('MIT')
arch=('x86_64')

depends=(
  'curl'
  'ipset'
  'iptables'
  'systemd'
)
makedepends=(
  'git'
  'libnetfilter_queue'
)

provides=(
  "$_pkgname=$pkgver"
  "$pkgbase=$pkgver"
)
conflicts=("$_pkgname")

_pkgsrc="$_pkgname"
source=(
  "$_pkgsrc"::"git+$url.git"
  "sysusers.conf"
)
sha256sums=(
  'SKIP'
  '25c309e2ec545c9ee53759e23961c8a3f02708a7ba8dcbabab6eb681a36c03c0'
)

pkgver() {
  cd "$_pkgsrc"
  local _file _hash _ver _rev
  _file="docs/changes.txt"
  read -r _hash _ver < <(
    NL=$(awk '/^v[[:digit:]]+/{n=NR}END{print n}' "$_file")

    git blame -L "$NL,+1" -- "$_file" \
      | awk '{print $1" "$NF }' \
      | sed -E -e 's& v([[:digit:]]+)& \1&'
  )
  _rev=$(git rev-list --count --cherry-pick "$_hash"...HEAD)

  printf "%s.r%s.g%s" "${_ver:?}" "${_rev:?}" "${_hash::7}"
}

build() {
  cd "$_pkgsrc"
  make
}

_symlink() {
  mkdir -pm755 "$pkgdir/usr/bin"
  ln -s "/opt/zapret/$1" "$pkgdir/usr/bin/${1##*/}"
}

_set_config() {
  local _cfg="$pkgdir/opt/zapret/config.${1%/*}" _key="${1##*/}" _val="$2"
  if grep -q "^#$_key=" "$_cfg"; then
    sed -i "/^#$_key/s/#//" "$_cfg"
  fi
  sed -i "/^$_key=/c\\$_key=$(printf '%q' "$_val")" "$_cfg"
}

_package_zapret-common() {
  depends=(
    "$pkgbase=$pkgver"
    'curl'
    'ipset'
    'iptables'
    'systemd'
  )
  provides=("zapret-common=$pkgver")
  conflicts=('zapret-common')
  pkgdesc+=' - common files'

  cd "$_pkgsrc"
  for n in ip2net mdig; do
    install -Dm755 "binaries/my/$n" "$pkgdir/opt/zapret/$n/$n"
  done
  install -Dm644 init.d/systemd/* -t "$pkgdir/usr/lib/systemd/system"
  install -Dm755 init.d/sysv/* -t "$pkgdir/opt/zapret/init.d/sysv"
  install -Dm755 ipset/* -t "$pkgdir/opt/zapret/ipset"
  install -Dm644 common/* -t "$pkgdir/opt/zapret/common"
  install -Dm644 "$srcdir/sysusers.conf" "$pkgdir/usr/lib/sysusers.d/zapret.conf"
  install -Dm644 docs/LICENSE.txt "$pkgdir/usr/share/licenses/$_pkgname/LICENSE"

  sed -i '1s/$/\n\nWS_USER=zapret/' "$pkgdir/opt/zapret/init.d/sysv/functions"
  _symlink init.d/sysv/zapret
}

_package_zapret-nfqws() {
  depends=('libnetfilter_queue' "zapret-common-git=$pkgver")
  provides+=("zapret-nfqws=$pkgver")
  conflicts+=('zapret-nfqws')
  backup=("${makepkg_program_name+/}opt/zapret/config.nfqws")
  pkgdesc+=' - netfilter queue mode'

  cd "$_pkgsrc"
  install -Dm644 config.default "$pkgdir/opt/zapret/config.nfqws"
  install -Dm755 "binaries/my/nfqws" "$pkgdir/opt/zapret/nfq/nfqws"
  install -Dm644 docs/LICENSE.txt "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  ln -s config.nfqws "$pkgdir/opt/zapret/config"

  _symlink nfq/nfqws

  _set_config nfqws/FWTYPE iptables
  _set_config nfqws/MODE nfqws
  _set_config nfqws/MODE_HTTP_KEEPALIVE 1
  _set_config nfqws/MODE_HTTPS 1
  _set_config nfqws/MODE_HTTP 1
}

_package_zapret-tpws() {
  depends=("zapret-common-git=$pkgver")
  provides+=("zapret-tpws=$pkgver")
  conflicts+=('zapret-tpws')
  backup=("${makepkg_program_name+/}opt/zapret/config.tpws")
  pkgdesc+=' - transparent proxy mode'

  cd "$_pkgsrc"
  install -Dm644 config.default "$pkgdir/opt/zapret/config.tpws"
  install -Dm755 "binaries/my/tpws" "$pkgdir/opt/zapret/tpws/tpws"
  install -Dm644 docs/LICENSE.txt "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  ln -s config.tpws "$pkgdir/opt/zapret/config"

  _symlink tpws/tpws

  _set_config tpws/FWTYPE iptables
  _set_config tpws/MODE tpws
  _set_config tpws/MODE_HTTP_KEEPALIVE 1
  _set_config tpws/MODE_HTTPS 1
  _set_config tpws/MODE_HTTP 1
}

_package_zapret-docs() {
  unset depends
  provides=("zapret-docs=$pkgver")
  conflicts=('zapret-docs')
  pkgdesc+=' - docs and manuals'

  cd "$_pkgsrc"
  install -Dm644 docs/*.* -t "$pkgdir/usr/share/doc/$_pkgname"
  install -Dm644 docs/LICENSE.txt "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 docs/LICENSE.txt "$pkgdir/usr/share/doc/$_pkgname/LICENSE"
  install -Dm644 docs/changes.txt "$pkgdir/usr/share/doc/$_pkgname/CHANGELOG"

  _rm() {
    rm -rf "$pkgdir/usr/share/doc/$_pkgname/$1"
  }
  _rm LICENSE.txt
  _rm changes.txt
}

pkgname=(
  "$_pkgname-nfqws${_pkgtype:-}"
  "$_pkgname-tpws${_pkgtype:-}"
  "$_pkgname-common${_pkgtype:-}"
  "$_pkgname-docs${_pkgtype:-}"
)
for _p in "${pkgname[@]}"; do
  eval "package_$_p() {
    $(declare -f "_package_${_p%$_pkgtype}")
    _package_${_p%$_pkgtype}
  }"
done
