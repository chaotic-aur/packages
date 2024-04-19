# Variables provided:
# TARGET_VERSION
# BASE_URL
# TARGET_URL
# COMMIT

BEGIN {
    is_source = 0
    ignore_rest = 0
    ignore_pkgver = 0
    next_is_commit = 0
}
{
    line_begin = ""
    line_end = ""
}

function update_source(source) {
    r = source
    if (match(source, /(.+)\)$/, o)) {
        line_end = ")"
        is_source = 0
        r = o[1]
    }
    if (match(r, /(\s*)(.*)$/, o)) {
        line_begin = line_begin o[1]
        r = o[2]
    }
    r = gensub(/\x27([^\x27]+)\x27/, "\\1", "g", r)
    r = gensub(/\x22([^\x22]+)\x22/, "\\1", "g", r)

    # name-ver.tar.gz::https://gitlab.com/-/archive/name/name-version.tar.gz
    if (match(r, /^(.*)$/, o)) {
        if (index(o[1], BASE_URL) == 1) {
            print line_begin "\"" TARGET_URL "\"" line_end
            ignore_rest = 1
            is_source = 0
            next
        }
    }
}

# Handle pkgver
/^\s*pkgver *=/ {
    if (!is_source && !ignore_pkgver) {
        print "pkgver=" "\"" TARGET_VERSION "\""
        ignore_pkgver = 1
        next_is_commit = 1
        next
    }
}

/^\s*_commit *=/ {
    next
}

{
    if (next_is_commit) {
        print "_commit=" "'" COMMIT "'"
        next_is_commit = 0
    }
    if (!is_source && !ignore_rest) {
        # Find sum array
        if (match($0, /^source *= *\((.*)$/, o)) {
            is_source = 1
            line_begin="source=("
            update_source(o[1])
        }
    }
    if (is_source) {
        update_source($0)
    }
    print
}
