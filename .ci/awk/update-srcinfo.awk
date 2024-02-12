# Variables provided
# TARGET_VERSION
# BASE_URL
# TARGET_URL

BEGIN {
    ignore_pkgver = 0
    ignore_source = 0
}

/^\tpkgver = / {
    if (ignore_pkgver == 0) {
        print "\tpkgver = " TARGET_VERSION
        next
    }
}
/^\tsource = / {
    if (!ignore_source) {
        # name-ver.tar.gz::https://gitlab.com/-/archive/name/name-version.tar.gz
        if (match($0, /^\tsource = (.*)$/, o)) {
            if (index(o[1], BASE_URL) == 1) {
                print "\tsource = " TARGET_URL
                ignore_source = 1
                next
            }
        }
    }
}
1
