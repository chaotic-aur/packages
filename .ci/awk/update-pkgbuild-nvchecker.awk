# Variables provided:
# TARGET_VERSION
# TARGET_REVISION
# OLD_VERSION

BEGIN {
    has_old_version = OLD_VERSION != ""
    escaped_old_version = OLD_VERSION
    if (has_old_version) {
        gsub(/[][^$.|*+?(){}\\]/, "\\\\&", escaped_old_version)
    }
}

function replace_old_version(line,    result) {
    if (!has_old_version) {
        result = line
    } else {
        result = gensub(escaped_old_version, TARGET_VERSION, "g", line)
    }

    # Fallback for inconsistent files where source contains a stale version
    # not matching OLD_VERSION (e.g. v3.4.0 while pkgver is 3.1.0).
    if (result == line) {
        result = gensub(/v[0-9]+([.][0-9]+)+([_-][0-9A-Za-z]+)?/, "v" TARGET_VERSION, "g", result)
    }
    if (result == line) {
        result = gensub(/[0-9]+([.][0-9]+)+([_-][0-9A-Za-z]+)?/, TARGET_VERSION, "g", result)
    }

    return result
}

/^[[:space:]]*pkgver[[:space:]]*=/ {
    print "pkgver=\"" TARGET_VERSION "\""
    next
}

/^[[:space:]]*pkgrel[[:space:]]*=/ {
    print "pkgrel=1"
    next
}

/^[[:space:]]*_commit[[:space:]]*=/ {
    if (TARGET_REVISION != "") {
        print "_commit='" TARGET_REVISION "'"
    } else {
        print
    }
    next
}

/^[[:space:]]*source[[:space:]]*=.*/ {
    print replace_old_version($0)
    next
}

{
    print
}
