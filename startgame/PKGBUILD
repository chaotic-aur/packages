pkgname=startgame
pkgver=1.2.3
pkgrel=1
pkgdesc="CLI/Steam custom game launching helper"
arch=('any')
url='https://github.com/chaotic-aur/startgame'
license=('Unlicense')
depends=('gamemode' 'lib32-gamemode' 'mangohud' 'lib32-mangohud' 'obs-vkcapture')
makedepends=('git')
optdepends=('vulkan-amdgpu-pro' 'lib32-amdgpu-pro' 'gamescope' 'sdl2' 'lib32-sdl2' 'wine-tkg-staging-fsync-git' 'lib32-obs-vkcapture' 'amdvlk' 'lib32-amdvlk')
backup=('etc/gamerc')
source=('startgame' 'gamerc.example')
md5sums=('SKIP' 'SKIP')

package() {
  install -dDm755 "${pkgdir}/usr/bin" "${pkgdir}/etc"
  install -m644 gamerc.example "$pkgdir/etc/gamerc"
  install -m755 startgame "$pkgdir/usr/bin/"
}
