BEGIN {
    had_pkgver = 0
    had_pkgrel = 0
}
# Check if line begins with pkgver
/^pkgver/ {
    # Check if we already had a pkgver line
    if (had_pkgver == 1) {
        print $0
        next
    }
    had_pkgver = 1
    r = gensub(/\x27([a-zA-Z0-9_.-]+)\x27/, "\\1", "g")
    r = gensub(/"([a-zA-Z0-9_.-]+)"/, "\\1", "g", r)

    # Check if the general format is correct
    if (r !~ /^pkgver *= *[a-zA-Z0-9_.-]+\t+ +\|\t+pkgver *= *[a-zA-Z0-9_.-]+$/) {
        exit 1
    }
    next
}
# Check if line begins with pkgrel
/^pkgrel/ {
    # Check if we already had a pkgrel line
    if (had_pkgrel == 1) {
        exit 1
    }
    had_pkgrel = 1
    r = gensub(/\x27([a-zA-Z0-9_.-]+)\x27/, "\\1", "g")
    r = gensub(/"([a-zA-Z0-9_.-]+)"/, "\\1", "g", r)

    # Check if the general format is correct
    if (r !~ /^pkgrel *= *[a-zA-Z0-9_.-]+\t+ +\|\t+pkgrel *= *[a-zA-Z0-9_.-]+$/) {
        exit 1
    }
    next
}
{
    exit 1
}
