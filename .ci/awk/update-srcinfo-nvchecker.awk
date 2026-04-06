# Variables provided:
# TARGET_VERSION
# OLD_VERSION

BEGIN {
    has_old_version = OLD_VERSION != ""
    escaped_old_version = OLD_VERSION
    if (has_old_version) {
        gsub(/[][^$.|*+?(){}\\]/, "\\\\&", escaped_old_version)
    }
}

function replace_old_version(line,    result) {
    result = line
    if (has_old_version) {
        result = gensub(escaped_old_version, TARGET_VERSION, "g", result)
    }

    # Fallback for inconsistent files where source contains a stale version
    # not matching OLD_VERSION.
    if (result == line) {
        result = gensub(/v[0-9]+([.][0-9]+)+([_-][0-9A-Za-z]+)?/, "v" TARGET_VERSION, "g", result)
    }
    if (result == line) {
        result = gensub(/[0-9]+([.][0-9]+)+([_-][0-9A-Za-z]+)?/, TARGET_VERSION, "g", result)
    }

    return result
}

/^[[:space:]]*pkgver[[:space:]]*=/ {
    print "\tpkgver = " TARGET_VERSION
    next
}

/^[[:space:]]*pkgrel[[:space:]]*=/ {
    print "\tpkgrel = 1"
    next
}

/^[[:space:]]*source[[:space:]]*=.*/ {
    print replace_old_version($0)
    next
}

{
    print
}
