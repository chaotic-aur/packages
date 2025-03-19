# Maintainer: KokaKiwi <kokakiwi+aur@kokakiwi.net>

pkgname=dwarfs
pkgver=0.11.1
pkgrel=1
pkgdesc="A fast high compression read-only file system"
url='https://github.com/mhx/dwarfs'
arch=('x86_64' 'aarch64')
license=('GPL-3.0-only')
depends=(
  'fuse3' 'openssl' 'boost-libs' 'jemalloc' 'xxhash' 'fmt'
  'lz4' 'xz' 'zstd' 'brotli' 'libarchive' 'flac'
  'libunwind' 'google-glog' 'fmt' 'gflags' 'double-conversion'
)
makedepends=(
  'cmake' 'ruby-ronn'
  'python' 'python-mistletoe'
  'boost' 'libevent' 'libdwarf' 'chrono-date'
  'utf8cpp' 'range-v3' 'nlohmann-json'
  'gtest' 'parallel-hashmap'
)
source=("$pkgname-$pkgver.tar.xz::https://github.com/mhx/dwarfs/releases/download/v$pkgver/dwarfs-$pkgver.tar.xz")
sha256sums=('7a0cccb1ec3c2a18e9a014893c1d3e1f8f2c44ade6936c9f6d3bab5ec14b2052')
b2sums=('5e6d9a002043f5c90ea1191779efef6675eebe426ac37074938cff916871155772d5c0fc9c195b8953ecd78be57dd05f32f9805ce1f41c7b41feaa25cfe7cdaf')

build() {
  # Setting up release flags manually here so we get to use `CMAKE_BUILD_TYPE=None`
  # and keep makepkg-defined flags for build
  # cf. https://wiki.archlinux.org/title/CMake_package_guidelines#Fixing_the_automatic_optimization_flag_override
  export CFLAGS="$CFLAGS -DNDEBUG"
  export CXXFLAGS="$CXXFLAGS -DNDEBUG"

  # Disable ccache here since makepkg already handly this
  cmake -B build -S "$pkgname-$pkgver" \
    -W no-dev \
    -D CMAKE_INSTALL_PREFIX=/usr \
    -D CMAKE_BUILD_TYPE=None \
    -D WITH_TESTS=ON \
    -D PREFER_SYSTEM_ZSTD=ON \
    -D PREFER_SYSTEM_XXHASH=ON \
    -D PREFER_SYSTEM_LIBFMT=ON \
    -D PREFER_SYSTEM_GTEST=ON \
    -D DISABLE_CCACHE=ON \
    -D DISABLE_MOLD=ON

  cmake --build build
}

check() {
  #TODO: Find a way to either load the `fuse` module for the tests or disable the tests only when `fuse` module is not
  #      loaded
  #      Also wtf with perfmon test??
  cmake --build build --target test -- ARGS="-E '(dwarfs/tools_test\..*|dwarfsextract_test\.perfmon)'"
}

package() {
  cmake --install build --prefix "$pkgdir/usr"

  mv "$pkgdir/usr/sbin"/* "$pkgdir/usr/bin"
  rm -rf "$pkgdir/usr/sbin"

  install -Dm0644 "$pkgname-$pkgver/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
